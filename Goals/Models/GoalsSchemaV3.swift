//
//  GoalsSchemaV3.swift
//  Goals
//
//  V3 schema = Topic + Goal + StudySession + SessionInterval
//  - TopicGoalChange is replaced by Goal snapshots keyed by topicID
//  - StudySession stores topicID instead of a Topic relationship
//  - SessionInterval stores the focused intervals that compose a study session
//

import Foundation
import SwiftData

enum GoalsSchemaV3: VersionedSchema
{
    static var versionIdentifier: Schema.Version = .init(3, 0, 0)

    static var models: [any PersistentModel.Type]
    {
        [Topic.self, Goal.self, StudySession.self, SessionInterval.self]
    }

    @Model
    final class Goal
    {
        var id: UUID = UUID()
        var topicID: UUID = UUID()
        var targetSecondsPerDay: TimeInterval = 0
        var createdAt: Date = Date.now
        var effectiveFromDay: Date = Date.now
        var updatedAt: Date = Date.now
        var isArchived: Bool = false

        init(
            id: UUID = UUID(),
            topicID: UUID,
            targetSecondsPerDay: TimeInterval,
            createdAt: Date = Date.now,
            effectiveFromDay: Date? = nil,
            updatedAt: Date = Date.now,
            isArchived: Bool = false
        )
        {
            self.id = id
            self.topicID = topicID
            self.targetSecondsPerDay = targetSecondsPerDay
            self.createdAt = createdAt
            self.effectiveFromDay = effectiveFromDay ?? Calendar.current.startOfDay(for: createdAt)
            self.updatedAt = updatedAt
            self.isArchived = isArchived
        }
    }

    @Model
    final class SessionInterval
    {
        var id: UUID = UUID()
        var startDate: Date = Date.now
        var endDate: Date?
        var studySession: StudySession?
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var isArchived: Bool = false

        var durationSeconds: TimeInterval
        {
            guard let endDate else { return 0 }
            let duration = endDate.timeIntervalSince(startDate)
            return max(0, duration)
        }

        init(
            id: UUID = UUID(),
            startDate: Date,
            endDate: Date? = nil,
            studySession: StudySession? = nil,
            createdAt: Date = Date.now,
            updatedAt: Date = Date.now,
            isArchived: Bool = false
        )
        {
            self.id = id
            self.startDate = startDate
            self.endDate = endDate
            self.studySession = studySession
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isArchived = isArchived
        }
    }

    @Model
    final class StudySession
    {
        var id: UUID = UUID()
        var topicID: UUID = UUID()
        var startDate: Date = Date.now
        var endDate: Date?
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var isArchived: Bool = false

        @Relationship(deleteRule: .cascade, inverse: \SessionInterval.studySession)
        var sessionIntervals: [SessionInterval]

        var durationSeconds: TimeInterval
        {
            guard let endDate else { return 0 }
            let duration = endDate.timeIntervalSince(startDate)
            return max(0, duration)
        }

        init(
            id: UUID = UUID(),
            topicID: UUID,
            startDate: Date,
            endDate: Date? = nil,
            sessionIntervals: [SessionInterval] = [],
            createdAt: Date = Date.now,
            updatedAt: Date = Date.now,
            isArchived: Bool = false
        )
        {
            self.id = id
            self.topicID = topicID
            self.startDate = startDate
            self.endDate = endDate
            self.sessionIntervals = sessionIntervals
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isArchived = isArchived
        }
    }

    @Model
    final class Topic
    {
        var id: UUID = UUID()
        var name: String = ""
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var isArchived: Bool = false

        init(
            id: UUID = UUID(),
            name: String,
            createdAt: Date = Date.now,
            updatedAt: Date = Date.now,
            isArchived: Bool = false
        )
        {
            self.id = id
            self.name = name
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isArchived = isArchived
        }
    }
}
