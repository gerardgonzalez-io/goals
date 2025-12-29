//
//  ProgressVsPlan.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 29-12-25.
//
//  service/model for: "Progress vs Plan" (Swift Charts)
//  - Pure business logic: takes Topic + sessions + range + offset + now
//  - Returns chart-ready points + KPIs + insight

import Foundation

struct ProgressVsPlan {

    // MARK: - Public API

    enum Range: Equatable {
        case days7
        case days30
        case months12
    }

    enum Status: Equatable {
        case ahead
        case behind
    }

    struct Point: Equatable {
        let periodDate: Date
        let actualCumulativeMinutes: Int
        let planCumulativeMinutes: Int?
    }

    struct Report: Equatable {
        let isPlanAvailable: Bool
        let points: [Point]

        let actualTotalMinutes: Int
        let planTotalMinutes: Int?

        let deltaMinutes: Int?
        let status: Status?

        /// A short, UI-ready message. Nil when plan is not available.
        let insight: String?
    }

    /// Computes the "Progress vs Plan" report for a topic.
    ///
    /// - Important:
    ///   - Sessions are attributed to the day of `startDate` (via `StudySession.normalizedDay`).
    ///   - 7D/30D produce daily points, inclusive of "today" (or shifted end by pageOffset).
    ///   - 12M produces monthly points, window ends at "today" (or shifted end by pageOffset).
    ///   - Chart starts at the first `TopicGoalChange` day when plan is available.
    ///   - Plan is unavailable if:
    ///       - topic has no goalChanges, OR
    ///       - goal resolution is nil for any day within the shown range.
    static func compute(
        topic: Topic,
        sessions: [StudySession],
        range: Range,
        pageOffset: Int,
        now: Date = Date(),
        calendar: Calendar = {
            var c = Calendar.current
            c.timeZone = .current
            return c
        }()
    ) -> Report {

        let topicID = topic.id
        let topicSessions = sessions.filter { $0.topic.id == topicID }

        // If there are no goal changes at all, plan is not available.
        let hasAnyGoalChange = !topic.goalChanges.isEmpty

        let today = calendar.startOfDay(for: now)

        // Earliest goal day (start of day) used as chart anchor when plan is available.
        let firstGoalDay: Date? = topic.goalChanges
            .map { $0.effectiveFromDay }
            .min()

        switch range {
        case .days7:
            return computeDaily(
                topic: topic,
                sessions: topicSessions,
                today: today,
                lengthInDays: 7,
                pageOffset: pageOffset,
                hasAnyGoalChange: hasAnyGoalChange,
                firstGoalDay: firstGoalDay,
                calendar: calendar
            )

        case .days30:
            return computeDaily(
                topic: topic,
                sessions: topicSessions,
                today: today,
                lengthInDays: 30,
                pageOffset: pageOffset,
                hasAnyGoalChange: hasAnyGoalChange,
                firstGoalDay: firstGoalDay,
                calendar: calendar
            )

        case .months12:
            return computeMonthly12(
                topic: topic,
                sessions: topicSessions,
                today: today,
                pageOffset: pageOffset,
                hasAnyGoalChange: hasAnyGoalChange,
                firstGoalDay: firstGoalDay,
                calendar: calendar
            )
        }
    }
}

// MARK: - Daily (7D / 30D)

private extension ProgressVsPlan {

