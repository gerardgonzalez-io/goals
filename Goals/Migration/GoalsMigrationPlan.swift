//
//  GoalsMigrationPlan.swift
//  Goals
//
//  Custom SwiftData migrations:
//  - V1 -> V2: Goal + StudySession.goal become TopicGoalChange snapshots
//  - V2 -> V3: TopicGoalChange becomes Goal and StudySession stores topicID + intervals
//

import Foundation
import SwiftData

enum GoalsMigrationPlan: SchemaMigrationPlan
{
    static var schemas: [any VersionedSchema.Type]
    {
        [GoalsSchemaV1.self, GoalsSchemaV2.self, GoalsSchemaV3.self]
    }

    static var stages: [MigrationStage]
    {
        [migrateV1toV2, migrateV2toV3]
    }

    // MARK: - V1 -> V2 bridge

    private struct GoalSeed: Hashable
    {
        let effectiveAt: Date
        let goalInMinutes: Int
    }

    private static var goalSeedsByTopicID: [UUID: [GoalSeed]] = [:]

    // MARK: - V2 -> V3 bridge

    fileprivate struct V3TopicSeed
    {
        let id: UUID
        let name: String
        let createdAt: Date
    }

    fileprivate struct V3GoalSeed
    {
        let id: UUID
        let topicID: UUID
        let targetSecondsPerDay: TimeInterval
        let createdAt: Date
        let effectiveFromDay: Date
    }

    fileprivate struct V3SessionSeed
    {
        let id: UUID
        let topicID: UUID
        let startDate: Date
        let endDate: Date?
    }

    private static var v3TopicSeedsByID: [UUID: V3TopicSeed] = [:]
    private static var v3GoalSeeds: [V3GoalSeed] = []
    private static var v3SessionSeeds: [V3SessionSeed] = []

