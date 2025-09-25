//
//  ContentView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 21-06-25.
//

import SwiftUI

struct ContentView: View
{
    @Environment(\.modelContext) private var context

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
                    .environmentObject(TimerModel(context: context))
            }
        }
        
    }
}

#Preview("Dark")
{
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
}
