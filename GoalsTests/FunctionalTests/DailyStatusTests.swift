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

    @Test("DailyStatus groups by topic, sums durations, uses topic goal snapshot for that day, and computes isMet from total")
    func computeBusinessRules() throws {

        let topicA = Topic(name: "Topic A")
        let topicB = Topic(name: "Topic B")

        let day = TestDates.date(2025, 10, 12, 9, 0)

        // Goal snapshots (source of truth)
        let changeA = TopicGoalChange(
            topic: topicA,
            goalInMinutes: 60,
            effectiveFromDay: TestDates.date(2025, 10, 11, 12, 0)
        )
        let changeB = TopicGoalChange(
            topic: topicB,
            goalInMinutes: 30,
            effectiveFromDay: TestDates.date(2025, 10, 1, 12, 0)
        )

        // Ensure they are attached even without a ModelContext (avoid relying on inverse inference).
        topicA.goalChanges.append(changeA)
        topicB.goalChanges.append(changeB)

        let a1 = makeSession(topic: topicA, start: day, minutes: 30)
        let a2 = makeSession(topic: topicA, start: day.addingTimeInterval(3600), minutes: 30)

        let b1 = makeSession(topic: topicB, start: day.addingTimeInterval(7200), minutes: 10)

        let status = try #require(DailyStatus.compute(from: [a1, a2, b1]))

        #expect(status.topics.count == status.durationsInMinutes.count)
        #expect(status.topics.count == status.goalInMinutes.count)
        #expect(status.topics.count == status.isMet.count)

        let idxA = status.topics.firstIndex(where: { $0.id == topicA.id })!
        let idxB = status.topics.firstIndex(where: { $0.id == topicB.id })!

        // Topic A: 60 minutes studied, snapshot goal is 60 => met
        #expect(status.durationsInMinutes[idxA] == 60)
        #expect(status.goalInMinutes[idxA] == 60)
        #expect(status.isMet[idxA] == true)

        // Topic B: 10 minutes studied, snapshot goal is 30 => not met
        #expect(status.durationsInMinutes[idxB] == 10)
        #expect(status.goalInMinutes[idxB] == 30)
        #expect(status.isMet[idxB] == false)
    }

    @Test("DailyStatus uses the goal snapshot active on each day (goal changes over time do not recalculate the past)")
    func computeUsesSnapshotByDay() throws {

        let topic = Topic(name: "iOS")

        // Goal history (snapshots)
        let g1 = TopicGoalChange(topic: topic, goalInMinutes: 120, effectiveFromDay: TestDates.date(2025, 12, 20, 12, 0)) // 2h
        let g2 = TopicGoalChange(topic: topic, goalInMinutes: 240, effectiveFromDay: TestDates.date(2025, 12, 22, 12, 0)) // 4h
        let g3 = TopicGoalChange(topic: topic, goalInMinutes: 180, effectiveFromDay: TestDates.date(2025, 12, 23, 12, 0)) // 3h

        // Ensure they are attached even without a ModelContext (avoid relying on inverse inference).
        topic.goalChanges.append(g1)
        topic.goalChanges.append(g2)
        topic.goalChanges.append(g3)

        // 20 Dec 2025: goal 2h, studied 3h => met YES
        do {
            let day20 = TestDates.date(2025, 12, 20, 9, 0)
            let s = makeSession(topic: topic, start: day20, minutes: 180)
            let status = try #require(DailyStatus.compute(from: [s]))

            let idx = status.topics.firstIndex(where: { $0.id == topic.id })!
            #expect(status.durationsInMinutes[idx] == 180)
            #expect(status.goalInMinutes[idx] == 120)
            #expect(status.isMet[idx] == true)
        }

        // 22 Dec 2025: goal 4h, studied 3h => met NO
        do {
            let day22 = TestDates.date(2025, 12, 22, 9, 0)
            let s = makeSession(topic: topic, start: day22, minutes: 180)
            let status = try #require(DailyStatus.compute(from: [s]))

            let idx = status.topics.firstIndex(where: { $0.id == topic.id })!
            #expect(status.durationsInMinutes[idx] == 180)
            #expect(status.goalInMinutes[idx] == 240)
            #expect(status.isMet[idx] == false)
        }

        // 23 Dec 2025: goal 3h, studied 3h => met YES
        do {
            let day23 = TestDates.date(2025, 12, 23, 9, 0)
            let s = makeSession(topic: topic, start: day23, minutes: 180)
            let status = try #require(DailyStatus.compute(from: [s]))

            let idx = status.topics.firstIndex(where: { $0.id == topic.id })!
            #expect(status.durationsInMinutes[idx] == 180)
            #expect(status.goalInMinutes[idx] == 180)
            #expect(status.isMet[idx] == true)
        }
    }
}
