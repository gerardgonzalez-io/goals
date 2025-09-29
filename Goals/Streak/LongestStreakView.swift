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

    // MARK: - Streak logic (concise overview)
    // Build totals per calendar day from persisted sessions plus today's in-progress timer time.
    // A day qualifies when its total >= the goal minutes that were effective on that specific day (historical-aware).
    // currentStreak counts consecutive qualifying days ending in TODAY; it's active only if today qualifies.
    // longestStreak is the maximum length of any consecutive run of qualifying days.

    private var calendar: Calendar { Calendar.current }

    // Sum seconds per startOfDay; includes live timer so the circle updates as you study.
    private var totalsByDay: [Date: TimeInterval]
    {
        var totals: [Date: TimeInterval] = [:]
        for session in sessions
        {
            let day = calendar.startOfDay(for: session.startDate)
            totals[day, default: 0] += session.duration
        }
        let todayStart = calendar.startOfDay(for: Date())
        if timer.elapsed > 0
        {
            totals[todayStart, default: 0] += timer.elapsed
        }
        return totals
    }

    private var goalMinutes: Int
    {
        appSettings.first?.dailyStudyGoalMinutes ?? AppSettings.defaultGoalMinutes
    }

    // Set of calendar days that met/exceeded their effective goal.
    private var qualifyingDays: Set<Date>
    {
        let settings = appSettings.first
        let days: Set<Date> = Set(
            totalsByDay.compactMap
            { (day, total) in
                let effectiveMinutes = settings?.goalMinutes(effectiveOn: day) ?? AppSettings.defaultGoalMinutes
                let goalForDaySeconds = TimeInterval(effectiveMinutes * 60)
                return total >= goalForDaySeconds ? day : nil
            }
        )
        return days
    }

    // Count backwards from today while each previous day qualifies; returns 0 if today doesn't qualify.
    private var currentStreak: Int
    {
        // Current streak is only considered active if today qualifies.
        let today = calendar.startOfDay(for: Date())
        guard qualifyingDays.contains(today) else { return 0 }

        var count = 0
        var cursor = today
        while qualifyingDays.contains(cursor)
        {
            count += 1
            if let prev = calendar.date(byAdding: .day, value: -1, to: cursor)
            {
                cursor = calendar.startOfDay(for: prev)
            }
            else
            {
                break
            }
        }
        return count
    }

    private var isCurrentStreakActive: Bool { currentStreak > 0 }

    // Scan sorted qualifying days to find the longest consecutive-day sequence.
    private var longestStreak: Int
    {
        if qualifyingDays.isEmpty { return 0 }
        let sorted = qualifyingDays.sorted()
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

                // Show current streak when active; otherwise show the all-time longest streak.
                Text("\(isCurrentStreakActive ? currentStreak : longestStreak)")
                    .font(.system(size: 96, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
            }
            VStack(spacing: 8)
            {
                // Title switches between Current/Longest depending on active state.
                Text(isCurrentStreakActive ? "Current Session Streak" : "Longest Session Streak")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text("\(isCurrentStreakActive ? currentStreak : longestStreak) Days")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.tint)

                // When active, encourage extending the streak and display the record; otherwise a generic nudge.
                Group {
                    if isCurrentStreakActive {
                        Text("Keep studying every day to extend your streak.\nLongest streak: \(longestStreak) days")
                    } else {
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
