//
//  LongestStreakView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 28-09-25.
//

import SwiftUI
import SwiftData

struct LongestStreakView: View
{
    @EnvironmentObject private var timer: TimerModel
    @Query private var sessions: [StudySession]
    @Query private var appSettings: [AppSettings]

    private var goalMinutes: Int
    {
        appSettings.first?.dailyStudyGoalMinutes ?? AppSettings.defaultGoalMinutes
    }

    private var longestStreak: Int
    {
        // Compute longest consecutive-day streak where each day meets/exceeds the daily goal
        let calendar = Calendar.current

        // Build totals per day from persisted sessions
        var totalsByDay: [Date: TimeInterval] = [:]
        for session in sessions
        {
            let day = calendar.startOfDay(for: session.startDate)
            totalsByDay[day, default: 0] += session.duration
        }

        // Add today's in-progress time (even if not persisted yet)
        let todayStart = calendar.startOfDay(for: Date())
        if timer.elapsed > 0
        {
            totalsByDay[todayStart, default: 0] += timer.elapsed
        }

        // Build the set of qualifying days (met or exceeded the historical goal for that day)
        let settings = appSettings.first
        let qualifyingDays: Set<Date> = Set(
            totalsByDay.compactMap
            { (day, total) in
                let effectiveMinutes = settings?.goalMinutes(effectiveOn: day) ?? AppSettings.defaultGoalMinutes
                let goalForDaySeconds = TimeInterval(effectiveMinutes * 60)
                return total >= goalForDaySeconds ? day : nil
            }
        )

        if qualifyingDays.isEmpty { return 0 }

        // Sort qualifying days ascending
        let sorted = qualifyingDays.sorted()

        // Walk and compute longest run of consecutive days
        var longest = 1
        var current = 1
        for i in 1..<sorted.count
        {
            if let diff = calendar.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day, diff == 1
            {
                current += 1
            }
            else
            {
                longest = max(longest, current)
                current = 1
            }
        }
        longest = max(longest, current)
        return longest
    }

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

                Text("\(longestStreak)")
                    .font(.system(size: 96, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
            }
            VStack(spacing: 8)
            {
                Text("Longest Session Streak")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text("\(longestStreak) Days")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.tint)

                Text("Study today to reach your goals.")
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
    @Previewable @Environment(\.modelContext) var context
    LongestStreakView()
        .environmentObject(TimerModel(context: context))
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    @Previewable @Environment(\.modelContext) var context
    LongestStreakView()
        .environmentObject(TimerModel(context: context))
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
}
