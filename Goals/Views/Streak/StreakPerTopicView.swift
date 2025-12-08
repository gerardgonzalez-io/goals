//
//  StreakPerTopicView.swift
//  GoalsV2
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
            session.topic.id == topicID
        }

        _sessions = Query(
            filter: predicate,
            sort: [SortDescriptor(\.startDate, order: .reverse)]
        )
    }

    private var streak: Streak
    {
        Streak(sessions: sessions)
    }

    private var current: Int
    {
        streak.currentStreak(for: topic)
    }

    private var longest: Int
    {
        streak.longestStreak(for: topic)
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
        ZStack
        {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(brandGradient)

            VStack(spacing: 16)
            {
                HStack(spacing: 10)
                {
                    Image(systemName: "flame.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.title2)

                    Text("Current streak")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()
                }

                HStack(alignment: .firstTextBaseline, spacing: 4)
                {
                    Text("\(current)")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(current == 1 ? "day" : "days")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer()
                }

                Text(currentSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
        .shadow(radius: 8, y: 4)
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

// MARK: - Brand gradient
private extension StreakPerTopicView
{
    var brandGradient: LinearGradient
    {
        LinearGradient(
            colors: [
                Color(red: 63/255, green: 167/255, blue: 214/255), // #3FA7D6
                Color(red: 29/255, green: 53/255,  blue: 87/255)   // #1D3557
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
