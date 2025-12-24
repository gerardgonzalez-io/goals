//
//  LongestStreakView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI
import SwiftData

struct LongestStreakView: View
{
    let streak: Streak

    var body: some View
    {
        VStack(spacing: 30)
        {
            ZStack
            {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 200, height: 200)
                    .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)

                Text("\(streak.isCurrentStreakActive ? streak.currentStreak : streak.longestStreak)")
                    .font(.system(size: 96, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
            }
            VStack(spacing: 8)
            {
                Text(streak.isCurrentStreakActive ? "Current Session Streak" : "Longest Session Streak")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text("\(streak.isCurrentStreakActive ? streak.currentStreak : streak.longestStreak) Days")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.tint)

                Group
                {
                    if streak.isCurrentStreakActive
                    {
                        Text("Keep studying every day to extend your streak.\nLongest streak: \(streak.longestStreak) days")
                    }
                    else
                    {
                        Text("Study today to reach your goals.")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.top, 100)
        
    }
}

#Preview("Dark")
{
    LongestStreakView(streak: Streak(sessions: StudySession.sampleData))
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    LongestStreakView(streak: Streak(sessions: StudySession.sampleData))
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
}
