//
//  ContentView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 03-12-24.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        GoalList()
    }
}

#Preview {
    ContentView()
        .environment(TopicManager())
}
