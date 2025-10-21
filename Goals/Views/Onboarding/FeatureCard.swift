//
//  FeatureCard.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI

struct FeatureCard: View
{
    let iconName: String
    let description: String
    
    var body: some View
    {
        HStack
        {
            Image(systemName: iconName)
                .font(.largeTitle)
                .frame(width: 50)
                .padding(.trailing, 10)
            
            Text(description)
            
            Spacer()
        }
        .padding()
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
    FeatureCard(iconName: "timer",
                description: "Build discipline by keeping a clean log of your daily effort")
            .frame(maxHeight: .infinity)
            .background(Gradient(colors: gradientColors))
}
