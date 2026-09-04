import Foundation
import SwiftData
import Testing
@testable import Goals

/// `DataContainerStartupCleanupTests` coverage summary (1 test):
/// 1. `initDeletesUnfinishedSessionsAndIntervalsFromPersistentStore`:
///    Verifies `DataContainer` runs unfinished-record cleanup during initialization.
///    If the startup call to `deleteUnfinishedSessions()` is removed, this test fails.
struct DataContainerStartupCleanupTests
{
    @MainActor
    @Test("DataContainer init deletes unfinished records from persistent store")
    func initDeletesUnfinishedSessionsAndIntervalsFromPersistentStore() throws
    {
        let storeURL = temporaryStoreURL()
        defer { removeStoreFiles(at: storeURL) }

        let configuration = ModelConfiguration(
            "StartupCleanupTest",
            schema: DataContainer.schema,
            url: storeURL
        )
        let topicID = UUID()
        let startDate = date(year: 2026, month: 7, day: 14, hour: 8, minute: 0)
        let completedSessionID: UUID

        do
        {
            let seedContainer = try ModelContainer(
                for: DataContainer.schema,
                configurations: [configuration]
            )
            let seedContext = seedContainer.mainContext

            let completedSession = StudySession(
                topicID: topicID,
                startDate: startDate,
                endDate: startDate.addingTimeInterval(3_600),
                sessionIntervals: [
                    SessionInterval(
                        startDate: startDate,
                        endDate: startDate.addingTimeInterval(3_600)
                    )
                ]
            )
            completedSessionID = completedSession.id

            let unfinishedSession = StudySession(
                topicID: topicID,
                startDate: startDate.addingTimeInterval(7_200),
                sessionIntervals: [
                    SessionInterval(
                        startDate: startDate.addingTimeInterval(7_200)
                    )
                ]
            )
            let orphanUnfinishedInterval = SessionInterval(
                startDate: startDate.addingTimeInterval(14_400)
            )

            seedContext.insert(completedSession)
            seedContext.insert(unfinishedSession)
            seedContext.insert(orphanUnfinishedInterval)
            try seedContext.save()
        }

        let dataContainer = DataContainer(
            includeSampleData: false,
            modelConfiguration: configuration
        )
        let context = dataContainer.context

        let sessions = try context.fetch(FetchDescriptor<StudySession>())
        let intervals = try context.fetch(FetchDescriptor<SessionInterval>())
        let unfinishedSessions = try context.fetch(FetchDescriptor<StudySession>(
            predicate: #Predicate { session in
                session.endDate == nil
            }
        ))
        let unfinishedIntervals = try context.fetch(FetchDescriptor<SessionInterval>(
            predicate: #Predicate { interval in
                interval.endDate == nil
            }
        ))

        #expect(sessions.count == 1)
        #expect(sessions.first?.id == completedSessionID)
        #expect(unfinishedSessions.isEmpty)

        #expect(intervals.count == 1)
        #expect(intervals.first?.endDate != nil)
        #expect(unfinishedIntervals.isEmpty)
    }

    private func temporaryStoreURL() -> URL
    {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("Goals-StartupCleanup-\(UUID().uuidString)")
            .appendingPathExtension("store")
    }

    private func removeStoreFiles(at storeURL: URL)
    {
        let fileManager = FileManager.default
        let relatedURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in relatedURLs where fileManager.fileExists(atPath: url.path)
        {
            try? fileManager.removeItem(at: url)
        }
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) -> Date
    {
        Calendar(identifier: .gregorian).date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}
