import Foundation
import SwiftData
import Testing
@testable import Goals

struct SwiftDataMigrationTests
{
    @Test("SwiftData V1 -> V3 migration preserves topics, sessions, and goal snapshots")
    @MainActor
    func v1ToV3Migration() throws
    {
        let storeName = Self.makeUniqueStoreName()
        let expected = try Self.seedV1Store(storeName: storeName)

        let schemaV3 = Schema(versionedSchema: GoalsSchemaV3.self)
        let configV3 = ModelConfiguration(storeName, schema: schemaV3, isStoredInMemoryOnly: false)

        let containerV3 = try ModelContainer(
            for: schemaV3,
            migrationPlan: GoalsMigrationPlan.self,
            configurations: [configV3]
        )
        let contextV3 = containerV3.mainContext

        let topicsV3 = try contextV3.fetch(FetchDescriptor<GoalsSchemaV3.Topic>())
        let sessionsV3 = try contextV3.fetch(FetchDescriptor<GoalsSchemaV3.StudySession>())
        let goalsV3 = try contextV3.fetch(FetchDescriptor<GoalsSchemaV3.Goal>())
        let intervalsV3 = try contextV3.fetch(FetchDescriptor<GoalsSchemaV3.SessionInterval>())

        #expect(topicsV3.count == expected.topicCount)
        #expect(sessionsV3.count == expected.sessionCount)
        #expect(goalsV3.count == expected.expectedSnapshotsTotal)
        #expect(intervalsV3.count == expected.sessionCount)

        let topicByName: [String: GoalsSchemaV3.Topic] =
            Dictionary(uniqueKeysWithValues: topicsV3.map { ($0.name, $0) })

        let ios = try #require(topicByName["iOS"])
        let japanese = try #require(topicByName["Japanese"])

        let iosGoalSeconds = goalsV3
            .filter { $0.topicID == ios.id }
            .map { Int($0.targetSecondsPerDay) }
            .sorted()
        #expect(iosGoalSeconds == [1_800, 3_600])

        let japaneseGoalSeconds = goalsV3
            .filter { $0.topicID == japanese.id }
            .map { Int($0.targetSecondsPerDay) }
            .sorted()
        #expect(japaneseGoalSeconds == [3_600])

        #expect(sessionsV3.allSatisfy { session in
            session.endDate != nil &&
            (session.topicID == ios.id || session.topicID == japanese.id)
        })
        #expect(sessionsV3.allSatisfy { $0.sessionIntervals.count == 1 })
    }

    @Test("SwiftData V2 -> V3 migration preserves existing V2 data")
    @MainActor
    func v2ToV3Migration() throws
    {
        let storeName = Self.makeUniqueStoreName()
        let expected = try Self.seedV2Store(storeName: storeName)

        let schemaV3 = Schema(versionedSchema: GoalsSchemaV3.self)
        let configV3 = ModelConfiguration(storeName, schema: schemaV3, isStoredInMemoryOnly: false)

        let containerV3 = try ModelContainer(
            for: schemaV3,
            migrationPlan: GoalsMigrationPlan.self,
            configurations: [configV3]
        )
        let contextV3 = containerV3.mainContext

        let topicsV3 = try contextV3.fetch(FetchDescriptor<GoalsSchemaV3.Topic>())
        let sessionsV3 = try contextV3.fetch(FetchDescriptor<GoalsSchemaV3.StudySession>())
        let goalsV3 = try contextV3.fetch(FetchDescriptor<GoalsSchemaV3.Goal>())
        let intervalsV3 = try contextV3.fetch(FetchDescriptor<GoalsSchemaV3.SessionInterval>())

        #expect(topicsV3.count == expected.topicCount)
        #expect(sessionsV3.count == expected.sessionCount)
        #expect(goalsV3.count == expected.expectedSnapshotsTotal)
        #expect(intervalsV3.count == expected.sessionCount)

        let topicIDs = Set(topicsV3.map(\.id))
        #expect(sessionsV3.allSatisfy { topicIDs.contains($0.topicID) })
        #expect(goalsV3.allSatisfy { topicIDs.contains($0.topicID) })
        #expect(goalsV3.map { Int($0.targetSecondsPerDay) }.sorted() == [2_700, 3_600, 5_400])
    }

    @Test("SwiftData V1 -> V3 migration keeps the default goal for a topic without sessions")
    @MainActor
    func v1ToV3MigrationTopicWithoutSessionsGetsDefaultGoal() throws
    {
        let storeName = Self.makeUniqueStoreName()

        let schemaV1 = Schema(versionedSchema: GoalsSchemaV1.self)
        let configV1 = ModelConfiguration(storeName, schema: schemaV1, isStoredInMemoryOnly: false)
        let containerV1 = try ModelContainer(for: schemaV1, configurations: [configV1])
        let contextV1 = containerV1.mainContext

        let lonelyTopic = GoalsSchemaV1.Topic(name: "Alone")
        contextV1.insert(lonelyTopic)
        try contextV1.save()

        let schemaV3 = Schema(versionedSchema: GoalsSchemaV3.self)
        let configV3 = ModelConfiguration(storeName, schema: schemaV3, isStoredInMemoryOnly: false)
        let containerV3 = try ModelContainer(
            for: schemaV3,
            migrationPlan: GoalsMigrationPlan.self,
            configurations: [configV3]
        )
        let contextV3 = containerV3.mainContext

        let topicsV3 = try contextV3.fetch(FetchDescriptor<GoalsSchemaV3.Topic>())
        let goalsV3 = try contextV3.fetch(FetchDescriptor<GoalsSchemaV3.Goal>())

        #expect(topicsV3.count == 1)
        let migratedTopic = try #require(topicsV3.first)
        #expect(migratedTopic.name == "Alone")

        #expect(goalsV3.count == 1)
        let goal = try #require(goalsV3.first)
        #expect(goal.topicID == migratedTopic.id)
        #expect(Int(goal.targetSecondsPerDay) == 3_600)
    }
}

