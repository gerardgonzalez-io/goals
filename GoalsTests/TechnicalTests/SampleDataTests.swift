//
//  SampleDataTests.swift
//  GoalsTests
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-12-25.
//

import Foundation
import SwiftData
import Testing
@testable import Goals

struct SampleDataTests
{
    @Test("SampleData uses an in-memory SwiftData container and inserts sample Topics and StudySessions")
    @MainActor
    func sampleDataInserts() async throws {
        let sample = SampleData.shared
        let context = sample.context

        let topics = try context.fetch(FetchDescriptor<Topic>())
        let sessions = try context.fetch(FetchDescriptor<StudySession>())

        #expect(topics.count >= Topic.sampleData.count)
        #expect(sessions.count >= StudySession.sampleData.count)
    }
}
