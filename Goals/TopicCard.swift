//
//  TopicCard.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 23-09-25.
//

import SwiftUI

struct TopicCard: View
{
    let description: String
    let timeSpent: String
    
    var body: some View
    {
        VStack(alignment: .leading, spacing: 8)
        {
            Text(description)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(timeSpent)
                .font(.system(size: 47, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background
        {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.tint)
                .opacity(0.25)
        }
        .foregroundStyle(.white)
    }
}

#Preview
{
    TopicCard(description: "Today", timeSpent: "07h 09m")
        .frame(maxHeight: .infinity)
        .background(Gradient(colors: gradientColors))
}
