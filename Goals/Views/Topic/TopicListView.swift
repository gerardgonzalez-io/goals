//
//  TopicListView.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI
import SwiftData

struct TopicListView: View
{
    @Query(sort: \Topic.name) private var topics: [Topic]
    @Environment(\.modelContext) private var context
    @State private var newTopic: Topic?
    
    var body: some View
    {
        NavigationSplitView
        {
            List
            {
                ForEach(topics)
                { topic in
                    NavigationLink(topic.name)
                    {
                        TopicDetailView(topic: topic)
                    }
                }
                .onDelete(perform: deteleTopic(indexes:))
            }
            .navigationTitle("Topics")
            .toolbar
            {
                ToolbarItem
                {
                    Button("Add topic", systemImage: "plus", action: addTopic)
                }
                ToolbarItem(placement: .topBarTrailing)
                {
                    EditButton()
                }
            }
            .sheet(item: $newTopic)
            { topic in
                NavigationStack
                {
                    NewTopicView(topic: topic)
                }
                .interactiveDismissDisabled()
            }
        }
        detail:
        {
            Text("Select a topic")
                .navigationTitle("Topic")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func addTopic()
    {
        let newTopic = Topic(name: "")
        context.insert(newTopic)
        self.newTopic = newTopic
    }

    private func deteleTopic(indexes: IndexSet)
    {
        for index in indexes
        {
            context.delete(topics[index])
        }
    }
}

#Preview("Dark")
{
    TopicListView()
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    TopicListView()
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
}

