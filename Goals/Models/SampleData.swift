//
//  SampleData.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-10-25.
//

import Foundation
import SwiftData

@MainActor
final class SampleData {
    static let shared = SampleData()

    let modelContainer: ModelContainer

    private(set) var topics: [Topic] = []

    var context: ModelContext { modelContainer.mainContext }

    /// A stable topic that actually exists in this container (used by previews).
    var topic: Topic { topics.first! }

    private init() {
        // In-memory container used for previews and tests
        let schema = Schema([
            Topic.self,
            StudySession.self,
            TopicGoalChange.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            insertSampleData()
            try context.save()
        } catch {
            fatalError("Could not create model container: \(error)")
        }
    }

    private func insertSampleData() {
        // Create and insert Topics (keep references so previews use the same instances)
        let createdTopics: [Topic] = [
            Topic(name: "iOS"),
            Topic(name: "SwiftUI"),
            Topic(name: "Japanese")
        ]

        for t in createdTopics {
            context.insert(t)
        }
        self.topics = createdTopics

        // Calendar helper
        var cal = Calendar.current
        cal.timeZone = .current
        let now = Date()
        let today = cal.startOfDay(for: now)

        func day(_ offset: Int) -> Date {
            cal.startOfDay(for: cal.date(byAdding: .day, value: offset, to: today)!)
        }

        // Insert goal history (TopicGoalChange) so Plan is available
        // iOS: 60m/day since 30d ago, then 90m/day since 10d ago
        addGoalChange(to: topics[0], minutes: 60, effectiveAt: day(-120).addingTimeInterval(12 * 3600))
        addGoalChange(to: topics[0], minutes: 90, effectiveAt: day(-10).addingTimeInterval(12 * 3600))
        addGoalChange(to: topics[0], minutes: 30, effectiveAt: day(-4).addingTimeInterval(12 * 3600))

        // SwiftUI: 45m/day since 20d ago
        addGoalChange(to: topics[1], minutes: 45, effectiveAt: day(-20).addingTimeInterval(12 * 3600))

        // Japanese: 30m/day since 40d ago
        addGoalChange(to: topics[2], minutes: 30, effectiveAt: day(-40).addingTimeInterval(12 * 3600))

        // Insert sessions spread across days so chart shows movement (no midnight splitting needed)

        addSession(topic: topics[0], start: day(-6).addingTimeInterval(9  * 3600), minutes: 10)
        addSession(topic: topics[0], start: day(-5).addingTimeInterval(9  * 3600), minutes: 20)
        addSession(topic: topics[0], start: day(-4).addingTimeInterval(9  * 3600), minutes: 40)
        addSession(topic: topics[0], start: day(-3).addingTimeInterval(9  * 3600), minutes: 150)
        addSession(topic: topics[0], start: day(-2).addingTimeInterval(9  * 3600), minutes: 40)
        addSession(topic: topics[0], start: day(-1).addingTimeInterval(20 * 3600), minutes: 40)
        addSession(topic: topics[0], start: day(0).addingTimeInterval(8  * 3600), minutes: 40)

        // A few extra sessions on other topics (optional, for other screens)
        addSession(topic: topics[1], start: day(-2).addingTimeInterval(10 * 3600), minutes: 50)
        addSession(topic: topics[2], start: day(-4).addingTimeInterval(18 * 3600), minutes: 35)
    }

    // MARK: - Insert helpers

    private func addGoalChange(to topic: Topic, minutes: Int, effectiveAt: Date) {
        let g = TopicGoalChange(topic: topic, goalInMinutes: minutes, effectiveAt: effectiveAt)
        topic.goalChanges.append(g)   // keep relationship consistent without relying on inverse inference
        context.insert(g)
    }

    private func addSession(topic: Topic, start: Date, minutes: Int, extraSeconds: Int = 0) {
        let end = start.addingTimeInterval(TimeInterval(minutes * 60 + extraSeconds))
        let s = StudySession(topic: topic, startDate: start, endDate: end)
        context.insert(s)
    }
}
