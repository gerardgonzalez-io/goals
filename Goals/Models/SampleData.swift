//
//  SampleData.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-10-25.
//

import Foundation
import SwiftData

@MainActor
class SampleData
{
    static let shared = SampleData()

    let modelContainer: ModelContainer

    var context: ModelContext
    {
        modelContainer.mainContext
    }

    var topic: Topic
    {
        Topic.sample
    }

    private init()
    {
        let schema = Schema([
            Topic.self,
            Goal.self,
            StudySession.self,
            SessionInterval.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do
        {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            insertSampleData()
            try context.save()
        }
        catch
        {
            fatalError("Could not create model container: \(error)")
        }
    }

    private func insertSampleData()
    {
        for topic in Topic.sampleData
        {
            context.insert(topic)
        }

        for goal in Goal.sampleData
        {
            context.insert(goal)
        }

        for session in StudySession.sampleData
        {
            context.insert(session)
        }
    }
}
