//
//  TopicDetailView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI
import SwiftData

struct TopicDetailView: View
{
    let topic: Topic
    @Query private var sessions: [StudySession]

    @Bindable var timer: Timer

    fileprivate enum TopicRoute: Hashable
    {
        case focus
        case calendar
        case streak
    }

    private var totalDuration: Int
    {
        sessions.reduce(0) { $0 + $1.durationInMinutes }
    }

    private var todayDuration: Int
    {
        let calendar = Calendar.current
        let today = Date()
        return sessions
            .filter
            { session in
                calendar.isDate(session.normalizedDay, inSameDayAs: today)
            }
            .reduce(0) { $0 + $1.durationInMinutes }
    }

    init(topic: Topic, timer: Timer)
    {
        self.topic = topic
        self._timer = Bindable(wrappedValue: timer)
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
                VStack(alignment: .leading, spacing: 8)
                {
                    Text("Focus session")
                        .font(.headline)
                    NavigationLink(value: TopicRoute.focus)
                    {
                        HStack(spacing: 14)
                        {
                            ZStack
                            {
                                LinearGradient(
                                    colors: [
                                        Color(red: 63/255, green: 167/255, blue: 214/255), // #3FA7D6
                                        Color(red: 29/255, green: 53/255,  blue: 87/255)   // #1D3557
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .clipShape(Circle())
                                .frame(width: 40, height: 40)

                                Image(systemName: "play.fill")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 3)
                            {
                                Text("Start focus session")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Track a new study session for this topic")
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
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.06),
                                        radius: 10,
                                        x: 0,
                                        y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 8)
                {
                    Text("Study time")
                        .font(.headline)

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
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 8)
                {
                    Text("Study history")
                        .font(.headline)

                    TopicDetailNavCard(
                        value: TopicRoute.calendar,
                        systemImage: "calendar",
                        title: "Open sessions calendar",
                        subtitle: "See which days you studied this topic"
                    )
                    .padding(.bottom, 4)

                    TopicDetailNavCard(
                        value: TopicRoute.streak,
                        systemImage: "flame.fill",
                        title: "View topic streak",
                        subtitle: "Check your streak for this topic"
                    )
                    .padding(.bottom, 4)

                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: TopicRoute.self)
        { route in
            switch route
            {
            case .focus:
                TimerView(timer: timer, preselectedTopic: topic)
            case .calendar:
                CalendarView(topic: topic)
            case .streak:
                StreakPerTopicView(topic: topic)
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

/// Reusable navigation card for TopicDetail sections.
/// - Keeps the same layout/style for "calendar" and "streak" links.
/// - Generic over the `NavigationLink(value:)` type to avoid tight coupling.
private struct TopicDetailNavCard<Value: Hashable>: View
{
    let value: Value
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View
    {
        NavigationLink(value: value)
        {
            HStack(spacing: 12)
            {
                Image(systemName: systemImage)
                    .imageScale(.medium)
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 2)
                {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(subtitle)
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
    }
}

#Preview("Dark")
{
    NavigationStack
    {
        TopicDetailView(
            topic: SampleData.shared.topic,
            timer: Timer()
        )
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
    }
}

#Preview("Light")
{
    NavigationStack
    {
        TopicDetailView(
            topic: SampleData.shared.topic,
            timer: Timer()
        )
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
    }
}
