import Foundation

struct ProgressPlanChartData
{
    enum TimeRange: String, CaseIterable, Identifiable
    {
        case currentWeek = "7 Days"
        case currentMonth = "30 Days"

        var id: Self { self }
    }

    struct Point: Identifiable, Equatable
    {
        let day: Date
        let hours: Double

        var id: Date { day }
    }

    struct Series: Identifiable, Equatable
    {
        let name: String
        let points: [Point]

        var id: String { name }
    }

    static let planSeriesName = "Plan"
    static let progressSeriesName = "Progress"

    static func series(
        for topicID: UUID,
        sessions: [StudySession],
        goals: [Goal],
        timeRange: TimeRange,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Series]
    {
        let days = days(in: timeRange, now: now, calendar: calendar)
        let topicGoals = goals
            .filter { $0.topicID == topicID && !$0.isArchived }
            .sorted { $0.createdAt < $1.createdAt }
        let progressByDay = indexedProgressSecondsByDay(
            for: topicID,
            sessions: sessions,
            days: days,
            calendar: calendar
        )

        var cumulativePlan: TimeInterval = 0
        var cumulativeProgress: TimeInterval = 0
        var planPoints: [Point] = []
        var progressPoints: [Point] = []

        planPoints.reserveCapacity(days.count)
        progressPoints.reserveCapacity(days.count)

        for day in days
        {
            cumulativePlan += targetSeconds(on: day, goals: topicGoals, calendar: calendar)
            cumulativeProgress += progressByDay[day, default: 0]

            planPoints.append(Point(day: day, hours: cumulativePlan / 3_600))
            progressPoints.append(Point(day: day, hours: cumulativeProgress / 3_600))
        }

        return [
            Series(name: planSeriesName, points: planPoints),
            Series(name: progressSeriesName, points: progressPoints)
        ]
    }

    static func days(
        in timeRange: TimeRange,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Date]
    {
        switch timeRange
        {
        case .currentWeek:
            return currentMondayToSunday(now: now, calendar: calendar)
        case .currentMonth:
            return currentMonthDays(now: now, calendar: calendar)
        }
    }

    private static func currentMondayToSunday(now: Date, calendar: Calendar) -> [Date]
    {
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7

        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) else
        {
            return []
        }

        return (0..<7).compactMap
        { offset in
            calendar.date(byAdding: .day, value: offset, to: monday)
        }
    }

    private static func currentMonthDays(now: Date, calendar: Calendar) -> [Date]
    {
        guard let monthInterval = calendar.dateInterval(of: .month, for: now),
              let dayRange = calendar.range(of: .day, in: .month, for: now)
        else
        {
            return []
        }

        return dayRange.compactMap
        { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start)
        }
    }

    private static func indexedProgressSecondsByDay(
        for topicID: UUID,
        sessions: [StudySession],
        days: [Date],
        calendar: Calendar
    ) -> [Date: TimeInterval]
    {
        guard let firstDay = days.first,
              let lastDay = days.last,
              let rangeEnd = calendar.date(byAdding: .day, value: 1, to: lastDay)
        else
        {
            return [:]
        }

        var totals: [Date: TimeInterval] = [:]
        totals.reserveCapacity(days.count)

        for session in sessions where session.topicID == topicID && !session.isArchived
        {
            for interval in session.sessionIntervals where !interval.isArchived
            {
                guard let endDate = interval.endDate else { continue }
                guard interval.startDate < rangeEnd, endDate > firstDay else { continue }

                addInterval(
                    startDate: interval.startDate,
                    endDate: endDate,
                    rangeStart: firstDay,
                    rangeEnd: rangeEnd,
                    totals: &totals,
                    calendar: calendar
                )
            }
        }

        return totals
    }

    private static func addInterval(
        startDate: Date,
        endDate: Date,
        rangeStart: Date,
        rangeEnd: Date,
        totals: inout [Date: TimeInterval],
        calendar: Calendar
    )
    {
        var day = calendar.startOfDay(for: max(startDate, rangeStart))
        let clippedEnd = min(endDate, rangeEnd)

        while day < clippedEnd
        {
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) else { break }

            let overlapStart = max(startDate, day)
            let overlapEnd = min(clippedEnd, dayEnd)

            if overlapStart < overlapEnd
            {
                totals[day, default: 0] += overlapEnd.timeIntervalSince(overlapStart)
            }

            day = dayEnd
        }
    }

    private static func targetSeconds(
        on day: Date,
        goals: [Goal],
        calendar: Calendar
    ) -> TimeInterval
    {
        guard let dayEnd = calendar.dateInterval(of: .day, for: day)?.end,
              let goal = goals.last(where: { $0.createdAt < dayEnd })
        else
        {
            return 0
        }

        return goal.targetSecondsPerDay
    }
}
