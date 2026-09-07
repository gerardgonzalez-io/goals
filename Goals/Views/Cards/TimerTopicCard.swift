//
//  TimerTopicCard.swift
//  Goals
//

import SwiftUI

struct TimerTopicCard: View
{
    let topicName: String

    var body: some View
    {
        HStack(spacing: 14)
        {
            ZStack
            {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(brandGradient)

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4)
            {
                Text("Focus on")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(topicName)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)

                Text("This session will be tracked for this topic")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var brandGradient: LinearGradient
    {
        LinearGradient(
            colors: [
                Color("GoalLightPurple"),
                Color("GoalPurple")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview
{
    TimerTopicCard(topicName: "Mathematics")
        .padding()
}
