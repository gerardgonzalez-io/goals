//
//  StreakTests.swift
//  GoalsTests
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-12-25.
//

import Foundation
import Testing
@testable import Goals

struct StreakTests
{

    @Test("currentStreak(for:) anchors at today when today is met (otherwise yesterday) for that topic")
    func currentStreakAnchorBehaviorPerTopic() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let topic = Topic(name: "AnchorTopic")

        // Snapshot goal: 30 minutes (active since yesterday)
        let g = TopicGoalChange(topic: topic, goalInMinutes: 30, effectiveFromDay: yesterday)
        topic.goalChanges.append(g)

        let sTodayMet = makeSession(topic: topic, start: today.addingTimeInterval(10 * 60), minutes: 30)
        let sYesterdayMet = makeSession(topic: topic, start: yesterday.addingTimeInterval(10 * 60), minutes: 30)

        let streakA = Streak(sessions: [sTodayMet, sYesterdayMet])
        #expect(streakA.currentStreak(for: topic) == 2)

        // Today is NOT met (10 < 30), yesterday is met => anchor at yesterday => streak = 1
        let sTodayUnmet = makeSession(topic: topic, start: today.addingTimeInterval(12 * 60), minutes: 10)
        let streakB = Streak(sessions: [sTodayUnmet, sYesterdayMet])
        #expect(streakB.currentStreak(for: topic) == 1)
    }

    @Test("Missing days break current streak for that topic")
    func missingDaysBreakStreakPerTopic() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let topic = Topic(name: "GapTopic")

        // Snapshot goal: 10 minutes (active since twoDaysAgo)
        let g = TopicGoalChange(topic: topic, goalInMinutes: 10, effectiveFromDay: twoDaysAgo)
        topic.goalChanges.append(g)

        let sToday = makeSession(topic: topic, start: today.addingTimeInterval(10), minutes: 10)
        let sTwoDays = makeSession(topic: topic, start: twoDaysAgo.addingTimeInterval(10), minutes: 10)

        let streak = Streak(sessions: [sToday, sTwoDays])
        // Yesterday has no sessions for this topic => streak breaks, and since today is met => streak = 1
        #expect(streak.currentStreak(for: topic) == 1)
    }

    @Test("longestStreak(for:) finds the maximum historical run for that topic")
    func longestStreakFindsMaxRunPerTopic() {
        let topic = Topic(name: "Longest")

        // Snapshot goal: 10 minutes
        let g = TopicGoalChange(topic: topic, goalInMinutes: 10, effectiveFromDay: TestDates.date(2025, 10, 1, 0, 0))
        topic.goalChanges.append(g)

        let d1 = TestDates.date(2025, 10, 1, 9, 0)
        let d2 = TestDates.date(2025, 10, 2, 9, 0)
        let d4 = TestDates.date(2025, 10, 4, 9, 0)

        let sessions = [
            makeSession(topic: topic, start: d1, minutes: 10),
            makeSession(topic: topic, start: d2, minutes: 10),
            makeSession(topic: topic, start: d4, minutes: 10),
        ]

        let streak = Streak(sessions: sessions)
        #expect(streak.longestStreak(for: topic) == 2)
    }

    @Test("Per-topic streak counts only days where that topic is met (topic missing => breaks)")
    func perTopicStreakRules() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let topicA = Topic(name: "A")
        let topicB = Topic(name: "B")

        // Snapshot goals: both need 30 minutes
        topicA.goalChanges.append(TopicGoalChange(topic: topicA, goalInMinutes: 30, effectiveFromDay: yesterday))
        topicB.goalChanges.append(TopicGoalChange(topic: topicB, goalInMinutes: 30, effectiveFromDay: yesterday))

        // Yesterday: A met
        let yA = makeSession(topic: topicA, start: yesterday.addingTimeInterval(60), minutes: 30)

        // Today: B met, A unmet
        let tB = makeSession(topic: topicB, start: today.addingTimeInterval(60), minutes: 30)
        let tAUnmet = makeSession(topic: topicA, start: today.addingTimeInterval(3600), minutes: 10)

        let streak = Streak(sessions: [yA, tB, tAUnmet])

        #expect(streak.currentStreak(for: topicA) == 1) // today unmet => anchor yesterday => 1
        #expect(streak.currentStreak(for: topicB) == 1) // today met => 1 (no yesterday sessions for B => breaks)
    }
}
