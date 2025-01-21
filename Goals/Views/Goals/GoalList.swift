//
//  GoalList.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 06-12-24.
//

import SwiftUI

struct GoalList: View {
    @Environment(TopicStore.self) var topicStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPresentingNewTopicView = false
    let saveAction: ()->Void
    
    var body: some View {
        @Bindable var topicStore = topicStore

        NavigationStack {
            List($topicStore.topics) { $topic in
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
            .toolbar {
                Button(action: {
                    isPresentingNewTopicView = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewTopicView) {
            NewTopicSheet(topics: $topicStore.topics, isPresentingNewTopicView: $isPresentingNewTopicView)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .inactive { saveAction() }
        }
    }
}

#Preview {
    GoalList(saveAction: {})
        .environment(TopicStore())
}