    // MARK: - V1 -> V2

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: GoalsSchemaV1.self,
        toVersion: GoalsSchemaV2.self,
        willMigrate:
        { context in
            let topics = try context.fetch(FetchDescriptor<GoalsSchemaV1.Topic>())

            var result: [UUID: [GoalSeed]] = [:]
            let defaultMinutes = 60

            var calendar = Calendar.current
            calendar.timeZone = .current
            let nowStart = calendar.startOfDay(for: Date())

            for topic in topics
            {
                let topicID = topic.id
                var seeds: Set<GoalSeed> = []

                for session in topic.studySessions
                {
                    let goal = session.goal
                    seeds.insert(
                        GoalSeed(
                            effectiveAt: goal.createdAt,
                            goalInMinutes: goal.goalInMinutes
                        )
                    )
                }

                if seeds.isEmpty
                {
                    seeds.insert(
                        GoalSeed(
                            effectiveAt: nowStart,
                            goalInMinutes: defaultMinutes
                        )
                    )
                }

                result[topicID] = seeds.sorted { $0.effectiveAt < $1.effectiveAt }
            }

            goalSeedsByTopicID = result
        },
        didMigrate:
        { context in
            let topics = try context.fetch(FetchDescriptor<GoalsSchemaV2.Topic>())

            for topic in topics
            {
                guard let seeds = goalSeedsByTopicID[topic.id] else { continue }

                for seed in seeds
                {
                    let change = GoalsSchemaV2.TopicGoalChange(
                        topic: topic,
                        goalInMinutes: seed.goalInMinutes,
                        effectiveAt: seed.effectiveAt
                    )
                    topic.goalChanges.append(change)
                    context.insert(change)
                }
            }

            try context.save()
            goalSeedsByTopicID = [:]
        }
    )

    // MARK: - V2 -> V3

    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: GoalsSchemaV2.self,
        toVersion: GoalsSchemaV3.self,
        willMigrate:
        { context in
            let topics = try context.fetch(FetchDescriptor<GoalsSchemaV2.Topic>())
            let sessions = try context.fetch(FetchDescriptor<GoalsSchemaV2.StudySession>())
            let goalChanges = try context.fetch(FetchDescriptor<GoalsSchemaV2.TopicGoalChange>())

            var calendar = Calendar.current
            calendar.timeZone = .current
            let migrationDate = Date()

            v3GoalSeeds = goalChanges
                .map
                { change in
                    V3GoalSeed(
                        id: change.id,
                        topicID: change.topic.id,
                        targetSecondsPerDay: TimeInterval(change.goalInMinutes * 60),
                        createdAt: change.effectiveAt,
                        effectiveFromDay: change.effectiveFromDay
                    )
                }
                .sorted
                {
                    if $0.topicID != $1.topicID { return $0.topicID.uuidString < $1.topicID.uuidString }
                    if $0.effectiveFromDay != $1.effectiveFromDay { return $0.effectiveFromDay < $1.effectiveFromDay }
                    return $0.createdAt < $1.createdAt
                }

            v3SessionSeeds = sessions
                .map
                { session in
                    V3SessionSeed(
                        id: UUID(),
                        topicID: session.topic.id,
                        startDate: session.startDate,
                        endDate: session.endDate
                    )
                }
                .sorted(by: compareSessionSeeds)

            var earliestSessionStartByTopicID: [UUID: Date] = [:]
            for seed in v3SessionSeeds
            {
                let current = earliestSessionStartByTopicID[seed.topicID]
                earliestSessionStartByTopicID[seed.topicID] = min(current ?? seed.startDate, seed.startDate)
            }

            var earliestGoalDateByTopicID: [UUID: Date] = [:]
            for seed in v3GoalSeeds
            {
                let current = earliestGoalDateByTopicID[seed.topicID]
                earliestGoalDateByTopicID[seed.topicID] = min(current ?? seed.createdAt, seed.createdAt)
            }

            v3TopicSeedsByID = Dictionary(
                uniqueKeysWithValues: topics.map
                { topic in
                    let createdAt = [
                        earliestSessionStartByTopicID[topic.id],
                        earliestGoalDateByTopicID[topic.id]
                    ]
                    .compactMap { $0 }
                    .min() ?? migrationDate

                    return (
                        topic.id,
                        V3TopicSeed(
                            id: topic.id,
                            name: topic.name,
                            createdAt: calendar.startOfDay(for: createdAt)
                        )
                    )
                }
            )
        },
        didMigrate:
        { context in
            let migrationDate = Date()

            let topics = try context.fetch(FetchDescriptor<GoalsSchemaV3.Topic>())
            for topic in topics
            {
                guard let seed = v3TopicSeedsByID[topic.id] else { continue }
                topic.name = seed.name
                topic.createdAt = seed.createdAt
                topic.updatedAt = migrationDate
                topic.isArchived = false
            }

            for seed in v3GoalSeeds
            {
                let goal = GoalsSchemaV3.Goal(
                    id: seed.id,
                    topicID: seed.topicID,
                    targetSecondsPerDay: seed.targetSecondsPerDay,
                    createdAt: seed.createdAt,
                    effectiveFromDay: seed.effectiveFromDay,
                    updatedAt: migrationDate,
                    isArchived: false
                )
                context.insert(goal)
            }

            let migratedSessions = try context.fetch(FetchDescriptor<GoalsSchemaV3.StudySession>())
                .sorted(by: compareMigratedSessions)
            let orderedSeeds = v3SessionSeeds.sorted(by: compareSessionSeeds)

            for pair in zip(migratedSessions, orderedSeeds)
            {
                let session = pair.0
                let seed = pair.1

                session.id = seed.id
                session.topicID = seed.topicID
                session.startDate = seed.startDate
                session.endDate = seed.endDate
                session.createdAt = seed.startDate
                session.updatedAt = migrationDate
                session.isArchived = false

                if session.sessionIntervals.isEmpty
                {
                    let interval = GoalsSchemaV3.SessionInterval(
                        startDate: seed.startDate,
                        endDate: seed.endDate,
                        studySession: session,
                        createdAt: seed.startDate,
                        updatedAt: migrationDate,
                        isArchived: false
                    )
                    session.sessionIntervals.append(interval)
                    context.insert(interval)
                }
            }

            try context.save()

            v3TopicSeedsByID = [:]
            v3GoalSeeds = []
            v3SessionSeeds = []
        }
    )
}

private func compareSessionSeeds(
    _ lhs: GoalsMigrationPlan.V3SessionSeed,
    _ rhs: GoalsMigrationPlan.V3SessionSeed
) -> Bool
{
    if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
    if lhs.endDate != rhs.endDate { return (lhs.endDate ?? .distantPast) < (rhs.endDate ?? .distantPast) }
    return lhs.topicID.uuidString < rhs.topicID.uuidString
}

private func compareMigratedSessions(
    _ lhs: GoalsSchemaV3.StudySession,
    _ rhs: GoalsSchemaV3.StudySession
) -> Bool
{
    if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
    if lhs.endDate != rhs.endDate { return (lhs.endDate ?? .distantPast) < (rhs.endDate ?? .distantPast) }
    return lhs.id.uuidString < rhs.id.uuidString
}
