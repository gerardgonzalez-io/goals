//
//  GoalList.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 06-12-24.
//

import SwiftUI

struct GoalList: View {
    @Environment(TopicManager.self) var topicManager

    var body: some View {
        NavigationStack {
            List(topicManager.topics) { topic in
                NavigationLink {
                    GoalDetail()
                } label: {
                    GoalRow(topic: topic)
                }
            }
            .navigationTitle("Topics")
        }
    }
}

#Preview {
    GoalList()
        .environment(TopicManager())
}
