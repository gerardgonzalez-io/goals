//
//  TopicListView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI
import SwiftData

struct TopicListView: View
{
    @Query(sort: \Topic.name) private var topics: [Topic]
    @Query private var sessions: [StudySession]
    @Query private var goals: [Goal]
    @Environment(\.modelContext) private var context
    @State private var newTopic: Topic?
    @Bindable var timer: StudySessionTimer

    typealias Route = Topic.ID

    var body: some View
    {
        List
        {
            ForEach(topics)
            { topic in
                NavigationLink(value: topic.id)
                {
                    Text(topic.name)
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
        .navigationDestination(for: Route.self)
        { topicID in
            if let topic = topics.first(where: { $0.id == topicID })
            {
                TopicDetailView(topic: topic, timer: timer)
            }
            else
            {
                Text("Topic not found")
            }
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
            let topic = topics[index]
            let topicID = topic.id

            for session in sessions where session.topicID == topicID
            {
                context.delete(session)
            }

            for goal in goals where goal.topicID == topicID
            {
                context.delete(goal)
            }

            context.delete(topic)
        }
    }
}

#Preview("Dark")
{
    NavigationStack
    {
        TopicListView(timer: StudySessionTimer())
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}

#Preview("Light")
{
    NavigationStack
    {
        TopicListView(timer: StudySessionTimer())
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.light)
    }
}
