//
//  ContentView.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-10-25.
//

import SwiftUI
import SwiftData

struct ContentView: View
{
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var timer = Timer()

    var body: some View
    {
        TabView
        {
            Tab("Topics", systemImage: "list.bullet.rectangle")
            {
                TopicListView(timer: timer)
            }

            Tab("Streak", systemImage: "flame.fill")
            {
                StreakView()
            }
        }
        .onAppear
        {
            UserDefaults.standard.set(UUID().uuidString, forKey: "currentLaunchID")
        }
        .onChange(of: scenePhase)
        { oldPhase, newPhase in
            switch newPhase
            {
            case .background:
                UserDefaults.standard.set(UUID().uuidString, forKey: "lastSessionID")
                timer.saveSnapshot()
            case .active:
                let lastSessionID = UserDefaults.standard.string(forKey: "lastSessionID")
                let currentLaunchID = UserDefaults.standard.string(forKey: "currentLaunchID")
                if lastSessionID == currentLaunchID
                {
                    timer.restoreFromSnapshotAndResume()
                }
                else
                {
                    UserDefaults.standard.removeObject(forKey: "timer.snapshot.v1")
                }
            default:
                break
            }
        }
    }
}

#Preview
{
    ContentView()
}
