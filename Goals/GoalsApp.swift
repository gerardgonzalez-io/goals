//
//  GoalsApp.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 21-06-25.
//

import SwiftUI
import SwiftData

@main
struct GoalsApp: App
{
    // Persisted flag that survives app relaunches; cleared only when app is deleted
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var sharedModelContainer: ModelContainer =
    {
        // Use the latest schema (V2) + migration plan (V1 -> V2)
        let schema = Schema(versionedSchema: GoalsSchemaV2.self)

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do
        {
            return try ModelContainer(
                for: schema,
                migrationPlan: GoalsMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        }
        catch
        {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene
    {
        WindowGroup
        {
            if hasCompletedOnboarding
            {
                ContentView()
            }
            else
            {
                OnboardingView
                {
                    hasCompletedOnboarding = true
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
