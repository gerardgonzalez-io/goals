//
//  TopicCard.swift
//  Goals
//

import SwiftUI

struct TopicCard: View
{
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View
    {
        HStack(spacing: 12)
        {
            Image(systemName: systemImage)
                .imageScale(.medium)
                .foregroundStyle(Color.accentColor)

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
}

#Preview
{
    TopicCard(
        systemImage: "play.circle.fill",
        title: "Timer",
        subtitle: "Start or continue your study timer for this topic."
    )
    .padding()
}
