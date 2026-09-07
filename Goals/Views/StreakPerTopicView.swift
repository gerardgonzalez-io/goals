//
//  StreakPerTopicView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 08-12-25.
//

import SwiftUI
import SwiftData

struct StreakPerTopicView: View
{
    let topic: Topic

    @Query private var sessions: [StudySession]

    init(topic: Topic)
    {
        self.topic = topic

        let topicID = topic.id
        let predicate = #Predicate<StudySession> { session in
            session.topicID == topicID
        }

        _sessions = Query(
            filter: predicate,
            sort: [SortDescriptor(\.startDate, order: .reverse)]
        )
    }

    private var current: Int
    {
        StreakCalculator().calculateStreak(for: sessions)
    }

    private var longest: Int
    {
        longestStreak(from: sessions)
    }

    var body: some View
    {
        ScrollView
        {
            VStack(spacing: 24)
            {
                header

                currentCard

                VStack(spacing: 16)
                {
                    bestCard
                    tipCard
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .navigationTitle("Streak")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Header
private extension StreakPerTopicView
{
    var header: some View
    {
        VStack(spacing: 8)
        {
            Text(topic.name)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Your streaks")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Current card (gradient)
private extension StreakPerTopicView
{
    var currentCard: some View
    {
        StreakSummaryCard(
            title: "Current streak",
            current: current,
            subtitle: currentSubtitle
        )
    }

    var currentSubtitle: String
    {
        if sessions.isEmpty
        {
            return "Start your first session on this topic and begin your streak."
        }
        if current == 0
        {
            return "Your streak is waiting. A session today brings it back."
        }
        return "Keep going. Every day you add makes this topic stronger."
    }
}

// MARK: - Best card
private extension StreakPerTopicView
{
    var bestCard: some View
    {
        HStack
        {
            VStack(alignment: .leading, spacing: 6)
            {
                Text("Longest streak")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4)
                {
                    Text("\(longest)")
                        .font(.title.bold())

                    Text(longest == 1 ? "day" : "days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "medal.fill")
                .symbolRenderingMode(.multicolor)
                .font(.title2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Tip card
private extension StreakPerTopicView
{
    var tipCard: some View
    {
        VStack(alignment: .leading, spacing: 8)
        {
            Text("Tip")
                .font(.subheadline.bold())

            Text(tipText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var tipText: String
    {
        "Stay focus, consistency beats intensity."
    }
}

// MARK: - Data
private extension StreakPerTopicView
{
    func longestStreak(from sessions: [StudySession]) -> Int
    {
        let days = successfulDays(from: sessions).sorted()
        guard !days.isEmpty else { return 0 }

        var longest = 0
        var current = 0
        var previousDay: Date?
        let calendar = Calendar.current

        for day in days
        {
            if let previousDay,
               calendar.dateComponents([.day], from: previousDay, to: day).day == 1
            {
                current += 1
            }
            else
            {
                current = 1
            }

            longest = max(longest, current)
            previousDay = day
        }

        return longest
    }

    func successfulDays(from sessions: [StudySession]) -> Set<Date>
    {
        var days = Set<Date>()
        let calendar = Calendar.current

        for session in sessions
        {
            for interval in session.sessionIntervals
            {
                guard let endDate = interval.endDate, interval.startDate < endDate else { continue }

                let firstDay = calendar.startOfDay(for: interval.startDate)
                let inclusiveEnd = endDate.addingTimeInterval(-TimeInterval.leastNonzeroMagnitude)
                guard inclusiveEnd >= interval.startDate else { continue }

                let lastDay = calendar.startOfDay(for: inclusiveEnd)
                var currentDay = firstDay

                while currentDay <= lastDay
                {
                    days.insert(currentDay)
                    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
                    currentDay = nextDay
                }
            }
        }

        return days
    }
}


// MARK: - Preview
#Preview
{
    NavigationStack
    {
        StreakPerTopicView(topic: SampleData.shared.topic)
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}
