//
//  ContentView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 21-06-25.
//

import SwiftUI

struct ContentView: View
{
    var body: some View
    {
        TabView
        {
            Tab("Topics", systemImage: "list.bullet.rectangle")
            {
                TopicView()
            }

            Tab("Streak", systemImage: "flame.fill")
            {
                StreakView()
            }

            Tab("Timer", systemImage: "timer")
            {
                
            }
        }
        
    }
}

#Preview
{
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}
