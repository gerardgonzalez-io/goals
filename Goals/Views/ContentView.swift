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

    var body: some View
    {
        TabView
        {
            Tab("Topics", systemImage: "list.bullet.rectangle")
            {
                TopicListView()
            }

            Tab("Streak", systemImage: "flame.fill")
            {
                StreakView()
            }

            Tab("Timer", systemImage: "timer")
            {
                TimerView()
            }
        }
        
    }
}

#Preview
{
    ContentView()
}
