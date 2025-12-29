//
//  ProgressVsPlanTests.swift
//  GoalsTests
//
//  Created by Adolfo Gerard Montilla Gonzalez on 29-12-25.
//

import Foundation
import Testing
@testable import Goals

/// These tests define (via TDD) the expected business behavior for the
/// "Progress vs Plan" domain service/model.
///
/// Expected API (to be implemented in app code):
/// - ProgressVsPlan.compute(topic:sessions:range:pageOffset:now:) -> ProgressVsPlan.Report
/// - ProgressVsPlan.Range: .days7, .days30, .months12
/// - ProgressVsPlan.Report:
///     - isPlanAvailable: Bool
///     - points: [ProgressVsPlan.Point]
///     - actualTotalMinutes: Int
///     - planTotalMinutes: Int?
///     - deltaMinutes: Int?
///     - status: ProgressVsPlan.Status? (.ahead / .behind)
///     - insight: String?
/// - ProgressVsPlan.Point:
///     - periodDate: Date
///     - actualCumulativeMinutes: Int
///     - planCumulativeMinutes: Int?
///
/// Notes:
/// - 7D/30D: daily points, inclusive of "today".
/// - 12M: monthly points; window ends at "today".
/// - Chart starts at the first TopicGoalChange day (if topic has < window length, show fewer points).
/// - Plan is "not available" if goal resolution is nil anywhere in the shown range or if no goalChanges exist.
/// - Sessions are attributed to the day of their startDate (no splitting across midnight).
struct ProgressVsPlanTests {

    // MARK: - Helpers

    private var cal: Calendar {
        var c = Calendar.current
        c.timeZone = .current
        return c
    }

    private func dayStart(_ d: Date) -> Date { cal.startOfDay(for: d) }

    private func addDays(_ d: Date, _ days: Int) -> Date {
        cal.date(byAdding: .day, value: days, to: d)!
    }

    @discardableResult
    private func makeGoal(topic: Topic, minutes: Int, effectiveAt: Date) -> TopicGoalChange {
        let g = TopicGoalChange(topic: topic, goalInMinutes: minutes, effectiveAt: effectiveAt)
        topic.goalChanges.append(g)
        return g
    }

    /// Inclusive day count between two start-of-day dates (e.g., Dec 1..Dec 1 = 1).
    private func inclusiveDayCount(from startDay: Date, to endDay: Date) -> Int {
        let s = dayStart(startDay)
        let e = dayStart(endDay)
        let diff = cal.dateComponents([.day], from: s, to: e).day ?? 0
        return max(0, diff + 1)
    }

    private func monthStart(_ d: Date) -> Date {
        let comps = cal.dateComponents([.year, .month], from: d)
        return cal.date(from: comps)!
    }

    private func monthsInclusive(from startMonth: Date, to endMonth: Date) -> Int {
        let s = monthStart(startMonth)
        let e = monthStart(endMonth)
        let diff = cal.dateComponents([.month], from: s, to: e).month ?? 0
        return max(0, diff + 1)
    }

    // MARK: - Tests

    @Test("Plan not available when topic has no goalChanges (service returns points with nil plan + no KPIs/insight for plan)")
    func planUnavailableWhenNoGoalChanges() {
        let now = TestDates.date(2025, 12, 29, 10, 0)
        let topic = Topic(name: "No Goal")

        // Some sessions exist, but there is no goal snapshot -> plan not available.
        let today = dayStart(now)
        let s1 = makeSession(topic: topic, start: today.addingTimeInterval(60), minutes: 25)

        let report = ProgressVsPlan.compute(
            topic: topic,
            sessions: [s1],
            range: .days7,
            pageOffset: 0,
            now: now
        )

        #expect(report.isPlanAvailable == false)
        #expect(report.points.isEmpty == false) // still okay to show Actual-only line
        #expect(report.points.allSatisfy { $0.planCumulativeMinutes == nil })

        #expect(report.actualTotalMinutes == 25)
        #expect(report.planTotalMinutes == nil)
        #expect(report.deltaMinutes == nil)
        #expect(report.status == nil)
        #expect(report.insight == nil)
    }

