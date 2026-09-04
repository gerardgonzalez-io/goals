import Foundation
import Testing
@testable import Goals

/// `GoalEvaluatorTests` coverage summary (6 tests):
/// 1. `singleGoalAppliesToAllFutureSessions`:
///    Verifies one goal remains active from its creation date forward and is applied to later sessions.
/// 2. `newGoalAppliesFromCreationDateForward`:
///    Verifies newer goals replace older ones from their creation date onward across different session days.
/// 3. `multipleGoalChangesAcrossManyDays`:
///    Verifies goal evaluation over many goal updates and mixed reached/not-reached outcomes.
/// 4. `multipleGoalsOnSameDayUseLatestOne`:
///    Verifies when multiple goals are created on the same day, the latest goal of that day is used.
/// 5. `crossDaySessionReachesGoalOnBothDays`:
///    Verifies a crossing interval contributes to both days and can satisfy each day’s goal.
/// 6. `measureReachedGoalsByDayExecutionTime`:
///    Measures execution time of `reachedGoalsByDay` with a large synthetic dataset.
struct GoalEvaluatorTests
{
    let evaluator = GoalEvaluator()
    let calendar = Calendar.current
    
    @Test("Single goal applies to all future sessions")
    func singleGoalAppliesToAllFutureSessions()
    {
        let topicID = UUID()

        let goalDate = date(year: 2000, month: 1, day: 1)
        let goal = Goal(topicID: topicID, targetSecondsPerDay: 3_600, createdAt: goalDate) // 1h

        let sessionDay1 = date(year: 2000, month: 1, day: 1)
        let sessionDay2 = date(year: 2000, month: 2, day: 2)

        let sessions = [
            StudySession(
                topicID: topicID,
                startDate: sessionDay1,
                endDate: sessionDay1.addingTimeInterval(5_400), // 1h 30m
                sessionIntervals: [
                    SessionInterval(startDate: sessionDay1, endDate: sessionDay1.addingTimeInterval(2_400)), // 40m
                    SessionInterval(startDate: sessionDay1.addingTimeInterval(3_000), endDate: sessionDay1.addingTimeInterval(4_800)) // 30m
                ]
            ),
            StudySession(
                topicID: topicID,
                startDate: sessionDay2,
                endDate: sessionDay2.addingTimeInterval(5_400), // 1h 30m
                sessionIntervals: [
                    SessionInterval(startDate: sessionDay2, endDate: sessionDay2.addingTimeInterval(2_400)), // 40m
                    SessionInterval(startDate: sessionDay2.addingTimeInterval(3_000), endDate: sessionDay2.addingTimeInterval(4_800)) // 30m
                ]
            )
        ]

        let result = evaluator.reachedGoalsByDay(sessions: sessions, goals: [goal])

        #expect(result[calendar.startOfDay(for: sessionDay1)] == true)
        #expect(result[calendar.startOfDay(for: sessionDay2)] == true)
    }

