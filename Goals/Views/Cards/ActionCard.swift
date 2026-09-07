//
//  ActionCard.swift
//  Goals
//

import SwiftUI

struct ActionCard: View
{
    let title: String
    let subtitle: String
    let systemImage: String
    let showsChevron: Bool

    var body: some View
    {
        HStack(spacing: 14)
        {
            ZStack
            {
                LinearGradient(
                    colors: [
                        Color("GoalLightPurple"),
                        Color("GoalPurple")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(Circle())
                .frame(width: 40, height: 40)

                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3)
            {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if showsChevron
            {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
}

#Preview
{
    ActionCard(
        title: "Start focus session",
        subtitle: "Track a new study session for this topic",
        systemImage: "play.fill",
        showsChevron: true
    )
    .padding()
}
