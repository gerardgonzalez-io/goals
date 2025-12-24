//
//  OnboardingView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI

let gradientColors: [Color] = [
    .gradientTop,
    .gradientBottom
]

struct OnboardingView: View
{
    var onFinish: (() -> Void)? = nil

    var body: some View
    {
        TabView
        {
            WelcomePage()
            FeaturePage(onFinish: onFinish)
        }
        .background(Gradient(colors: gradientColors))
        .tabViewStyle(.page)
        .foregroundStyle(.white)
    }
}

#Preview
{
    OnboardingView()
}