    @Test("New goal applies from its creation date forward")
    func newGoalAppliesFromCreationDateForward()
    {
        let topicID = UUID()

        let firstGoalDate = date(year: 2000, month: 1, day: 1)
        let secondGoalDate = date(year: 2000, month: 4, day: 4)
        let thirdGoalDate = date(year: 2000, month: 6, day: 5)

        let firstGoal = Goal(topicID: topicID, targetSecondsPerDay: 3_600, createdAt: firstGoalDate) // 1h
        let secondGoal = Goal(topicID: topicID, targetSecondsPerDay: 5_400, createdAt: secondGoalDate) // 1h 30m
        let thirdGoal = Goal(topicID: topicID, targetSecondsPerDay: 1_400, createdAt: thirdGoalDate) // 23m 20s

        let sessionBeforeChange = date(year: 2000, month: 2, day: 2)
        let sessionAfterChange = date(year: 2000, month: 5, day: 5)
        let sessionAfterChangeAgain = date(year: 2000, month: 7, day: 5)

        let sessions = [
            StudySession(
                topicID: topicID,
                startDate: sessionBeforeChange,
                endDate: sessionBeforeChange.addingTimeInterval(5_400), // 1h 30m
                sessionIntervals: [
                    SessionInterval(startDate: sessionBeforeChange, endDate: sessionBeforeChange.addingTimeInterval(2_400)), // 40m
                    SessionInterval(startDate: sessionBeforeChange.addingTimeInterval(3_000), endDate: sessionBeforeChange.addingTimeInterval(4_800)) // 30m
                ]
            ),
            StudySession(
                topicID: topicID,
                startDate: sessionAfterChange,
                endDate: sessionAfterChange.addingTimeInterval(6_000), // 1h 40m
                sessionIntervals: [
                    SessionInterval(startDate: sessionAfterChange, endDate: sessionAfterChange.addingTimeInterval(3_000)), // 50m
                    SessionInterval(startDate: sessionAfterChange.addingTimeInterval(3_300), endDate: sessionAfterChange.addingTimeInterval(5_700)) // 40m
                ]
            ),
            StudySession(
                topicID: topicID,
                startDate: sessionAfterChangeAgain,
                endDate: sessionAfterChangeAgain.addingTimeInterval(2_700), // 45m
                sessionIntervals: [
                    SessionInterval(startDate: sessionAfterChangeAgain, endDate: sessionAfterChangeAgain.addingTimeInterval(1_200)), // 20m
                    SessionInterval(startDate: sessionAfterChangeAgain.addingTimeInterval(1_500), endDate: sessionAfterChangeAgain.addingTimeInterval(2_100)) // 10m
                ]
            ),
        ]

        let result = evaluator.reachedGoalsByDay(sessions: sessions, goals: [firstGoal, secondGoal, thirdGoal])

        #expect(result[calendar.startOfDay(for: sessionBeforeChange)] == true)
        #expect(result[calendar.startOfDay(for: sessionAfterChange)] == true)
        #expect(result[calendar.startOfDay(for: sessionAfterChangeAgain)] == true)
    }

