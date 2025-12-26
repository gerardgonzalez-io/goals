//
//  TopicTests.swift
//  GoalsTests
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-12-25.
//

import Foundation
import SwiftData
import Testing
@testable import Goals

struct TopicTests
{
    @Test("Topic init assigns a unique id and preserves name")
    func topicInit()
    {
        let a = Topic(name: "Swift")
        let b = Topic(name: "Swift")

        #expect(a.name == "Swift")
        #expect(b.name == "Swift")
        #expect(a.id != b.id)
    }

    @Test("Topic init accepts initial studySessions")
    func topicInitWithSessions()
    {
        let topic = Topic(name: "iOS")

        let s1 = makeSession(topic: topic, start: TestDates.date(2025, 10, 12, 10, 0), minutes: 5)
        let s2 = makeSession(topic: topic, start: TestDates.date(2025, 10, 12, 11, 0), minutes: 7)

        let t = Topic(name: "iOS", studySessions: [s1, s2])
        #expect(t.studySessions.count == 2)
        #expect(t.studySessions[0].durationInMinutes == 5)
        #expect(t.studySessions[1].durationInMinutes == 7)
    }

    @Test("Topic.goalInMinutes(for:) returns nil when there are no snapshots")
    func topicGoalNilWhenNoSnapshots()
    {
        let topic = Topic(name: "iOS")
        let day = TestDates.date(2025, 12, 20, 9, 0)
        #expect(topic.goalInMinutes(for: day) == nil)
    }

    @Test("Topic.goalInMinutes(for:) returns the last snapshot whose effectiveAtDay <= target day")
    func topicGoalResolvesByEffectiveDay()
    {
        let topic = Topic(name: "iOS")

        let g1 = TopicGoalChange(
            topic: topic,
            goalInMinutes: 120,
            effectiveAt: TestDates.date(2025, 12, 20, 12, 0) // 2h
        )
        let g2 = TopicGoalChange(
            topic: topic,
            goalInMinutes: 240,
            effectiveAt: TestDates.date(2025, 12, 22, 12, 0) // 4h
        )
        let g3 = TopicGoalChange(
            topic: topic,
            goalInMinutes: 180,
            effectiveAt: TestDates.date(2025, 12, 23, 12, 0) // 3h
        )

        // Ensure they are attached even without a ModelContext.
        topic.goalChanges.append(g1)
        topic.goalChanges.append(g2)
        topic.goalChanges.append(g3)

        // 2025-12-20 -> 2h
        #expect(topic.goalInMinutes(for: TestDates.date(2025, 12, 20, 9, 0)) == 120)

        // 2025-12-21 -> still 2h
        #expect(topic.goalInMinutes(for: TestDates.date(2025, 12, 21, 9, 0)) == 120)

        // 2025-12-22 -> 4h
        #expect(topic.goalInMinutes(for: TestDates.date(2025, 12, 22, 9, 0)) == 240)

        // 2025-12-23 -> 3h
        #expect(topic.goalInMinutes(for: TestDates.date(2025, 12, 23, 9, 0)) == 180)
    }

    @Test("Topic.currentGoalInMinutes returns the goal active today (or nil if none)")
    func topicCurrentGoalConvenience()
    {
        let topic = Topic(name: "SwiftUI")

        // With no snapshots, should be nil
        #expect(topic.currentGoalInMinutes == nil)

        // Add one snapshot effective today
        let today = Date()
        let change = TopicGoalChange(topic: topic, goalInMinutes: 60, effectiveAt: today)

        // Ensure attached even without a ModelContext
        topic.goalChanges.append(change)

        #expect(topic.currentGoalInMinutes == 60)
    }

    @Test("Deleting a Topic cascades and deletes its StudySessions (SwiftData)")
    @MainActor
    func topicCascadeDeleteRule() async throws
    {
        let schema = Schema([Topic.self, StudySession.self, TopicGoalChange.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "CascadeTopic")
        let start = TestDates.date(2025, 10, 12, 10, 0)
        let session = makeSession(topic: topic, start: start, minutes: 1)

        context.insert(topic)
        context.insert(session)
        try context.save()

        let before = try context.fetch(FetchDescriptor<StudySession>())
        #expect(before.count == 1)

        context.delete(topic)
        try context.save()

        let after = try context.fetch(FetchDescriptor<StudySession>())
        #expect(after.isEmpty)
    }
}
