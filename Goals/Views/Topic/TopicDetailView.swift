//
//  TopicDetailView.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI
import SwiftData

struct TopicDetailView: View
{
    let topic: Topic

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [StudySession]

    private var totalDuration: Int
    {
        sessions.reduce(0) { $0 + $1.durationInMinutes }
    }

    private var todayDuration: Int
    {
        let calendar = Calendar.current
        let today = Date()
        return sessions
            .filter { session in
                calendar.isDate(session.normalizedDay, inSameDayAs: today)
            }
            .reduce(0) { $0 + $1.durationInMinutes }
    }

    init(topic: Topic)
    {
        self.topic = topic
        // Fetch all sessions that belong to this topic, newest first
        let topicID = topic.id
        let predicate = #Predicate<StudySession>
        { session in
            session.topic.id == topicID
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
            VStack(alignment: .leading, spacing: 24)
            {
                // Metric cards
                VStack(spacing: 16)
                {
                    TopicCard(
                        title: "Today",
                        value: durationString(todayDuration),
                        subtitle: todayDuration > 0
                            ? "Study time today"
                            : "You haven't studied today yet",
                        isPrimary: true
                    )

                    TopicCard(
                        title: "Total",
                        value: durationString(totalDuration),
                        subtitle: "Total time spent on this topic",
                        isPrimary: false
                    )
                }
                .padding(.horizontal, 20)

                // Study history
                VStack(alignment: .leading, spacing: 8)
                {
                    Text("Study history")
                        .font(.headline)
                        .padding(.horizontal, 20)

                    NavigationLink
                    {
                        CalendarView(topic: topic)
                    }
                    label:
                    {
                        HStack(spacing: 12)
                        {
                            Image(systemName: "calendar")
                                .imageScale(.medium)
                                .foregroundStyle(.accent)

                            VStack(alignment: .leading, spacing: 2)
                            {
                                Text("Open sessions calendar")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("See which days you studied this topic")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .padding(.bottom, 16)
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
                .accessibilityLabel("Back")
            }
        }
    }

    private func durationString(_ minutes: Int) -> String
    {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return String(format: "%dh %02dm", hours, remainingMinutes)
    }
}

#Preview("Dark")
{
    NavigationStack
    {
        TopicDetailView(topic: SampleData.shared.topic)
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}

#Preview("Light")
{
    NavigationStack
    {
        TopicDetailView(topic: SampleData.shared.topic)
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.light)
    }
}
