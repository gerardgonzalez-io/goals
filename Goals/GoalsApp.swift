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
    @State private var dataContainer = DataContainer()

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
        .environment(dataContainer)
        .modelContainer(dataContainer.modelContainer)
    }
}
