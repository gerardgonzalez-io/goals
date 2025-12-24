//
//  DailyStatusTests.swift
//  GoalsTests
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-12-25.
//

import Foundation
import Testing
@testable import Goals

struct DailyStatusTests {

    @Test("DailyStatus.compute returns nil for empty sessions")
    func computeNilOnEmpty() {
        #expect(DailyStatus.compute(from: []) == nil)
    }

    @Test("DailyStatus groups by topic, sums durations, picks most recent goal, and computes isMet from total")
    func computeBusinessRules() throws {
        let oldGoal = Goal(goalInMinutes: 60, createdAt: TestDates.date(2025, 10, 10, 12, 0))
        let newGoal = Goal(goalInMinutes: 60, createdAt: TestDates.date(2025, 10, 11, 12, 0))

        let topicA = Topic(name: "Topic A")
        let topicB = Topic(name: "Topic B")

        let day = TestDates.date(2025, 10, 12, 9, 0)

        let a1 = makeSession(topic: topicA, goal: oldGoal, start: day, minutes: 30)
        let a2 = makeSession(topic: topicA, goal: newGoal, start: day.addingTimeInterval(3600), minutes: 30)

        let b1 = makeSession(topic: topicB, goal: oldGoal, start: day.addingTimeInterval(7200), minutes: 10)

        let status = try #require(DailyStatus.compute(from: [a1, a2, b1]))

        #expect(status.topics.count == status.durationsInMinutes.count)
        #expect(status.topics.count == status.goals.count)
        #expect(status.topics.count == status.isMet.count)

        let idxA = status.topics.firstIndex(where: { $0.id == topicA.id })!
        let idxB = status.topics.firstIndex(where: { $0.id == topicB.id })!

        #expect(status.durationsInMinutes[idxA] == 60)
        #expect(status.goals[idxA].createdAt == newGoal.createdAt)
        #expect(status.isMet[idxA] == true)

        #expect(status.durationsInMinutes[idxB] == 10)
        #expect(status.isMet[idxB] == false)
    }
}
