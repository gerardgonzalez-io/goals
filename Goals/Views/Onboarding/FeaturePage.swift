//
//  FeaturePage.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI

struct FeaturePage: View
{
    var onFinish: (() -> Void)? = nil

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

            Button
            {
                finishOnboarding()
            }
            label:
            {
                Text("Get Started")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.2), in: .capsule)
                    .overlay(
                        Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding()
    }

    private func finishOnboarding()
    {
        withAnimation(.easeInOut(duration: 0.25))
        {
            if let onFinish
            {
                onFinish()
            }
        }
    }
}

#Preview
{
    FeaturePage()
        .frame(maxHeight: .infinity)
        .background(Gradient(colors: gradientColors))
        .foregroundStyle(.white)
}

