//
//  FeaturePage.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI

struct FeaturePage: View
{
    var body: some View
    {
        VStack
        {
            Text("Features")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom)
                .padding(.top, 100)
            
            FeatureCard(iconName: "timer",
                        description: "Build discipline by keeping a clean log of your daily effort.")
            
            FeatureCard(iconName: "flame.fill",
                        description: "Track your discipline and build powerful habits.")
            
            FeatureCard(iconName: "chart.bar.xaxis",
                        description: "Get clear insights with charts to see how far you’ve come.")
            
            Spacer()
        }
        .padding()
    }
}

#Preview
{
    FeaturePage()
        .frame(maxHeight: .infinity)
        .background(Gradient(colors: gradientColors))
        .foregroundStyle(.white)
}

