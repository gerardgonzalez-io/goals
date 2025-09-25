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
                .foregroundStyle(.primary)
            Text(timeSpent)
                .font(.system(size: 47, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background
        {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.tint)
                .opacity(0.25)
        }
    }
}


#Preview("Dark")
{
    TopicCard(description: "Today", timeSpent: "07h 09m")
        .frame(maxHeight: .infinity)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    TopicCard(description: "Today", timeSpent: "07h 09m")
        .frame(maxHeight: .infinity)
        .preferredColorScheme(.light)
}

#Preview("Gradient")
{
    TopicCard(description: "Today", timeSpent: "07h 09m")
        .frame(maxHeight: .infinity)
        .background(Gradient(colors: gradientColors))
}