    @Test("7D: daily cumulative points, plan uses full daily goal (including today), and KPIs compute Behind correctly")
    func days7CumulativeAndKpisBehind() throws {
        let now = TestDates.date(2025, 12, 29, 10, 0)
        let topic = Topic(name: "7D Topic")

        let today = dayStart(now)
        let start7 = addDays(today, -6)

        // Goal active before the 7D window: 60 min/day.
        makeGoal(topic: topic, minutes: 60, effectiveAt: addDays(today, -30))

        // Sessions inside the 7D window:
        // Day -6: 30m, Day -4: 60m, Day -1: 90m, Today: 0m. Total = 180.
        let d0 = start7
        let d2 = addDays(start7, 2)
        let d5 = addDays(start7, 5)

        let sA = makeSession(topic: topic, start: d0.addingTimeInterval(9 * 3600), minutes: 30)
        let sB = makeSession(topic: topic, start: d2.addingTimeInterval(9 * 3600), minutes: 60)
        let sC = makeSession(topic: topic, start: d5.addingTimeInterval(9 * 3600), minutes: 90)

        let report = ProgressVsPlan.compute(
            topic: topic,
            sessions: [sA, sB, sC],
            range: .days7,
            pageOffset: 0,
            now: now
        )

        #expect(report.isPlanAvailable == true)
        #expect(report.points.count == 7)

        // Points sorted
        #expect(report.points.first!.periodDate < report.points.last!.periodDate)

        // End-of-range totals
        let expectedPlan = 7 * 60
        let expectedActual = 30 + 60 + 90

        #expect(report.actualTotalMinutes == expectedActual)
        #expect(report.planTotalMinutes == expectedPlan)

        let delta = try #require(report.deltaMinutes)
        let status = try #require(report.status)
        let insight = try #require(report.insight)

        #expect(delta == expectedActual - expectedPlan)
        #expect(delta < 0)
        #expect(status == .behind)
        #expect(insight.lowercased().contains("behind"))
    }

    @Test("7D navigation: pageOffset shifts the window (current vs previous week totals differ and do not mix)")
    func days7NavigationOffsetShiftsWindow() {
        let now = TestDates.date(2025, 12, 29, 10, 0)
        let topic = Topic(name: "Nav Topic")

        let today = dayStart(now)
        let startCurrent = addDays(today, -6)           // current 7D start
        let startPrev = addDays(today, -13)             // previous 7D start

        // Goal: 20 min/day, active long before.
        makeGoal(topic: topic, minutes: 20, effectiveAt: addDays(today, -100))

        // Put sessions in previous window only (total 60) and in current window only (total 20).
        // Previous window: 3 days x 20m
        let p0 = startPrev
        let p2 = addDays(startPrev, 2)
        let p6 = addDays(startPrev, 6)
        let prevSessions = [
            makeSession(topic: topic, start: p0.addingTimeInterval(3600), minutes: 20),
            makeSession(topic: topic, start: p2.addingTimeInterval(3600), minutes: 20),
            makeSession(topic: topic, start: p6.addingTimeInterval(3600), minutes: 20),
        ]

        // Current window: 1 day x 20m
        let c3 = addDays(startCurrent, 3)
        let currSessions = [
            makeSession(topic: topic, start: c3.addingTimeInterval(3600), minutes: 20),
        ]

        let all = prevSessions + currSessions

        let current = ProgressVsPlan.compute(topic: topic, sessions: all, range: .days7, pageOffset: 0, now: now)
        let previous = ProgressVsPlan.compute(topic: topic, sessions: all, range: .days7, pageOffset: -1, now: now)

        #expect(current.actualTotalMinutes == 20)
        #expect(previous.actualTotalMinutes == 60)

        #expect(current.points.count == 7)
        #expect(previous.points.count == 7)

        // Sanity: plan totals remain 7*20 in both (window length unchanged).
        #expect(current.planTotalMinutes == 7 * 20)
        #expect(previous.planTotalMinutes == 7 * 20)
    }

