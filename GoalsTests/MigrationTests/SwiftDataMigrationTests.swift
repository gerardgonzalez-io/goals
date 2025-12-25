import Foundation
import SwiftData
import Testing
@testable import Goals

struct SwiftDataMigrationTests
{
    @Test("SwiftData V1 -> V2 migration produces goal snapshots per topic and preserves sessions")
    @MainActor
    func v1ToV2Migration() throws
    {
        // IMPORTANT:
        // On your SwiftData version, ModelConfiguration does NOT take a URL.
        // Instead, we use a unique configuration NAME (store identifier) per test,
        // and reuse the SAME name for V1 and V2 so they point to the same on-disk store.
        let storeName = Self.makeUniqueStoreName()

        // -----------------------------
        // Arrange: Create + seed V1 store on disk
        // -----------------------------
        let expected = try Self.seedV1Store(storeName: storeName)

        // -----------------------------
        // Act: Open same store as V2 + migration plan (this triggers migration)
        // -----------------------------
        let schemaV2 = Schema(versionedSchema: GoalsSchemaV2.self)
        let configV2 = ModelConfiguration(storeName, schema: schemaV2, isStoredInMemoryOnly: false)

        let containerV2 = try ModelContainer(
            for: schemaV2,
            migrationPlan: GoalsMigrationPlan.self,
            configurations: [configV2]
        )
        let contextV2 = containerV2.mainContext

        // -----------------------------
        // Assert: Validate V2 state
        // -----------------------------
        let topicsV2 = try contextV2.fetch(FetchDescriptor<GoalsSchemaV2.Topic>())
        let sessionsV2 = try contextV2.fetch(FetchDescriptor<GoalsSchemaV2.StudySession>())
        let changesV2 = try contextV2.fetch(FetchDescriptor<GoalsSchemaV2.TopicGoalChange>())

        #expect(topicsV2.count == expected.topicCount)
        #expect(sessionsV2.count == expected.sessionCount)

        // Every topic should have at least 1 snapshot after migration.
        for topic in topicsV2
        {
            #expect(topic.goalChanges.isEmpty == false)
        }

        // Build lookup by name (explicit type to help inference)
        let topicByName: [String: GoalsSchemaV2.Topic] =
            Dictionary(uniqueKeysWithValues: topicsV2.map { ($0.name, $0) })

        // Topic A ("iOS") used 60 then 30 in V1 sessions -> should become 2 snapshots (60, 30)
        let ios = try #require(topicByName["iOS"])
        let iosMinutes = ios.goalChanges.map { $0.goalInMinutes }.sorted()
        #expect(iosMinutes == [30, 60])

        // Validar que el último snapshot de iOS tenga el mayor effectiveAt
        let iosSortedByTime = ios.goalChanges.sorted { $0.effectiveAt < $1.effectiveAt }
        let lastChange = try #require(iosSortedByTime.last)
        #expect(ios.goalChanges.contains(where: { $0.id == lastChange.id }))

        // Topic B ("Japanese") used only 60 -> should become 1 snapshot (60)
        let japanese = try #require(topicByName["Japanese"])
        let japaneseMinutes = japanese.goalChanges.map { $0.goalInMinutes }.sorted()
        #expect(japaneseMinutes == [60])

        // Total snapshots count should match what we expect from the seeded V1 data.
        #expect(changesV2.count == expected.expectedSnapshotsTotal)
    }

    @Test("SwiftData migration seeds default snapshot for topic without sessions")
    @MainActor
    func v1ToV2Migration_topicWithoutSessionsGetsDefaultSnapshot() throws {
        let storeName = Self.makeUniqueStoreName()

        // Seed V1 con un único topic sin sesiones
        let schemaV1 = Schema(versionedSchema: GoalsSchemaV1.self)
        let configV1 = ModelConfiguration(storeName, schema: schemaV1, isStoredInMemoryOnly: false)
        let containerV1 = try ModelContainer(for: schemaV1, configurations: [configV1])
        let contextV1 = containerV1.mainContext

        let lonelyTopic = GoalsSchemaV1.Topic(name: "Alone")
        contextV1.insert(lonelyTopic)
        try contextV1.save()

        // Abrir como V2 con migration plan para disparar migración
        let schemaV2 = Schema(versionedSchema: GoalsSchemaV2.self)
        let configV2 = ModelConfiguration(storeName, schema: schemaV2, isStoredInMemoryOnly: false)
        let containerV2 = try ModelContainer(
            for: schemaV2,
            migrationPlan: GoalsMigrationPlan.self,
            configurations: [configV2]
        )
        let contextV2 = containerV2.mainContext

        // Fetch V2
        let topicsV2 = try contextV2.fetch(FetchDescriptor<GoalsSchemaV2.Topic>())
        let changesV2 = try contextV2.fetch(FetchDescriptor<GoalsSchemaV2.TopicGoalChange>())

        // Aserciones
        #expect(topicsV2.count == 1)
        let migratedTopic = try #require(topicsV2.first)
        #expect(migratedTopic.name == "Alone")
        #expect(migratedTopic.goalChanges.isEmpty == false)
        #expect(changesV2.count == 1)

        // Debe ser el valor por defecto de la migración (60)
        let minutes = try #require(migratedTopic.goalChanges.first?.goalInMinutes)
        #expect(minutes == 60)
    }
}

// MARK: - V1 seeding

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

        // Topics
        let topicA = GoalsSchemaV1.Topic(name: "iOS")
        let topicB = GoalsSchemaV1.Topic(name: "Japanese")

        // Goals (V1 normalizes createdAt to startOfDay in init)
        let g60 = GoalsSchemaV1.Goal(goalInMinutes: 60, createdAt: makeDate(2025, 12, 20, 12, 0))
        let g30 = GoalsSchemaV1.Goal(goalInMinutes: 30, createdAt: makeDate(2025, 12, 22, 12, 0))

        // Sessions
        let s1 = GoalsSchemaV1.StudySession(
            topic: topicA,
            goal: g60,
            startDate: makeDate(2025, 12, 20, 9, 0),
            endDate: makeDate(2025, 12, 20, 10, 0)
        )

        let s2 = GoalsSchemaV1.StudySession(
            topic: topicA,
            goal: g30, // later goal used by this topic too
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

        // Sanity check V1 seed
        let fetchedTopics = try contextV1.fetch(FetchDescriptor<GoalsSchemaV1.Topic>())
        let fetchedSessions = try contextV1.fetch(FetchDescriptor<GoalsSchemaV1.StudySession>())
        let fetchedGoals = try contextV1.fetch(FetchDescriptor<GoalsSchemaV1.Goal>())

        #expect(fetchedTopics.count == 2)
        #expect(fetchedSessions.count == 3)
        #expect(fetchedGoals.count == 2)

        // Expected snapshots based on migration strategy:
        // Topic A: goals referenced by its sessions => {60, 30} => 2 snapshots
        // Topic B: goals referenced by its sessions => {60} => 1 snapshot
        return SeedExpectations(topicCount: 2, sessionCount: 3, expectedSnapshotsTotal: 3)
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
