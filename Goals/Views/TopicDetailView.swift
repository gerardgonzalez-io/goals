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

    @Bindable var timer: StudySessionTimer

    fileprivate enum TopicRoute: Hashable
    {
        case focus
        case calendar
        case streak
        case topicGoal
        case progressVsPlan
    }

    private var totalDuration: Int
    {
        Int(TimeCalculator.totalTime(from: sessions) / 60)
    }

    private var todayDuration: Int
    {
        Int(TimeCalculator.dailyTime(from: sessions, on: Date()) / 60)
    }

    init(topic: Topic, timer: StudySessionTimer)
    {
        self.topic = topic
        self._timer = Bindable(wrappedValue: timer)
        let topicID = topic.id
        let predicate = #Predicate<StudySession>
        { session in
            session.topicID == topicID
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
                        ActionCard(
                            title: "Start focus session",
                            subtitle: "Track a new study session for this topic",
                            systemImage: "play.fill",
                            showsChevron: true
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
                        TimeSummaryCard(
                            title: "Today",
                            value: durationString(todayDuration),
                            subtitle: todayDuration > 0
                                ? "Study time today"
                                : "You haven't studied today yet",
                            isPrimary: true
                        )

                        TimeSummaryCard(
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

                    
                    NavigationLink(value: TopicRoute.progressVsPlan)
                    {
                        ProgressPlanOverviewCard(
                            topicID: topic.id,
                            topicName: topic.name
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 4)

                    NavigationLink(value: TopicRoute.calendar)
                    {
                        TopicCard(
                            systemImage: "calendar",
                            title: "Open sessions calendar",
                            subtitle: "See which days you studied this topic"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 4)

                    NavigationLink(value: TopicRoute.streak)
                    {
                        TopicCard(
                            systemImage: "flame.fill",
                            title: "View topic streak",
                            subtitle: "Check your streak for this topic"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 4)
                    
                    NavigationLink(value: TopicRoute.topicGoal)
                    {
                        TopicCard(
                            systemImage: "scope",
                            title: "Change goal",
                            subtitle: "Adjust your goal for this topic"
                        )
                    }
                    .buttonStyle(.plain)
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
            case .topicGoal:
                TopicGoal(topic: topic)
            case .progressVsPlan:
                ProgressPlanChartView(
                    topicID: topic.id,
                    topicName: topic.name
                )
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
        TopicDetailView(
            topic: SampleData.shared.topic,
            timer: StudySessionTimer()
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
            timer: StudySessionTimer()
        )
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
    }
}
