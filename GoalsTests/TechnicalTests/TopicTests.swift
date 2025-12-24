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
        let goal = Goal(goalInMinutes: 10, createdAt: TestDates.date(2025, 10, 12, 9, 0))

        let s1 = makeSession(topic: topic, goal: goal, start: TestDates.date(2025, 10, 12, 10, 0), minutes: 5)
        let s2 = makeSession(topic: topic, goal: goal, start: TestDates.date(2025, 10, 12, 11, 0), minutes: 7)

        let t = Topic(name: "iOS", studySessions: [s1, s2])
        #expect(t.studySessions.count == 2)
        #expect(t.studySessions[0].durationInMinutes == 5)
        #expect(t.studySessions[1].durationInMinutes == 7)
    }

    @Test("Deleting a Topic cascades and deletes its StudySessions (SwiftData)")
    @MainActor
    func topicCascadeDeleteRule() async throws
    {
        let schema = Schema([Topic.self, StudySession.self, Goal.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "CascadeTopic")
        let goal = Goal(goalInMinutes: 1, createdAt: TestDates.date(2025, 10, 12, 9, 0))
        let start = TestDates.date(2025, 10, 12, 10, 0)
        let session = makeSession(topic: topic, goal: goal, start: start, minutes: 1)

        context.insert(topic)
        context.insert(goal)
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