    @Test("Sessions crossing midnight are fully attributed to the start day (no splitting) in daily buckets")
    func midnightCrossingSessionCountsOnStartDay() throws {
        let now = TestDates.date(2025, 12, 29, 10, 0)
        let topic = Topic(name: "Midnight Topic")

        let today = dayStart(now)
        let yesterday = addDays(today, -1)

        makeGoal(topic: topic, minutes: 10, effectiveAt: addDays(today, -50))

        // One session crosses midnight: 23:50 -> 00:10 (20 min), starts yesterday.
        let crossStart = cal.date(bySettingHour: 23, minute: 50, second: 0, of: yesterday)!
        let cross = StudySession(topic: topic, startDate: crossStart, endDate: addDays(crossStart, 1).addingTimeInterval(20 * 60 - 24 * 3600))
        // Above line ensures endDate = crossStart + 20 minutes (even if it crosses).

        // One session today: 10 min
        let todaySession = makeSession(topic: topic, start: today.addingTimeInterval(8 * 3600), minutes: 10)

        let report = ProgressVsPlan.compute(
            topic: topic,
            sessions: [cross, todaySession],
            range: .days7,
            pageOffset: 0,
            now: now
        )

        #expect(report.isPlanAvailable == true)
        #expect(report.points.count == 7)

        // Find cumulative at yesterday and today, and compare the increment (daily) implied.
        // Since the crossing session counts on yesterday, the jump from dayBeforeYesterday->yesterday includes +20.
        // The jump from yesterday->today includes only +10 (todaySession).
        let dayBeforeYesterday = addDays(yesterday, -1)

        func point(for day: Date) -> ProgressVsPlan.Point {
            report.points.first(where: { dayStart($0.periodDate) == dayStart(day) })!
        }

        let pDBY = point(for: dayBeforeYesterday)
        let pY = point(for: yesterday)
        let pT = point(for: today)

        let incYesterday = pY.actualCumulativeMinutes - pDBY.actualCumulativeMinutes
        let incToday = pT.actualCumulativeMinutes - pY.actualCumulativeMinutes

        #expect(incYesterday == 20)
        #expect(incToday == 10)

        // Total actual = 30
        #expect(report.actualTotalMinutes == 30)
    }

    @Test("12M: monthly points, window ends today, starts at first goalChange (topic younger than 12M => fewer than 12 points)")
    func months12MonthlyBucketsAndAnchorAtFirstGoalChange() throws {
        let now = TestDates.date(2025, 12, 29, 10, 0)
        let topic = Topic(name: "12M Topic")

        let today = dayStart(now)

        // First goal change is mid-October: chart should start there, not earlier.
        let firstGoalDay = TestDates.date(2025, 10, 15, 12, 0)
        makeGoal(topic: topic, minutes: 1, effectiveAt: firstGoalDay) // 1 minute/day for easy totals

        // Actual sessions: 10m in Oct, 20m in Nov, 30m in Dec (all should be included).
        let sOct = makeSession(topic: topic, start: TestDates.date(2025, 10, 20, 9, 0), minutes: 10)
        let sNov = makeSession(topic: topic, start: TestDates.date(2025, 11, 10, 9, 0), minutes: 20)
        let sDec = makeSession(topic: topic, start: TestDates.date(2025, 12, 5,  9, 0), minutes: 30)

        let report = ProgressVsPlan.compute(
            topic: topic,
            sessions: [sOct, sNov, sDec],
            range: .months12,
            pageOffset: 0,
            now: now
        )

        #expect(report.isPlanAvailable == true)

        // Points should be one per month from Oct 2025 to Dec 2025 inclusive => 3 points.
        let expectedPointCount = monthsInclusive(from: firstGoalDay, to: today)
        #expect(report.points.count == expectedPointCount)
        #expect(report.points.count == 3)

        // Plan total is 1 minute per day from firstGoalDay's startOfDay through today (inclusive).
        let expectedPlan = inclusiveDayCount(from: dayStart(firstGoalDay), to: today) * 1
        #expect(report.planTotalMinutes == expectedPlan)

        // Actual total is sum of sessions.
        #expect(report.actualTotalMinutes == 10 + 20 + 30)

        let delta = try #require(report.deltaMinutes)
        let status = try #require(report.status)
        _ = try #require(report.insight)

        // Status depends on totals; we just assert delta matches arithmetic and status matches sign rule.
        #expect(delta == (report.actualTotalMinutes - expectedPlan))
        #expect((delta >= 0) == (status == .ahead))
        #expect((delta < 0) == (status == .behind))
    }
}
