//
//  SummaryCard.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 25-12-25.
//

import SwiftUI

struct SummaryCard: View
{
    let title: String
    let subtitle: String
    let systemImage: String
    let showsChevron: Bool

    private var brandLight: Color
    {
        Color(red: 63/255, green: 167/255, blue: 214/255) // #3FA7D6
    }
    private var brandDark: Color
    {
        Color(red: 29/255, green: 53/255, blue: 87/255)   // #1D3557
    }

    var body: some View
    {
        HStack(spacing: 14)
        {
            ZStack
            {
                LinearGradient(
                    colors: [brandDark, brandLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4)
            {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if showsChevron
            {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}


#Preview {
    SummaryCard(title: "Topics",
                subtitle: "Manage what you study and start focus sessions.",
                systemImage: "list.bullet.rectangle",
                showsChevron: false)
}