    @Test("Multiple goal changes across many days")
    func multipleGoalChangesAcrossManyDays()
    {
        let topicID = UUID()

        let goals = [
            Goal(topicID: topicID, targetSecondsPerDay: 1_800, createdAt: date(year: 2000, month: 1, day: 1)),  // 30m
            Goal(topicID: topicID, targetSecondsPerDay: 2_400, createdAt: date(year: 2000, month: 1, day: 5)),  // 40m
            Goal(topicID: topicID, targetSecondsPerDay: 3_000, createdAt: date(year: 2000, month: 1, day: 10)), // 50m
            Goal(topicID: topicID, targetSecondsPerDay: 3_600, createdAt: date(year: 2000, month: 1, day: 15)), // 1h
            Goal(topicID: topicID, targetSecondsPerDay: 4_200, createdAt: date(year: 2000, month: 1, day: 20)), // 1h 10m
            Goal(topicID: topicID, targetSecondsPerDay: 4_800, createdAt: date(year: 2000, month: 1, day: 25)), // 1h 20m
            Goal(topicID: topicID, targetSecondsPerDay: 5_400, createdAt: date(year: 2000, month: 1, day: 30))  // 1h 30m
        ]

        let sessions: [(Date, TimeInterval, TimeInterval, TimeInterval, Bool)] = [
            (date(year: 2000, month: 1, day: 3), 2_000, 1_200, 800, true),   // 33m20s (20m + 13m20s)
            (date(year: 2000, month: 1, day: 7), 2_300, 1_200, 1_100, false), // 38m20s (20m + 18m20s)
            (date(year: 2000, month: 1, day: 12), 3_100, 1_800, 1_300, true), // 51m40s (30m + 21m40s)
            (date(year: 2000, month: 1, day: 17), 3_500, 1_800, 1_700, false), // 58m20s (30m + 28m20s)
            (date(year: 2000, month: 1, day: 22), 4_500, 2_400, 2_100, true), // 1h 15m (40m + 35m)
            (date(year: 2000, month: 1, day: 27), 4_700, 2_400, 2_300, false), // 1h 18m20s (40m + 38m20s)
            (date(year: 2000, month: 2, day: 1), 5_500, 3_000, 2_500, true)   // 1h 31m40s (50m + 41m40s)
        ]

        var studySessions: [StudySession] = []
        studySessions.reserveCapacity(sessions.count)

        for (day, sessionDuration, interval1Duration, interval2Duration, _) in sessions
        {
            let sessionStart = day
            let sessionEnd = day.addingTimeInterval(sessionDuration)
            let interval1End = sessionStart.addingTimeInterval(interval1Duration)
            let interval2Start = interval1End.addingTimeInterval(300) // 5m pause
            let interval2End = interval2Start.addingTimeInterval(interval2Duration)

            studySessions.append(
                StudySession(
                    topicID: topicID,
                    startDate: sessionStart,
                    endDate: sessionEnd,
                    sessionIntervals: [
                        SessionInterval(startDate: sessionStart, endDate: interval1End),
                        SessionInterval(startDate: interval2Start, endDate: interval2End)
                    ]
                )
            )
        }

        let result = evaluator.reachedGoalsByDay(sessions: studySessions, goals: goals)

        #expect(result[calendar.startOfDay(for: date(year: 2000, month: 1, day: 3))] == true)
        #expect(result[calendar.startOfDay(for: date(year: 2000, month: 1, day: 7))] == false)
        #expect(result[calendar.startOfDay(for: date(year: 2000, month: 1, day: 12))] == true)
        #expect(result[calendar.startOfDay(for: date(year: 2000, month: 1, day: 17))] == false)
        #expect(result[calendar.startOfDay(for: date(year: 2000, month: 1, day: 22))] == true)
        #expect(result[calendar.startOfDay(for: date(year: 2000, month: 1, day: 27))] == false)
        #expect(result[calendar.startOfDay(for: date(year: 2000, month: 2, day: 1))] == true)
    }

    @Test("Multiple goals created on same day use latest goal of that day")
    func multipleGoalsOnSameDayUseLatestOne()
    {
        let topicID = UUID()

        let sameDayMorning = dateTime(year: 2000, month: 3, day: 10, hour: 9, minute: 0)
        let sameDayEvening = dateTime(year: 2000, month: 3, day: 10, hour: 18, minute: 0)

        let goals = [
            Goal(topicID: topicID, targetSecondsPerDay: 3_000, createdAt: date(year: 2000, month: 3, day: 1)), // 50m
            Goal(topicID: topicID, targetSecondsPerDay: 4_200, createdAt: sameDayMorning), // 1h 10m
            Goal(topicID: topicID, targetSecondsPerDay: 5_400, createdAt: sameDayEvening), // 1h 30m
            Goal(topicID: topicID, targetSecondsPerDay: 6_000, createdAt: date(year: 2000, month: 3, day: 20)) // 1h 40m
        ]

        let dayBeforeSameDayChange = date(year: 2000, month: 3, day: 5)
        let sameDayOfChange = date(year: 2000, month: 3, day: 10)
        let afterNextChange = date(year: 2000, month: 3, day: 22)

        let studySessions = [
            StudySession(
                topicID: topicID,
                startDate: dayBeforeSameDayChange,
                endDate: dayBeforeSameDayChange.addingTimeInterval(3_600), // 1h
                sessionIntervals: [
                    SessionInterval(startDate: dayBeforeSameDayChange, endDate: dayBeforeSameDayChange.addingTimeInterval(1_800)), // 30m
                    SessionInterval(startDate: dayBeforeSameDayChange.addingTimeInterval(2_100), endDate: dayBeforeSameDayChange.addingTimeInterval(3_400)) // 21m 40s
                ]
            ),
            StudySession(
                topicID: topicID,
                startDate: sameDayOfChange,
                endDate: sameDayOfChange.addingTimeInterval(5_400), // 1h 30m
                sessionIntervals: [
                    SessionInterval(startDate: sameDayOfChange, endDate: sameDayOfChange.addingTimeInterval(2_400)), // 40m
                    SessionInterval(startDate: sameDayOfChange.addingTimeInterval(2_700), endDate: sameDayOfChange.addingTimeInterval(5_100)) // 40m
                ]
            ),
            StudySession(
                topicID: topicID,
                startDate: afterNextChange,
                endDate: afterNextChange.addingTimeInterval(6_000), // 1h 40m
                sessionIntervals: [
                    SessionInterval(startDate: afterNextChange, endDate: afterNextChange.addingTimeInterval(3_000)), // 50m
                    SessionInterval(startDate: afterNextChange.addingTimeInterval(3_300), endDate: afterNextChange.addingTimeInterval(5_700)) // 40m
                ]
            )
        ]

        let result = evaluator.reachedGoalsByDay(sessions: studySessions, goals: goals)

        #expect(result[calendar.startOfDay(for: dayBeforeSameDayChange)] == true)
        #expect(result[calendar.startOfDay(for: sameDayOfChange)] == true)
        #expect(result[calendar.startOfDay(for: afterNextChange)] == false)
    }

