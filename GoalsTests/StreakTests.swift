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

    @Test("Streak day is considered met if at least one topic met (contains(true))")
    func dayMetRuleAtLeastOneTopic() {
        let goal = Goal(goalInMinutes: 60, createdAt: TestDates.date(2025, 10, 10, 12, 0))
        let topicA = Topic(name: "A")
        let topicB = Topic(name: "B")

        let day = TestDates.date(2025, 10, 12, 9, 0)
        let sessions = [
            makeSession(topic: topicA, goal: goal, start: day, minutes: 60),
            makeSession(topic: topicB, goal: goal, start: day.addingTimeInterval(3600), minutes: 10),
        ]

        let streak = Streak(sessions: sessions)
        #expect(streak.longestStreak == 1)
        #expect(streak.currentStreak >= 0)
    }

    @Test("currentStreak anchors at today when today is met (otherwise yesterday)")
    func currentStreakAnchorBehavior() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let goal = Goal(goalInMinutes: 30, createdAt: TestDates.date(2025, 10, 10, 12, 0))
        let topic = Topic(name: "AnchorTopic")

        let sToday = makeSession(topic: topic, goal: goal, start: today.addingTimeInterval(10 * 60), minutes: 30)
        let sYesterday = makeSession(topic: topic, goal: goal, start: yesterday.addingTimeInterval(10 * 60), minutes: 30)

        let streakA = Streak(sessions: [sToday, sYesterday])
        #expect(streakA.currentStreak == 2)

        let sTodayUnmet = makeSession(topic: topic, goal: goal, start: today.addingTimeInterval(12 * 60), minutes: 10)
        let streakB = Streak(sessions: [sTodayUnmet, sYesterday])
        #expect(streakB.currentStreak == 1)
    }

    @Test("Missing days break current streak")
    func missingDaysBreakStreak() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let goal = Goal(goalInMinutes: 10, createdAt: TestDates.date(2025, 10, 10, 12, 0))
        let topic = Topic(name: "GapTopic")

        let sToday = makeSession(topic: topic, goal: goal, start: today.addingTimeInterval(10), minutes: 10)
        let sTwoDays = makeSession(topic: topic, goal: goal, start: twoDaysAgo.addingTimeInterval(10), minutes: 10)

        let streak = Streak(sessions: [sToday, sTwoDays])
        #expect(streak.currentStreak == 1)
    }

    @Test("longestStreak finds the maximum historical run")
    func longestStreakFindsMaxRun() {
        let goal = Goal(goalInMinutes: 10, createdAt: TestDates.date(2025, 10, 10, 12, 0))
        let topic = Topic(name: "Longest")

        let d1 = TestDates.date(2025, 10, 1, 9, 0)
        let d2 = TestDates.date(2025, 10, 2, 9, 0)
        let d4 = TestDates.date(2025, 10, 4, 9, 0)

        let sessions = [
            makeSession(topic: topic, goal: goal, start: d1, minutes: 10),
            makeSession(topic: topic, goal: goal, start: d2, minutes: 10),
            makeSession(topic: topic, goal: goal, start: d4, minutes: 10),
        ]

        let streak = Streak(sessions: sessions)
        #expect(streak.longestStreak == 2)
    }

    @Test("Per-topic streak counts only days where that topic is met (topic missing => false)")
    func perTopicStreakRules() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let goal = Goal(goalInMinutes: 30, createdAt: TestDates.date(2025, 10, 10, 12, 0))
        let topicA = Topic(name: "A")
        let topicB = Topic(name: "B")

        let yA = makeSession(topic: topicA, goal: goal, start: yesterday.addingTimeInterval(60), minutes: 30)

        let tB = makeSession(topic: topicB, goal: goal, start: today.addingTimeInterval(60), minutes: 30)
        let tAUnmet = makeSession(topic: topicA, goal: goal, start: today.addingTimeInterval(3600), minutes: 10)

        let streak = Streak(sessions: [yA, tB, tAUnmet])

        #expect(streak.currentStreak == 2)
        #expect(streak.currentStreak(for: topicA) == 1)
        #expect(streak.currentStreak(for: topicB) == 1)
    }
}