    static func computeDaily(
        topic: Topic,
        sessions: [StudySession],
        today: Date,
        lengthInDays: Int,
        pageOffset: Int,
        hasAnyGoalChange: Bool,
        firstGoalDay: Date?,
        calendar: Calendar
    ) -> Report {

        // Window ends at (today + offset * length).
        let end = calendar.date(byAdding: .day, value: pageOffset * lengthInDays, to: today)
            .map { calendar.startOfDay(for: $0) } ?? today
        let requestedStart = calendar.date(byAdding: .day, value: -(lengthInDays - 1), to: end)!
        var start = calendar.startOfDay(for: requestedStart)

        // Anchor to firstGoalDay when plan exists.
        if hasAnyGoalChange, let fg = firstGoalDay {
            if end < fg {
                // Should be prevented by UI, but clamp defensively.
                start = fg
            } else {
                start = max(start, fg)
            }
        }

        let days = enumerateDays(from: start, to: end, calendar: calendar)

        // Actual minutes per day (source: sessions)
        let actualByDay = sumActualMinutesByDay(sessions: sessions, calendar: calendar)

        // Build points with cumulative actual and (maybe) cumulative plan.
        var points: [Point] = []
        points.reserveCapacity(days.count)

        var actualCum = 0
        var planCum = 0
        var planAvailable = hasAnyGoalChange

        // First pass: determine plan availability and compute cumulative values.
        for day in days {
            let dailyActual = actualByDay[day] ?? 0
            actualCum += dailyActual

            if planAvailable {
                guard let dailyGoal = topic.goalInMinutes(for: day) else {
                    planAvailable = false
                    // From now on, we will produce nil plan values for all points.
                    continue
                }
                planCum += dailyGoal
            }
        }

        // Second pass: emit points (keeping logic compact and deterministic).
        actualCum = 0
        planCum = 0

        for day in days {
            let dailyActual = actualByDay[day] ?? 0
            actualCum += dailyActual

            if planAvailable {
                // Safe to force unwrap: planAvailable implies goal exists for all days.
                planCum += topic.goalInMinutes(for: day)!
                points.append(Point(periodDate: day, actualCumulativeMinutes: actualCum, planCumulativeMinutes: planCum))
            } else {
                points.append(Point(periodDate: day, actualCumulativeMinutes: actualCum, planCumulativeMinutes: nil))
            }
        }

        return makeReport(
            rangeLabel: lengthInDays == 7 ? "last 7 days" : "last 30 days",
            planAvailable: planAvailable,
            points: points
        )
    }
}

// MARK: - Monthly (12M)

private extension ProgressVsPlan {

    static func computeMonthly12(
        topic: Topic,
        sessions: [StudySession],
        today: Date,
        pageOffset: Int,
        hasAnyGoalChange: Bool,
        firstGoalDay: Date?,
        calendar: Calendar
    ) -> Report {

        // End day shifts by 12 months * offset (window ends at that shifted "today").
        let shiftedEndDay = calendar.date(byAdding: .month, value: pageOffset * 12, to: today)
            .map { calendar.startOfDay(for: $0) } ?? today

        // Determine monthly window: last 12 months ending at endMonthStart.
        let endMonthStart = monthStart(of: shiftedEndDay, calendar: calendar)
        let requestedStartMonthStart = calendar.date(byAdding: .month, value: -11, to: endMonthStart)!
        let requestedStartDay = calendar.startOfDay(for: requestedStartMonthStart)

        // Anchor to the month containing the first goal day (and to the first goal day itself for plan accumulation).
        var planAvailable = hasAnyGoalChange
        var rangeStartDay = requestedStartDay

        if hasAnyGoalChange, let fg = firstGoalDay {
            let fgDay = calendar.startOfDay(for: fg)
            if shiftedEndDay < fgDay {
                // Should be prevented by UI; clamp defensively.
                rangeStartDay = fgDay
            } else {
                rangeStartDay = max(rangeStartDay, fgDay)
            }
        }

        // Monthly buckets start at the month containing rangeStartDay (so Oct 15 -> includes Oct).
        let startMonthStart = monthStart(of: rangeStartDay, calendar: calendar)

        // Build list of month starts inclusive.
        let months = enumerateMonthStarts(from: startMonthStart, to: endMonthStart, calendar: calendar)

        // Prepare daily actual + daily plan across the whole day-range we will consider.
        // Day-range for monthly aggregation goes from rangeStartDay through shiftedEndDay inclusive.
        let days = enumerateDays(from: rangeStartDay, to: shiftedEndDay, calendar: calendar)
        let actualByDay = sumActualMinutesByDay(sessions: sessions, calendar: calendar)

        // Validate plan availability by ensuring all days have a goal when plan is expected.
        if planAvailable {
            for day in days {
                if topic.goalInMinutes(for: day) == nil {
                    planAvailable = false
                    break
                }
            }
        }

        // Accumulate monthly.
        var points: [Point] = []
        points.reserveCapacity(months.count)

        var actualCum = 0
        var planCum = 0

        for mStart in months {
            let mEnd = monthEndDay(forMonthStart: mStart, endCapDay: shiftedEndDay, calendar: calendar)

            // Month effective start is clamped to rangeStartDay if this is the first month.
            let effectiveStart = max(mStart, rangeStartDay)
            let effectiveDays = enumerateDays(from: effectiveStart, to: mEnd, calendar: calendar)

            var actualThisBucket = 0
            var planThisBucket = 0

            for day in effectiveDays {
                actualThisBucket += (actualByDay[day] ?? 0)
                if planAvailable {
                    planThisBucket += topic.goalInMinutes(for: day)! // safe if available
                }
            }

            actualCum += actualThisBucket
            if planAvailable { planCum += planThisBucket }

            points.append(
                Point(
                    periodDate: mStart,
                    actualCumulativeMinutes: actualCum,
                    planCumulativeMinutes: planAvailable ? planCum : nil
                )
            )
        }

        return makeReport(
            rangeLabel: "last 12 months",
            planAvailable: planAvailable,
            points: points
        )
    }
}

