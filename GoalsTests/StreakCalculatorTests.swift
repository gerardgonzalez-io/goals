import Foundation
import Testing
@testable import Goals

/// `StreakCalculatorTests` coverage summary (2 tests):
/// 1. `testCalculations`:
///    Verifies streak results across multiple day-pattern scenarios using parameterized inputs.
///    Covered behaviors include:
///    empty input, goal reached today, goal reached yesterday, inactive streak after gaps,
///    same-day sessions summing toward one streak day, and multi-day consecutive streak counting.
/// 2. `measureCalculateStreakExecutionTime`:
///    Measures execution time of `calculateStreak(for:goals:)` with a large synthetic dataset
///    to monitor performance characteristics under heavier load.
struct StreakCalculatorTests
{
    let streakCalculator = StreakCalculator()
    let now = Date.now

    struct Input
    {
        let expectedStreak: Int
        let days: [Int]
        let targetSecondsPerDay: TimeInterval

        init(
            expectedStreak: Int,
            days: [Int],
            targetSecondsPerDay: TimeInterval = 1_800
        )
        {
            self.expectedStreak = expectedStreak
            self.days = days
            self.targetSecondsPerDay = targetSecondsPerDay
        }
    }

    @Test("Streak calculations", arguments: [
        Input(expectedStreak: 0, days: []),

        Input(expectedStreak: 1, days: [0]),
        Input(expectedStreak: 1, days: [-1]),
        Input(expectedStreak: 0, days: [-2]),

        Input(expectedStreak: 1, days: [0, 0]),
        Input(expectedStreak: 1, days: [-1, -1]),
        Input(expectedStreak: 0, days: [-2, -2]),

        Input(expectedStreak: 3, days: [-2, -1, 0]),
        Input(expectedStreak: 2, days: [-3, -1, 0]),
        Input(expectedStreak: 3, days: [-3, -2, -1]),
        Input(expectedStreak: 2, days: [-4, -2, -1]),

        Input(expectedStreak: 0, days: [0], targetSecondsPerDay: 3_600),
        Input(expectedStreak: 0, days: [-1], targetSecondsPerDay: 3_600),
        Input(expectedStreak: 1, days: [0, 0], targetSecondsPerDay: 3_600),
        Input(expectedStreak: 1, days: [-1, -1], targetSecondsPerDay: 3_600)
    ])

    func testCalculations(input: Input)
    {
        let topicID = UUID()
        let goal = Goal(
            topicID: topicID,
            targetSecondsPerDay: input.targetSecondsPerDay,
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: now)!
        )
        let sessions = input.days.map {
            let endDate = Calendar.current.date(byAdding: .day, value: $0, to: now)!
            let startDate = endDate.addingTimeInterval(-1_800)
            return StudySession(
                topicID: topicID,
                startDate: startDate,
                endDate: endDate,
                sessionIntervals: [
                    SessionInterval(startDate: startDate, endDate: endDate)
                ]
            )
        }

        let streak = streakCalculator.calculateStreak(for: sessions, goals: [goal])
        #expect(streak == input.expectedStreak, "\(input.days)")
    }
}

extension StreakCalculatorTests
{
    @Test("Measure calculateStreak execution time")
    func measureCalculateStreakExecutionTime()
    {
        let calendar = Calendar(identifier: .gregorian)
        let topicID = UUID()
        let goal = Goal(
            topicID: topicID,
            targetSecondsPerDay: 3_600,
            createdAt: date(year: 2000, month: 1, day: 1, calendar: calendar)
        )

        let sessions = (0..<1_500).map { i in
            let startDate = calendar.date(
                byAdding: .day,
                value: i,
                to: date(year: 2000, month: 1, day: 1, calendar: calendar)
            )!

            let endDate = startDate.addingTimeInterval(3_900)

            return StudySession(
                topicID: topicID,
                startDate: startDate,
                endDate: endDate,
                sessionIntervals: [
                    SessionInterval(startDate: startDate, endDate: endDate)
                ]
            )
        }

        let clock = ContinuousClock()

        let duration = clock.measure {
            _ = streakCalculator.calculateStreak(for: sessions, goals: [goal])
        }

        print("calculateStreak took:", duration)
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        calendar: Calendar
    ) -> Date
    {
        calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}
