//
//  StreakSummaryCard.swift
//  Goals
//

import SwiftUI

struct StreakSummaryCard: View
{
    let title: String
    let current: Int
    let subtitle: String

    var body: some View
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

                    Text(title)
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

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
        .shadow(radius: 8, y: 4)
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
    StreakSummaryCard(
        title: "Current streak",
        current: 7,
        subtitle: "Consecutive study days up to today or yesterday."
    )
    .padding()
}
