//
//  GoalsApp.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 03-12-24.
//

import SwiftUI

@main
struct GoalsApp: App {
    @State private var topicManager = TopicManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(topicManager)
        }
    }
}
