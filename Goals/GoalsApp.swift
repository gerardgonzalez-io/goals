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
    var body: some Scene
    {
        WindowGroup
        {
            RootView()
        }
        .modelContainer(for: [Topic.self, StudySession.self, AppSettings.self])
    }
}
