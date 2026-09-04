//
//  GoalsSchemaV1.swift
//  Goals
//
//  V1 schema = modelos viejos (Topic + StudySession + Goal)
//

import Foundation
import SwiftData

enum GoalsSchemaV1: VersionedSchema
{

    static var versionIdentifier: Schema.Version = .init(1, 0, 0)

    static var models: [any PersistentModel.Type]
    {
        [Topic.self, StudySession.self, Goal.self]
    }

    // MARK: - Models (V1)

    @Model
    final class Topic: Identifiable
    {
        var id: UUID
        var name: String

        @Relationship(deleteRule: .cascade, inverse: \StudySession.topic)
        var studySessions: [StudySession] = []

        init(name: String, studySessions: [StudySession] = [])
        {
            self.id = UUID()
            self.name = name
            self.studySessions = studySessions
        }
    }

    @Model
    final class Goal
    {
        var createdAt: Date
        var goalInMinutes: Int

        var goalInSeconds: Int { goalInMinutes * 60 }
        var goalInHours: Int { goalInMinutes / 60 }

        init(goalInMinutes: Int, createdAt: Date = Date())
        {
            self.goalInMinutes = goalInMinutes

            var cal = Calendar.current
            cal.timeZone = .current
            self.createdAt = cal.startOfDay(for: createdAt)
        }
    }

    @Model
    final class StudySession
    {
        var topic: Topic
        var goal: Goal
        var startDate: Date
        var endDate: Date

        /// Normalized start of day for this session's startDate using the current calendar and time zone.
        var normalizedDay: Date
        {
            var cal = Calendar.current
            cal.timeZone = .current
            return cal.startOfDay(for: startDate)
        }

        var durationInMinutes: Int
        {
            let seconds = endDate.timeIntervalSince(startDate)
            if seconds <= 0 { return 0 }
            return Int(seconds / 60)
        }

        init(topic: Topic, goal: Goal, startDate: Date, endDate: Date)
        {
            self.topic = topic
            self.goal = goal
            self.startDate = startDate
            self.endDate = endDate
        }
    }
}
