import Foundation
import Testing
@testable import Goals

/// `TimeCalculatorTests` coverage summary (8 tests):
/// 1. `dailyTimeSplitsCrossDaySingleIntervalSession`:
///    Verifies one 1-hour interval crossing midnight is split correctly into both days.
///    interval 1 = 23:30 -> 00:30 (1h, crossing interval), resulting in 30m + 30m by day.
/// 2. `dailyTimeSplitsCrossDaySessionWithTwoSeparateIntervals`:
///    Verifies a cross-day session with one interval on each day counts each day independently.
///    interval 1 = 23:10 -> 23:50 (40m, same day),
///    interval 2 = 00:10 -> 00:50 (40m, same day),
///    resulting in 40m per day.
/// 3. `dailyTimeSplitsCrossingIntervalInsideCrossDaySession`:
///    Verifies a cross-day session that includes an interval crossing midnight splits that interval correctly
///    and combines it with other same-day intervals:
///    interval 1 = 22:40 -> 23:20 (40m, same day),
///    interval 2 = 23:53 -> 00:23 (30m, crossing interva, 7m one day, 23m next dayl),
///    interval 3 = 00:40 -> 00:55 (15m, same day),
///    resulting in 47m on day 1 and 38m on day 2.
/// 4. `dailyTimeCountsSingleIntervalSessionOnSameDay`:
///    Verifies daily time uses active interval duration only, not full session duration.
///    interval 1 = 08:00 -> 10:00 (2h, same day) inside a 08:00 -> 14:00 session.
/// 5. `dailyTimeSumsTwoIntervalsInOneSession`:
///    Verifies daily time sums multiple intervals from the same session on one day.
///    interval 1 = 10:00 -> 10:20 (20m, same day),
///    interval 2 = 10:30 -> 10:45 (15m, same day),
///    resulting in 35m total.
/// 6. `dailyTimeSumsTwoSessionsOnSameDay`:
///    Verifies daily time sums interval totals across two different sessions on the same day.
///    session 1 interval 1 = 08:00 -> 10:30 (2h30m, same day),
///    session 2 interval 1 = 13:00 -> 13:25 (25m, same day),
///    session 2 interval 2 = 13:30 -> 13:50 (20m, same day),
///    session 2 interval 3 = 14:00 -> 14:15 (15m, same day),
///    session 2 interval 4 = 14:20 -> 15:20 (1h, same day),
///    session 2 interval 5 = 15:30 -> 15:33 (3m, same day),
///    session 2 interval 6 = 15:40 -> 15:47 (7m, same day),
///    resulting in 4h40m total.
/// 7. `totalTimeSumsAllSessions`:
///    Verifies total time sums all intervals across all provided sessions, including cross-day intervals.
///    interval 1 = 23:30 -> 00:30 (1h, crossing interval),
///    interval 2 = 23:10 -> 23:50 (40m, same day),
///    interval 3 = 00:10 -> 00:50 (40m, same day),
///    interval 4 = 22:40 -> 23:20 (40m, same day),
///    interval 5 = 23:53 -> 00:23 (30m, crossing interval),
///    interval 6 = 00:40 -> 00:55 (15m, same day),
///    resulting in 3h45m total.
/// 8. `measureTotalTimeExecutionTime`:
///    Measures total-time performance with 20,500 sessions.
///    Each session has 4 same-day intervals:
///    interval 1 = 25m, interval 2 = 20m, interval 3 = 15m, interval 4 = 20m.
struct TimeCalculatorTests
{
    @Test("Cross-day session is split across both calendar days")
    func dailyTimeSplitsCrossDaySingleIntervalSession()
    {
        let calendar = Calendar(identifier: .gregorian)
        let topicID = UUID()

        // One 1h interval crossing midnight.
        let start = calendar.date(from: DateComponents(year: 2000, month: 1, day: 10, hour: 23, minute: 30))!
        let end = calendar.date(from: DateComponents(year: 2000, month: 1, day: 11, hour: 0, minute: 30))!

        let session = StudySession(
            topicID: topicID,
            startDate: start,
            endDate: end,
            sessionIntervals: [
                SessionInterval(startDate: start, endDate: end)
            ]
        )

        let day10 = calendar.date(from: DateComponents(year: 2000, month: 1, day: 10, hour: 12, minute: 0))!
        let day11 = calendar.date(from: DateComponents(year: 2000, month: 1, day: 11, hour: 12, minute: 0))!

        let resultDay10 = TimeCalculator.dailyTime(from: [session], on: day10, calendar: calendar)
        let resultDay11 = TimeCalculator.dailyTime(from: [session], on: day11, calendar: calendar)

        #expect(resultDay10 == 1_800) // 30m
        #expect(resultDay11 == 1_800) // 30m
    }

