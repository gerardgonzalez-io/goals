//
//  SampleData.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 26-08-25.
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
        Topic.sampleData.first!
    }
    
    private init()
    {
        // In-memory container used for previews and tests
        let schema = Schema([
            Topic.self,
            StudySession.self
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
    }
}
