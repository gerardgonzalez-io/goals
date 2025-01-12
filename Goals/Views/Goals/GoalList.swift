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
            List(topicManager.topics) { topic in
                NavigationLink {
                    GoalDetail(topic: topic)
                } label: {
                    GoalRow(topic: topic)
                }
                .listRowBackground(topic.theme.mainColor)
                .foregroundStyle(
                    topic.theme.mainColor == Color("goldenyellow") ? Color.black : Color.white
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
