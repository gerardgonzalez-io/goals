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
        @Bindable var topicManager = topicManager

        NavigationStack {
            List($topicManager.topics) { $topic in
                NavigationLink {
                    GoalDetail(topic: $topic)
                } label: {
                    GoalRow(topic: topic)
                }
                .listRowBackground(topic.theme.mainColor)
                .foregroundStyle(
                    // Color of this symbol " > "
                    topic.theme.accentColor
                )
            }
            .navigationTitle("Topics")
        }
    }
}

#Preview {
    GoalList()
        .environment(TopicManager())
}