// MARK: - Seeding

private extension SwiftDataMigrationTests
{
    struct SeedExpectations
    {
        let topicCount: Int
        let sessionCount: Int
        let expectedSnapshotsTotal: Int
    }

    @MainActor
    static func seedV1Store(storeName: String) throws -> SeedExpectations
    {
        let schemaV1 = Schema(versionedSchema: GoalsSchemaV1.self)
        let configV1 = ModelConfiguration(storeName, schema: schemaV1, isStoredInMemoryOnly: false)
        let containerV1 = try ModelContainer(for: schemaV1, configurations: [configV1])
        let contextV1 = containerV1.mainContext

        let topicA = GoalsSchemaV1.Topic(name: "iOS")
        let topicB = GoalsSchemaV1.Topic(name: "Japanese")

        let g60 = GoalsSchemaV1.Goal(goalInMinutes: 60, createdAt: makeDate(2025, 12, 20, 12, 0))
        let g30 = GoalsSchemaV1.Goal(goalInMinutes: 30, createdAt: makeDate(2025, 12, 22, 12, 0))

        let s1 = GoalsSchemaV1.StudySession(
            topic: topicA,
            goal: g60,
            startDate: makeDate(2025, 12, 20, 9, 0),
            endDate: makeDate(2025, 12, 20, 10, 0)
        )

        let s2 = GoalsSchemaV1.StudySession(
            topic: topicA,
            goal: g30,
            startDate: makeDate(2025, 12, 22, 9, 0),
            endDate: makeDate(2025, 12, 22, 9, 30)
        )

        let s3 = GoalsSchemaV1.StudySession(
            topic: topicB,
            goal: g60,
            startDate: makeDate(2025, 12, 21, 8, 0),
            endDate: makeDate(2025, 12, 21, 9, 0)
        )

        contextV1.insert(topicA)
        contextV1.insert(topicB)
        contextV1.insert(g60)
        contextV1.insert(g30)
        contextV1.insert(s1)
        contextV1.insert(s2)
        contextV1.insert(s3)

        try contextV1.save()

        return SeedExpectations(topicCount: 2, sessionCount: 3, expectedSnapshotsTotal: 3)
    }

    @MainActor
    static func seedV2Store(storeName: String) throws -> SeedExpectations
    {
        let schemaV2 = Schema(versionedSchema: GoalsSchemaV2.self)
        let configV2 = ModelConfiguration(storeName, schema: schemaV2, isStoredInMemoryOnly: false)
        let containerV2 = try ModelContainer(for: schemaV2, configurations: [configV2])
        let contextV2 = containerV2.mainContext

        let topicA = GoalsSchemaV2.Topic(name: "Swift")
        let topicB = GoalsSchemaV2.Topic(name: "SwiftUI")

        let g45 = GoalsSchemaV2.TopicGoalChange(
            topic: topicA,
            goalInMinutes: 45,
            effectiveAt: makeDate(2025, 12, 18, 12, 0)
        )
        let g90 = GoalsSchemaV2.TopicGoalChange(
            topic: topicA,
            goalInMinutes: 90,
            effectiveAt: makeDate(2025, 12, 20, 12, 0)
        )
        let g60 = GoalsSchemaV2.TopicGoalChange(
            topic: topicB,
            goalInMinutes: 60,
            effectiveAt: makeDate(2025, 12, 19, 12, 0)
        )

        topicA.goalChanges.append(g45)
        topicA.goalChanges.append(g90)
        topicB.goalChanges.append(g60)

        let s1 = GoalsSchemaV2.StudySession(
            topic: topicA,
            startDate: makeDate(2025, 12, 20, 9, 0),
            endDate: makeDate(2025, 12, 20, 10, 0)
        )
        let s2 = GoalsSchemaV2.StudySession(
            topic: topicB,
            startDate: makeDate(2025, 12, 21, 9, 0),
            endDate: makeDate(2025, 12, 21, 11, 0)
        )

        contextV2.insert(topicA)
        contextV2.insert(topicB)
        contextV2.insert(g45)
        contextV2.insert(g90)
        contextV2.insert(g60)
        contextV2.insert(s1)
        contextV2.insert(s2)

        try contextV2.save()

        return SeedExpectations(topicCount: 2, sessionCount: 2, expectedSnapshotsTotal: 3)
    }
}

// MARK: - Helpers

private extension SwiftDataMigrationTests
{
    static func makeUniqueStoreName() -> String
    {
        "GoalsMigrationStore-\(UUID().uuidString)"
    }

    static func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date
    {
        var comps = DateComponents()
        comps.calendar = Calendar.current
        comps.timeZone = .current
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        return comps.date!
    }
}