    @Test("Cross-day session with one interval per day sums each day independently")
    func dailyTimeSplitsCrossDaySessionWithTwoSeparateIntervals()
    {
        let calendar = Calendar(identifier: .gregorian)
        let topicID = UUID()

        // Entire session: 1h 50m crossing midnight.
        let sessionStart = calendar.date(from: DateComponents(year: 2000, month: 1, day: 14, hour: 23, minute: 10))!
        let sessionEnd = calendar.date(from: DateComponents(year: 2000, month: 1, day: 15, hour: 1, minute: 0))!

        let intervalDay1Start = calendar.date(from: DateComponents(year: 2000, month: 1, day: 14, hour: 23, minute: 10))!
        let intervalDay1End = calendar.date(from: DateComponents(year: 2000, month: 1, day: 14, hour: 23, minute: 50))! // 40m

        let intervalDay2Start = calendar.date(from: DateComponents(year: 2000, month: 1, day: 15, hour: 0, minute: 10))!
        let intervalDay2End = calendar.date(from: DateComponents(year: 2000, month: 1, day: 15, hour: 0, minute: 50))! // 40m

        let session = StudySession(
            topicID: topicID,
            startDate: sessionStart,
            endDate: sessionEnd,
            sessionIntervals: [
                SessionInterval(startDate: intervalDay1Start, endDate: intervalDay1End),
                SessionInterval(startDate: intervalDay2Start, endDate: intervalDay2End)
            ]
        )

        let day14 = calendar.date(from: DateComponents(year: 2000, month: 1, day: 14, hour: 12, minute: 0))!
        let day15 = calendar.date(from: DateComponents(year: 2000, month: 1, day: 15, hour: 12, minute: 0))!

        let resultDay14 = TimeCalculator.dailyTime(from: [session], on: day14, calendar: calendar)
        let resultDay15 = TimeCalculator.dailyTime(from: [session], on: day15, calendar: calendar)

        #expect(resultDay14 == 2_400) // 40m
        #expect(resultDay15 == 2_400) // 40m
    }

    @Test("Cross-day session splits a crossing interval across both days")
    func dailyTimeSplitsCrossingIntervalInsideCrossDaySession()
    {
        let calendar = Calendar(identifier: .gregorian)
        let topicID = UUID()

        // Entire session: 2h 50m crossing midnight.
        let sessionStart = calendar.date(from: DateComponents(year: 2000, month: 1, day: 16, hour: 22, minute: 40))!
        let sessionEnd = calendar.date(from: DateComponents(year: 2000, month: 1, day: 17, hour: 1, minute: 30))!

        let interval1Start = calendar.date(from: DateComponents(year: 2000, month: 1, day: 16, hour: 22, minute: 40))!
        let interval1End = calendar.date(from: DateComponents(year: 2000, month: 1, day: 16, hour: 23, minute: 20))! // 40m day 1

        let interval2Start = calendar.date(from: DateComponents(year: 2000, month: 1, day: 16, hour: 23, minute: 53))!
        let interval2End = calendar.date(from: DateComponents(year: 2000, month: 1, day: 17, hour: 0, minute: 23))! // 30m crossing (7m day 1, 23m day 2)

        let interval3Start = calendar.date(from: DateComponents(year: 2000, month: 1, day: 17, hour: 0, minute: 40))!
        let interval3End = calendar.date(from: DateComponents(year: 2000, month: 1, day: 17, hour: 0, minute: 55))! // 15m day 2

        let session = StudySession(
            topicID: topicID,
            startDate: sessionStart,
            endDate: sessionEnd,
            sessionIntervals: [
                SessionInterval(startDate: interval1Start, endDate: interval1End),
                SessionInterval(startDate: interval2Start, endDate: interval2End),
                SessionInterval(startDate: interval3Start, endDate: interval3End)
            ]
        )

        let day16 = calendar.date(from: DateComponents(year: 2000, month: 1, day: 16, hour: 12, minute: 0))!
        let day17 = calendar.date(from: DateComponents(year: 2000, month: 1, day: 17, hour: 12, minute: 0))!

        let resultDay16 = TimeCalculator.dailyTime(from: [session], on: day16, calendar: calendar)
        let resultDay17 = TimeCalculator.dailyTime(from: [session], on: day17, calendar: calendar)

        #expect(resultDay16 == 2_820) // 47m
        #expect(resultDay17 == 2_280) // 38m
    }

