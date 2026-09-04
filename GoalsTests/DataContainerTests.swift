import Foundation
import SwiftData
import Testing
@testable import Goals

/// `DataContainerTests` coverage summary (1 test):
/// 1. `deleteUnfinishedSessionsRemovesOpenSessionsAndIntervals`:
///    Verifies startup cleanup deletes sessions and intervals with `endDate == nil`
///    while preserving completed sessions and intervals.
struct DataContainerTests
{
    @MainActor
    @Test("Delete unfinished sessions removes open sessions and intervals")
    func deleteUnfinishedSessionsRemovesOpenSessionsAndIntervals() throws
    {
        let dataContainer = DataContainer(includeSampleData: true)
        let context = dataContainer.context
        let topicID = UUID()
        let startDate = date(year: 2026, month: 7, day: 14, hour: 8, minute: 0)
        let initialSessionCount = try context.fetch(FetchDescriptor<StudySession>()).count
        let initialIntervalCount = try context.fetch(FetchDescriptor<SessionInterval>()).count

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

        context.insert(completedSession)
        context.insert(unfinishedSession)
        context.insert(orphanUnfinishedInterval)
        try context.save()

        try dataContainer.deleteUnfinishedSessions()
        try context.save()

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

        #expect(sessions.count == initialSessionCount + 1)
        #expect(sessions.contains { $0.id == completedSession.id })
        #expect(unfinishedSessions.isEmpty)

        #expect(intervals.count == initialIntervalCount + 1)
        #expect(intervals.contains { interval in
            interval.endDate != nil && interval.studySession?.id == completedSession.id
        })
        #expect(unfinishedIntervals.isEmpty)
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
