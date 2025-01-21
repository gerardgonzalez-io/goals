//
//  NewTopicSheet.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 21-01-25.
//

import SwiftUI

struct NewTopicSheet: View {
    @State private var newTopic = Topic.emptyTopic
    @Binding var topics: [Topic]
    @Binding var isPresentingNewTopicView: Bool
    
    var body: some View {
        NavigationStack {
            DetailEditView(topic: $newTopic)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Dismiss") {
                            isPresentingNewTopicView = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            topics.append(newTopic)
                            isPresentingNewTopicView = false
                        }
                    }
                }
        }
    }
}

#Preview {
    NewTopicSheet(topics: .constant(Topic.sampleData), isPresentingNewTopicView: .constant(true))
}