    @Test("Single-interval session counts only its active interval time")
    func dailyTimeCountsSingleIntervalSessionOnSameDay()
    {
        let calendar = Calendar(identifier: .gregorian)
        let topicID = UUID()

        // 6h session with a single 2h active interval.
        let sessionStart = calendar.date(from: DateComponents(year: 2000, month: 1, day: 12, hour: 8, minute: 0))!
        let sessionEnd = calendar.date(from: DateComponents(year: 2000, month: 1, day: 12, hour: 14, minute: 0))!
        let intervalEnd = calendar.date(from: DateComponents(year: 2000, month: 1, day: 12, hour: 10, minute: 0))!

        let session = StudySession(
            topicID: topicID,
            startDate: sessionStart,
            endDate: sessionEnd,
            sessionIntervals: [
                SessionInterval(startDate: sessionStart, endDate: intervalEnd)
            ]
        )

        let day12 = calendar.date(from: DateComponents(year: 2000, month: 1, day: 12, hour: 12, minute: 0))!
        let result = TimeCalculator.dailyTime(from: [session], on: day12, calendar: calendar)

        #expect(result == 7_200) // 2h
    }

    @Test("Session with two intervals sums both intervals on the selected day")
    func dailyTimeSumsTwoIntervalsInOneSession()
    {
        let calendar = Calendar(identifier: .gregorian)
        let topicID = UUID()

        // 2h session with two active intervals: 20m + 15m.
        let sessionStart = calendar.date(from: DateComponents(year: 2000, month: 1, day: 13, hour: 10, minute: 0))!
        let sessionEnd = calendar.date(from: DateComponents(year: 2000, month: 1, day: 13, hour: 12, minute: 0))!

        // Same start that session, interval: 20m
        let interval1Start = calendar.date(from: DateComponents(year: 2000, month: 1, day: 13, hour: 10, minute: 0))!
        let interval1End = calendar.date(from: DateComponents(year: 2000, month: 1, day: 13, hour: 10, minute: 20))!
        
        // interval: 15m
        let interval2Start = calendar.date(from: DateComponents(year: 2000, month: 1, day: 13, hour: 10, minute: 30))!
        let interval2End = calendar.date(from: DateComponents(year: 2000, month: 1, day: 13, hour: 10, minute: 45))!

        let session = StudySession(
            topicID: topicID,
            startDate: sessionStart,
            endDate: sessionEnd,
            sessionIntervals: [
                SessionInterval(
                    startDate: interval1Start,
                    endDate: interval1End
                ),
                SessionInterval(
                    startDate: interval2Start,
                    endDate: interval2End
                )
            ]
        )

        let day13 = calendar.date(from: DateComponents(year: 2000, month: 1, day: 13, hour: 12, minute: 0))!
        let result = TimeCalculator.dailyTime(from: [session], on: day13, calendar: calendar)

        #expect(result == 2_100) // 35m
    }

