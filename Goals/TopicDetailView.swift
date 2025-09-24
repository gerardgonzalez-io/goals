//
//  TopicDetailView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 23-09-25.
//

import SwiftUI
import SwiftData

struct TopicDetailView: View
{
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [StudySession]
    let topic: Topic

    private var totalDuration: TimeInterval
    {
        sessions.reduce(0) { $0 + $1.duration }
    }

    private var todayDuration: TimeInterval
    {
        let calendar = Calendar.current
        let today = Date()
        return sessions.filter
        { session in
            calendar.isDate(session.startDate, inSameDayAs: today)
        }
        .reduce(0)
        {
            $0 + $1.duration
        }
    }

    init(topic: Topic)
    {
        self.topic = topic
        // Fetch all sessions that belong to this topic, newest first
        let topicID = topic.persistentModelID
        let predicate = #Predicate<StudySession>
        { session in
            session.topic.persistentModelID == topicID
        }
        _sessions = Query(
            filter: predicate,
            sort: [SortDescriptor(\.startDate,
                  order: .reverse)]
        )
    }

    var body: some View
    {
        ScrollView
        {
            VStack(spacing: 16)
            {
                TopicCard(description: "Today",
                          timeSpent:   durationString(todayDuration))

                TopicCard(description: "Total",
                          timeSpent:   durationString(totalDuration))

            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar
        {
            ToolbarItem(placement: .topBarLeading)
            {
                Button
                {
                    dismiss()
                }
                label:
                {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Atrás")
            }

            ToolbarItem(placement: .topBarTrailing)
            {
                Button
                {
                    // TODO: Configure calendar action
                }
                label:
                {
                    Image(systemName: "calendar")
                }
                .accessibilityLabel("Calendario")
            }
        }
    }

    private func durationString(_ interval: TimeInterval) -> String
    {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
}

#Preview
{
    NavigationStack
    {
        TopicDetailView(topic: SampleData.shared.topic)
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
            
    }
}
