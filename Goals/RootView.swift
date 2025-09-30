//
//  RootView.swift
//  Goals
//
//  Created by Assistant on 29-09-25.
//

import SwiftUI

struct RootView: View
{
    // Persisted flag that survives app relaunches; cleared only when app is deleted
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View
    {
        Group
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
    }
}

#Preview("Onboarding")
{
    RootView()
        .environment(\.modelContext, SampleData.shared.modelContainer.mainContext)
}