    @Test("Daily time sums two sessions on same day using interval totals")
    func dailyTimeSumsTwoSessionsOnSameDay()
    {
        let calendar = Calendar(identifier: .gregorian)
        let topicID = UUID()
        let targetDay = calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 12, minute: 0))!

        // Sample 4: 2h30m session with one interval matching full session.
        let session1Start = calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 8, minute: 0))!
        let session1End = calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 10, minute: 30))!

        // Sample 5: 3h session with intervals 25m, 20m, 15m, 1h, 3m, 7m.
        let session2Start = calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 13, minute: 0))!
        let session2End = calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 16, minute: 0))!

        let sessions = [
            StudySession(
                topicID: topicID,
                startDate: session1Start,
                endDate: session1End,
                sessionIntervals: [
                    SessionInterval(startDate: session1Start, endDate: session1End)
                ]
            ),
            StudySession(
                topicID: topicID,
                startDate: session2Start,
                endDate: session2End,
                sessionIntervals: [
                    SessionInterval(
                        startDate: session2Start,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 13, minute: 25))!
                    ),
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 13, minute: 30))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 13, minute: 50))!
                    ),
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 14, minute: 0))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 14, minute: 15))!
                    ),
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 14, minute: 20))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 15, minute: 20))!
                    ),
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 15, minute: 30))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 15, minute: 33))!
                    ),
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 15, minute: 40))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 20, hour: 15, minute: 47))!
                    )
                ]
            )
        ]

        let result = TimeCalculator.dailyTime(from: sessions, on: targetDay, calendar: calendar)

        #expect(result == 16_800) // 4h 40m
    }

    @Test("Total time sums all session intervals")
    func totalTimeSumsAllSessions()
    {
        let calendar = Calendar(identifier: .gregorian)
        let topicID = UUID()
        let sessions = [
            // Sample 1: 1h session crossing midnight with one 1h interval crossing midnight.
            StudySession(
                topicID: topicID,
                startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 10, hour: 23, minute: 30))!,
                endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 11, hour: 0, minute: 30))!,
                sessionIntervals: [
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 10, hour: 23, minute: 30))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 11, hour: 0, minute: 30))!
                    )
                ]
            ),
            // Sample 2: 1h50m session crossing midnight with two same-day intervals (40m + 40m = 1h20m).
            StudySession(
                topicID: topicID,
                startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 14, hour: 23, minute: 10))!,
                endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 15, hour: 1, minute: 0))!,
                sessionIntervals: [
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 14, hour: 23, minute: 10))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 14, hour: 23, minute: 50))!
                    ),
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 15, hour: 0, minute: 10))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 15, hour: 0, minute: 50))!
                    )
                ]
            ),
            // Sample 3: 2h50m session crossing midnight with three intervals (40m + 30m crossing + 15m = 1h25m).
            StudySession(
                topicID: topicID,
                startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 16, hour: 22, minute: 40))!,
                endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 17, hour: 1, minute: 30))!,
                sessionIntervals: [
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 16, hour: 22, minute: 40))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 16, hour: 23, minute: 20))!
                    ),
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 16, hour: 23, minute: 53))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 17, hour: 0, minute: 23))!
                    ),
                    SessionInterval(
                        startDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 17, hour: 0, minute: 40))!,
                        endDate: calendar.date(from: DateComponents(year: 2000, month: 1, day: 17, hour: 0, minute: 55))!
                    )
                ]
            )
        ]

        let result = TimeCalculator.totalTime(from: sessions)
        #expect(result == 13_500) // 3h 45m
    }
}
extension TimeCalculatorTests
{
    @Test("Measure dailyTime execution time")
    func measureDailyTimeExecutionTime()
    {
        let calendar = Calendar(identifier: .gregorian)
        let topicID = UUID()
        let targetDay = date(year: 2000, month: 1, day: 20, hour: 12, minute: 0, calendar: calendar)

        let sessions = (0..<20_500).map
        { i in
            let dayStart = calendar.date(
                byAdding: .day,
                value: i % 30,
                to: date(year: 2000, month: 1, day: 1, hour: 22, minute: 30, calendar: calendar)
            )!

            let interval1Start = dayStart
            let interval1End = dayStart.addingTimeInterval(1_200) // 20m
            let interval2Start = dayStart.addingTimeInterval(4_200) // 23:40
            let interval2End = dayStart.addingTimeInterval(6_000) // 00:10 next day (crossing)

            return StudySession(
                topicID: topicID,
                startDate: dayStart,
                endDate: dayStart.addingTimeInterval(10_800), // 3h
                sessionIntervals: [
                    SessionInterval(startDate: interval1Start, endDate: interval1End),
                    SessionInterval(startDate: interval2Start, endDate: interval2End)
                ]
            )
        }

        let clock = ContinuousClock()
        let duration = clock.measure {
            _ = TimeCalculator.dailyTime(
                from: sessions,
                on: targetDay,
                calendar: calendar
            )
        }

        print("dailyTime took:", duration)
    }

    @Test("Measure totalTime execution time")
    func measureTotalTimeExecutionTime()
    {
        let calendar = Calendar(identifier: .gregorian)
        let topicID = UUID()

        let sessions = (0..<20_500).map { i in
            let baseDate = calendar.date(
                byAdding: .day,
                value: i,
                to: date(year: 2000, month: 1, day: 1, hour: 8, minute: 0, calendar: calendar)
            )!

            return StudySession(
                topicID: topicID,
                startDate: baseDate,
                endDate: baseDate.addingTimeInterval(7_200), // 2h
                sessionIntervals: [
                    SessionInterval(
                        startDate: baseDate,
                        endDate: baseDate.addingTimeInterval(1_500) // 25m
                    ),
                    SessionInterval(
                        startDate: baseDate.addingTimeInterval(1_800),
                        endDate: baseDate.addingTimeInterval(3_000) // 20m
                    ),
                    SessionInterval(
                        startDate: baseDate.addingTimeInterval(3_600),
                        endDate: baseDate.addingTimeInterval(4_500) // 15m
                    ),
                    SessionInterval(
                        startDate: baseDate.addingTimeInterval(5_000),
                        endDate: baseDate.addingTimeInterval(6_200) // 20m
                    )
                ]
            )
        }

        let clock = ContinuousClock()
        let duration = clock.measure {
            _ = TimeCalculator.totalTime(from: sessions)
        }

        print("totalTime took:", duration)
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
