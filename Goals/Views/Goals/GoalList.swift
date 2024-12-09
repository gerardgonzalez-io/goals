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
                .listRowBackground(topic.theme.mainColor)
                .foregroundStyle(getArrowColor(for: topic.theme.mainColor))
            }
            .navigationTitle("Topics")
        }
    }
    
    func getArrowColor(for backgroundColor: Color) -> Color {
        if backgroundColor == Color("goldenyellow") {
            return Color.black
        } else {
            return Color.white
        }
    }
}

#Preview {
    GoalList()
        .environment(TopicManager())
}