// MARK: - Report composition

private extension ProgressVsPlan {

    static func makeReport(
        rangeLabel: String,
        planAvailable: Bool,
        points: [Point]
    ) -> Report {

        let actualTotal = points.last?.actualCumulativeMinutes ?? 0

        if !planAvailable {
            return Report(
                isPlanAvailable: false,
                points: points,
                actualTotalMinutes: actualTotal,
                planTotalMinutes: nil,
                deltaMinutes: nil,
                status: nil,
                insight: nil
            )
        }

        let planTotal = points.last?.planCumulativeMinutes ?? 0
        let delta = actualTotal - planTotal

        let status: Status = (delta >= 0) ? .ahead : .behind
        let absDeltaText = formatMinutes(abs(delta))

        let insight: String
        if status == .ahead {
            insight = "You're ahead by \(absDeltaText) in \(rangeLabel)."
        } else {
            insight = "You're behind by \(absDeltaText) in \(rangeLabel)."
        }

        return Report(
            isPlanAvailable: true,
            points: points,
            actualTotalMinutes: actualTotal,
            planTotalMinutes: planTotal,
            deltaMinutes: delta,
            status: status,
            insight: insight
        )
    }
}

// MARK: - Utilities

private extension ProgressVsPlan {

    static func sumActualMinutesByDay(
        sessions: [StudySession],
        calendar: Calendar
    ) -> [Date: Int] {
        var map: [Date: Int] = [:]
        map.reserveCapacity(min(64, sessions.count))

        for s in sessions {
            let day = calendar.startOfDay(for: s.startDate) // align with StudySession.normalizedDay logic
            map[day, default: 0] += s.durationInMinutes
        }
        return map
    }

    static func enumerateDays(from startDay: Date, to endDay: Date, calendar: Calendar) -> [Date] {
        let s = calendar.startOfDay(for: startDay)
        let e = calendar.startOfDay(for: endDay)
        guard s <= e else { return [] }

        var result: [Date] = []
        var d = s
        while d <= e {
            result.append(d)
            guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
            d = calendar.startOfDay(for: next)
        }
        return result
    }

    static func monthStart(of date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps)!
    }

    static func enumerateMonthStarts(from startMonthStart: Date, to endMonthStart: Date, calendar: Calendar) -> [Date] {
        let s = monthStart(of: startMonthStart, calendar: calendar)
        let e = monthStart(of: endMonthStart, calendar: calendar)
        guard s <= e else { return [] }

        var result: [Date] = []
        var m = s
        while m <= e {
            result.append(m)
            guard let next = calendar.date(byAdding: .month, value: 1, to: m) else { break }
            m = monthStart(of: next, calendar: calendar)
        }
        return result
    }

    /// Returns the last day (start-of-day) of a month bucket, capped by `endCapDay`.
    static func monthEndDay(forMonthStart monthStartDate: Date, endCapDay: Date, calendar: Calendar) -> Date {
        let cap = calendar.startOfDay(for: endCapDay)

        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStartDate) else { return cap }

        let nextMonthStart = monthStart(of: nextMonth, calendar: calendar)
        let lastDay = calendar.date(byAdding: .day, value: -1, to: nextMonthStart)!
        let lastDayStart = calendar.startOfDay(for: lastDay)

        return min(lastDayStart, cap)
    }

    static func formatMinutes(_ minutes: Int) -> String {
        if minutes <= 0 { return "0m" }
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
