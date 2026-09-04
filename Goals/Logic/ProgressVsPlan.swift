//
//  ProgressVsPlan.swift
//  Goals
//
//  Builds chart data from V3 raw tracking records.
//

import Foundation

struct ProgressVsPlan
{
    enum Range: Equatable
    {
        case days7
        case days30
        case months12
    }

    enum Status: Equatable
    {
        case ahead
        case behind
    }

    struct Point: Equatable
    {
        let periodDate: Date
        let actualCumulativeMinutes: Int
        let planCumulativeMinutes: Int?
    }

    struct Report: Equatable
    {
        let isPlanAvailable: Bool
        let points: [Point]
        let actualTotalMinutes: Int
        let planTotalMinutes: Int?
        let deltaMinutes: Int?
        let status: Status?
        let insight: String?
    }

    static func compute(
        topic: Topic,
        sessions: [StudySession],
        goals: [Goal],
        range: Range,
        pageOffset: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Report
    {
        let topicSessions = sessions.filter { $0.topicID == topic.id }
        let topicGoals = goals
            .filter { $0.topicID == topic.id && !$0.isArchived }
            .sorted { $0.createdAt < $1.createdAt }
        let periods = periodsForRange(range, pageOffset: pageOffset, now: now, calendar: calendar)

        var actualCumulativeSeconds: TimeInterval = 0
        var planCumulativeSeconds: TimeInterval = 0
        var hasPlan = false
        var points: [Point] = []
        points.reserveCapacity(periods.count)

        for period in periods
        {
            actualCumulativeSeconds += actualSeconds(
                from: topicSessions,
                in: period,
                range: range,
                calendar: calendar
            )

            if let planSeconds = plannedSeconds(
                from: topicGoals,
                in: period,
                range: range,
                calendar: calendar
            )
            {
                hasPlan = true
                planCumulativeSeconds += planSeconds
            }

            points.append(
                Point(
                    periodDate: period.start,
                    actualCumulativeMinutes: Int(actualCumulativeSeconds / 60),
                    planCumulativeMinutes: hasPlan ? Int(planCumulativeSeconds / 60) : nil
                )
            )
        }

        let actualTotalMinutes = Int(actualCumulativeSeconds / 60)
        let planTotalMinutes = hasPlan ? Int(planCumulativeSeconds / 60) : nil
        let deltaMinutes = planTotalMinutes.map { actualTotalMinutes - $0 }
        let status = deltaMinutes.map { $0 >= 0 ? Status.ahead : Status.behind }

        return Report(
            isPlanAvailable: hasPlan,
            points: points,
            actualTotalMinutes: actualTotalMinutes,
            planTotalMinutes: planTotalMinutes,
            deltaMinutes: deltaMinutes,
            status: status,
            insight: insight(deltaMinutes: deltaMinutes, status: status)
        )
    }

    static func compute(
        topic: Topic,
        sessions: [StudySession],
        range: Range,
        pageOffset: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Report
    {
        compute(
            topic: topic,
            sessions: sessions,
            goals: [],
            range: range,
            pageOffset: pageOffset,
            now: now,
            calendar: calendar
        )
    }

    private static func actualSeconds(
        from sessions: [StudySession],
        in period: DateInterval,
        range: Range,
        calendar: Calendar
    ) -> TimeInterval
    {
        switch range
        {
        case .days7, .days30:
            return TimeCalculator.dailyTime(from: sessions, on: period.start, calendar: calendar)
        case .months12:
            var total: TimeInterval = 0
            var day = period.start
            while day < period.end
            {
                total += TimeCalculator.dailyTime(from: sessions, on: day, calendar: calendar)
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = nextDay
            }
            return total
        }
    }

    private static func plannedSeconds(
        from goals: [Goal],
        in period: DateInterval,
        range: Range,
        calendar: Calendar
    ) -> TimeInterval?
    {
        switch range
        {
        case .days7, .days30:
            guard let goal = activeGoal(on: period.start, goals: goals, calendar: calendar) else { return nil }
            return goal.targetSecondsPerDay
        case .months12:
            var total: TimeInterval = 0
            var hasGoal = false
            var day = period.start

            while day < period.end
            {
                if let goal = activeGoal(on: day, goals: goals, calendar: calendar)
                {
                    hasGoal = true
                    total += goal.targetSecondsPerDay
                }

                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = nextDay
            }

            return hasGoal ? total : nil
        }
    }

    private static func activeGoal(on day: Date, goals: [Goal], calendar: Calendar) -> Goal?
    {
        guard let dayEnd = calendar.dateInterval(of: .day, for: day)?.end else { return nil }
        return goals.last { $0.createdAt < dayEnd }
    }

    private static func periodsForRange(
        _ range: Range,
        pageOffset: Int,
        now: Date,
        calendar: Calendar
    ) -> [DateInterval]
    {
        let today = calendar.startOfDay(for: now)

        switch range
        {
        case .days7:
            return dailyWindow(length: 7, pageOffset: pageOffset, today: today, calendar: calendar)
        case .days30:
            return dailyWindow(length: 30, pageOffset: pageOffset, today: today, calendar: calendar)
        case .months12:
            return monthlyWindow(pageOffset: pageOffset, today: today, calendar: calendar)
        }
    }

    private static func dailyWindow(
        length: Int,
        pageOffset: Int,
        today: Date,
        calendar: Calendar
    ) -> [DateInterval]
    {
        let end = calendar.date(byAdding: .day, value: pageOffset * length, to: today) ?? today
        let start = calendar.date(byAdding: .day, value: -(length - 1), to: end) ?? end
        return (0..<length).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return calendar.dateInterval(of: .day, for: day)
        }
    }

    private static func monthlyWindow(
        pageOffset: Int,
        today: Date,
        calendar: Calendar
    ) -> [DateInterval]
    {
        let shiftedEnd = calendar.date(byAdding: .month, value: pageOffset * 12, to: today) ?? today
        let components = calendar.dateComponents([.year, .month], from: shiftedEnd)
        let endMonth = calendar.date(from: components) ?? shiftedEnd
        let startMonth = calendar.date(byAdding: .month, value: -11, to: endMonth) ?? endMonth
        return (0..<12).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: offset, to: startMonth) else { return nil }
            return calendar.dateInterval(of: .month, for: month)
        }
    }

    private static func insight(deltaMinutes: Int?, status: Status?) -> String?
    {
        guard let deltaMinutes, let status else { return nil }
        let minutes = abs(deltaMinutes)
        let hours = minutes / 60
        let remainder = minutes % 60
        let duration = hours > 0 ? String(format: "%dh %02dm", hours, remainder) : "\(remainder)m"

        switch status
        {
        case .ahead:
            return "You are \(duration) ahead of your plan."
        case .behind:
            return "You are \(duration) behind your plan."
        }
    }
}
