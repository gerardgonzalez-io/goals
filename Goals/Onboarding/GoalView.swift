//
//  GoalView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 29-09-25.
//

import SwiftUI

struct GoalView: View
{
    var onFinish: (() -> Void)? = nil
    @State private var selectedMinutes: Int = 25
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View
    {
        VStack(spacing: 24)
        {
            Image(systemName: "target")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)

            Text("Set your goal")
                .font(.largeTitle).bold()

            Text("Choose your daily study goal. You can change it later.")
                .multilineTextAlignment(.center)
                .font(.body)
                .opacity(0.9)

            VStack(spacing: 12)
            {
                Slider(value: Binding(
                    get: { Double(selectedMinutes) },
                    set: { selectedMinutes = Int($0) }
                ), in: 10...120, step: 5)
                .tint(.white)

                Text("\(selectedMinutes) min")
                    .font(.title2).bold()
                    .monospacedDigit()
            }
            .padding(.horizontal)

            Button
            {
                let initialSetting = AppSettings(dailyStudyGoalMinutes: selectedMinutes)
                modelContext.insert(initialSetting)
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

            Button(role: .cancel)
            {
                finishOnboarding()
            }
            label:
            {
                Text("Decide Later")
            }
            .padding(.top, 4)
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
            else
            {
                dismiss()
            }
        }
    }
}

#Preview
{
    GoalView()
        .frame(maxHeight: .infinity)
        .background(Gradient(colors: gradientColors))
        .foregroundStyle(.white)
}
