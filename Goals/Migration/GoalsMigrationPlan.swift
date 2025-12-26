//
//  GoalsMigrationPlan.swift
//  Goals
//
//  Custom SwiftData migration: V1 -> V2
//  - V1 had Goal + StudySession.goal
//  - V2 removes Goal and adds TopicGoalChange snapshots (goals per topic)
//

import Foundation
import SwiftData

enum GoalsMigrationPlan: SchemaMigrationPlan
{
    static var schemas: [any VersionedSchema.Type]
    {
        [GoalsSchemaV1.self, GoalsSchemaV2.self]
    }

    static var stages: [MigrationStage]
    {
        [migrateV1toV2]
    }

    // MARK: - In-memory bridge (willMigrate -> didMigrate)

    private struct GoalSeed: Hashable
    {
        let effectiveAt: Date
        let goalInMinutes: Int
    }

    /// We store extracted V1 goal info here during `willMigrate`,
    /// because in `didMigrate` we can only access V2 models.
    private static var goalSeedsByTopicID: [UUID: [GoalSeed]] = [:]

    // MARK: - Stage

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: GoalsSchemaV1.self,
        toVersion: GoalsSchemaV2.self,
        willMigrate: { context in
            // 1) Read ONLY V1 models here
            let topics = try context.fetch(FetchDescriptor<GoalsSchemaV1.Topic>())

            var result: [UUID: [GoalSeed]] = [:]

            // Default goal for topics that existed but never had sessions in V1
            let defaultMinutes = 60

            // Normalize "now" to startOfDay in the current time zone (consistency with day-based logic)
            var cal = Calendar.current
            cal.timeZone = .current
            let nowStart = cal.startOfDay(for: Date())

            for topic in topics
            {
                let topicID = topic.id

                // Collect all goals referenced by this topic's sessions
                var seeds: Set<GoalSeed> = []

                for session in topic.studySessions
                {
                    let g = session.goal
                    seeds.insert(
                        GoalSeed(
                            effectiveAt: g.createdAt,          // V1 already normalized to startOfDay
                            goalInMinutes: g.goalInMinutes
                        )
                    )
                }

                // If a topic had no sessions, seed an initial snapshot so the topic has a goal in V2
                if seeds.isEmpty
                {
                    seeds.insert(
                        GoalSeed(
                            effectiveAt: nowStart,
                            goalInMinutes: defaultMinutes
                        )
                    )
                }

                // Sort by time (older -> newer)
                let sorted = seeds.sorted { $0.effectiveAt < $1.effectiveAt }
                result[topicID] = sorted
            }

            goalSeedsByTopicID = result
        },
        didMigrate: { context in
            // 2) Read/Write ONLY V2 models here
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

                    // Ensure relationship is set
                    topic.goalChanges.append(change)
                    context.insert(change)
                }
            }

            try context.save()

            // Clean up bridge memory
            goalSeedsByTopicID = [:]
        }
    )
}