    @Test("Cross-day session reaches goal on both days")
    func crossDaySessionReachesGoalOnBothDays()
    {
        let topicID = UUID()

        let startDate = dateTime(year: 2022, month: 12, day: 7, hour: 22, minute: 0) // 22:00
        let endDate = dateTime(year: 2022, month: 12, day: 8, hour: 2, minute: 0) // 02:00 next day (4h total)

        let goal = Goal(topicID: topicID, targetSecondsPerDay: 3_600, createdAt: date(year: 2022, month: 12, day: 7)) // 1h

        let sessions = [
            StudySession(
                topicID: topicID,
                startDate: startDate,
                endDate: endDate,
                sessionIntervals: [
                    SessionInterval(startDate: startDate, endDate: endDate) // 4h crossing interval
                ]
            )
        ]

        let result = evaluator.reachedGoalsByDay(sessions: sessions, goals: [goal])

        #expect(result[calendar.startOfDay(for: date(year: 2022, month: 12, day: 7))] == true)
        #expect(result[calendar.startOfDay(for: date(year: 2022, month: 12, day: 8))] == true)
    }

    private func date(year: Int, month: Int, day: Int) -> Date
    {
        let components = DateComponents(calendar: calendar, year: year, month: month, day: day)
        return components.date!
    }

    private func dateTime(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date
    {
        let components = DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return components.date!
    }
}

extension GoalEvaluatorTests
{
    @Test("Measure reachedGoalsByDay execution time")
    func measureReachedGoalsByDayExecutionTime()
    {
        let topicID = UUID()

        let goal = Goal(
            topicID: topicID,
            targetSecondsPerDay: 3_600,
            createdAt: date(year: 2000, month: 1, day: 1)
        )

        let sessions = (0..<1_500).map { i in
            let startDate = calendar.date(
                byAdding: .day,
                value: i,
                to: date(year: 2000, month: 1, day: 1)
            )!
            let endDate = startDate.addingTimeInterval(3_900) // 1h 5m
            let firstIntervalEnd = startDate.addingTimeInterval(2_100) // 35m
            let secondIntervalStart = startDate.addingTimeInterval(2_400) // 5m pause
            let secondIntervalEnd = startDate.addingTimeInterval(3_600) // 20m

            return StudySession(
                topicID: topicID,
                startDate: startDate,
                endDate: endDate,
                sessionIntervals: [
                    SessionInterval(startDate: startDate, endDate: firstIntervalEnd),
                    SessionInterval(startDate: secondIntervalStart, endDate: secondIntervalEnd)
                ]
            )
        }

        let clock = ContinuousClock()

        let duration = clock.measure {
            _ = evaluator.reachedGoalsByDay(
                sessions: sessions,
                goals: [goal]
            )
        }

        print("reachedGoalsByDay took:", duration)
    }
}
