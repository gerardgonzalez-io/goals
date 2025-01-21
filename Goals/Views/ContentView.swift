//
//  ContentView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 03-12-24.
//

import SwiftUI

struct ContentView: View {
    @State private var errorWrapper: ErrorWrapper?
    @State private var topicStore = TopicStore()

    var body: some View {
        GoalList() {
            Task {
                do {
                    try await topicStore.save(topics: topicStore.topics)
                } catch {
                    errorWrapper = ErrorWrapper(error: error,
                                                guidance: "Try again later.")
                }
            }
        }
        .task {
            do {
                try await topicStore.load()
            } catch {
                errorWrapper = ErrorWrapper(error: error,
                                            guidance: "Goals will load sample data and continue.")
            }
        }
        .sheet(item: $errorWrapper) {
            topicStore.topics = Topic.sampleData
        } content: { wrapper in
            ErrorView(errorWrapper: wrapper)
        }
        .environment(topicStore)
    }
}

#Preview {
    ContentView()
        .environment(TopicStore())
}
