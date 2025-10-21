//
//  StreakView.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI
import SwiftData

struct StreakView: View
{
    @Environment(\.modelContext) private var modelContext

    @Query private var sessions: [StudySession]
    @Query private var todaySessions: [StudySession]
    // Order asc by default
    @Query(sort: \Goal.createdAt) private var goals: [Goal]

    @State private var showingLongestStreak = false
    @State private var showingGoalPicker = false
    @State private var tempGoalInMinutes: Int = 15

    private let startOfToday: Date
    private let startOfTomorrow: Date

    init() {
        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = .current

        let start = calendarWithTimeZone.startOfDay(for: .now)
        let next  = calendarWithTimeZone.date(byAdding: .day, value: 1, to: start)!

        self.startOfToday = start
        self.startOfTomorrow = next

        _todaySessions = Query(
            filter: #Predicate<StudySession> { session in
                // To ensure SwiftData can evaluate the predicate efficiently and use indexes,
                // we filter using the persisted 'startDate' property rather than computed or transient properties.
                // Comparing directly on 'startDate' allows filtering directly in the store.
                session.startDate >= start && session.startDate < next
            },
            sort: [SortDescriptor(\StudySession.startDate)]
        )
    }

    var body: some View
    {
        
        VStack(spacing: 30)
        {
            Spacer()

            VStack(spacing: 8)
            {
                Text("Study Goal")
                    .font(.system(.title).bold())
                    .foregroundStyle(.primary)
                
                Text("Track your time, stay focused, and achieve your daily study goals.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 8)

            ZStack
            {
                //Background Arc
                SemiRing()
                    .stroke(lineWidth: 9)
                    .foregroundStyle(.quaternary)
                    .frame(width: 300, height: 150)

                //Progress Arc
                SemiRing()
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .foregroundStyle(.tint.opacity(0.6))
                    .frame(width: 300, height: 150)
                    .animation(.easeInOut(duration: 0.8), value: progress)
                
                VStack
                {
                    Text("Today’s Session")
                        .font(.callout).bold()
                        .foregroundStyle(.primary)
                        .opacity(0.85)
                    
                    Text(formatHM(totalMinutesToday))
                        .font(.system(size: 60, weight: .light, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Button
                    {
                        tempGoalInMinutes = goal
                        showingGoalPicker = true
                    }
                    label:
                    {
                        HStack(spacing: 4)
                        {
                            // If streak is active, prompt to extend it; otherwise invite to start a new one.
                            Text("of your \(goal)-minute goal")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .offset(y: 16)
            }

            WeekRow(days: weekDaySymbols, states: weekStates)

            VStack(spacing: 4)
            {
                Button(action: { showingLongestStreak = true })
                {
                    HStack(spacing: 6)
                    {
                        // If streak is active, prompt to extend it; otherwise invite to start a new one.
                        Text(streak.isCurrentStreakActive ? "Extend your \(streak.currentStreak)-day session streak." : "Start a new streak.")
                            .font(.callout.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                
                // Always show the real record (longest streak), regardless of active state.
                Text("Record is \(streak.longestStreak) days.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            // Chek if this Spacer() is really necessary
            Spacer()
        }
        .sheet(isPresented: $showingLongestStreak)
        {
            NavigationStack
            {
                LongestStreakView(streak: streak)
                    .toolbar
                    {
                        ToolbarItem(placement: .topBarTrailing)
                        {
                            Button
                            {
                                showingLongestStreak = false
                            }
                            label:
                            {
                                Image(systemName: "xmark")
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingGoalPicker) {
            GoalMinutesPickerSheet(selectedMinutes: $tempGoalInMinutes)
            {
                addNewGoal()
            }
        }
    }
}

/// A `Shape` that draws a 180° semicircle based on the assigned rect size.
///
/// Typical usage:
/// - As background: `SemiRing().stroke(lineWidth: 9)`
/// - For progress: apply `.trim(from: 0, to: progress)` with `progress` in [0, 1].
///
/// Notes:
/// - Size is controlled with `.frame(width:height:)`. For a "perfect" semicircle, use a 2:1 ratio (e.g., 300x150).
/// - `.trim` expects a normalized value between 0 and 1; 0 draws nothing, 1 draws the full semicircle.
struct SemiRing: Shape
{
    func path(in rect: CGRect) -> Path
    {
        /// Creates a 180° arc centered at the bottom of the rect, with radius `rect.width / 2`.
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

extension StreakView
{
    var streak: Streak
    {
        Streak(sessions: sessions)
    }

    // the latest goal register is the most current
    private var goal: Int
    {
        goals.last?.goalInMinutes ?? 15
    }

    private var totalMinutesToday: Int
    {
        todaySessions.reduce(0)
        {
            $0 + $1.durationInMinutes
        }
    }

    private var progress: CGFloat
    {
        let target = max(1, goal) // avoid division by zero
        let todayProgress = CGFloat(totalMinutesToday) / CGFloat(target)
        let nonNegativeProgress = max(todayProgress, 0)   // avoid negative values
        let clampedProgress = min(nonNegativeProgress, 1) // limit the value to 100%
        return clampedProgress
    }

    private func formatHM(_ totalMinutes: Int) -> String
    {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }

    private var weekDaySymbols: [String]
    {
        var calendar: Calendar { Calendar.current }
        // Use short standalone symbols ordered by user's firstWeekday
        let symbols = calendar.shortStandaloneWeekdaySymbols.map { $0.prefix(1).uppercased() }
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first..<symbols.count]) + Array(symbols[0..<first])
        return ordered
    }

    /// Visual states for the weekly row, aligned with `weekDaySymbols`.
    ///
    /// Rules:
    /// - Future days: `.none`
    /// - Past days: `.completed` if the day met the goal (per DailyStatus), otherwise `.none`
    /// - Today: `.completed` if met; `.progress` if there are sessions today but the goal isn't met yet; `.none` if there are no sessions
    private var weekStates: [DayState]
    {
        var calendar = Calendar.current
        calendar.timeZone = .current

        // Start of the current week per the user's settings (aligned with weekDaySymbols)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: startOfToday) else { return Array(repeating: .none, count: 7) }
        let startOfWeek = calendar.startOfDay(for: weekInterval.start)

        // Build per-normalized-day maps from sessions
        // - metByDay: whether the day "met" the goal (at least one topic met)
        // - hasSessionsByDay: whether there are sessions on that day
        var grouped: [Date: [StudySession]] = [:]
        for session in sessions
        {
            let day = session.normalizedDay
            grouped[day, default: []].append(session)
        }

        var metByDay: [Date: Bool] = [:]
        var hasSessionsByDay: [Date: Bool] = [:]
        for (day, daySessions) in grouped
        {
            hasSessionsByDay[day] = !daySessions.isEmpty
            if let status = DailyStatus.compute(from: daySessions)
            {
                // Fulfillment rule: at least one topic met
                let met = status.isMet.contains(true)
                metByDay[day] = met
            }
        }

        // Build the 7 states for the visible week
        var result: [DayState] = []
        result.reserveCapacity(7)

        for offset in 0..<7
        {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { continue }
            let dayStart = calendar.startOfDay(for: day)

            if dayStart > startOfToday
            {
                // Future
                result.append(.none)
                continue
            }

            if dayStart == startOfToday
            {
                if metByDay[dayStart] == true
                {
                    result.append(.completed)
                }
                else if !todaySessions.isEmpty
                {
                    result.append(.progress)
                }
                else
                {
                    result.append(.none)
                }
                continue
            }

            // Past
            if metByDay[dayStart] == true
            {
                result.append(.completed)
            }
            else
            {
                result.append(.none)
            }
        }

        return result
    }

    private func addNewGoal()
    {
        // If there is a latest goal and the value hasn't changed, do nothing.
        if let latest = goals.last, latest.goalInMinutes == tempGoalInMinutes
        {
            showingGoalPicker = false
            return
        }

        // Otherwise, insert a new Goal snapshot with the chosen minutes.
        let newGoal = Goal(goalInMinutes: tempGoalInMinutes)
        modelContext.insert(newGoal)
        try? modelContext.save()
        showingGoalPicker = false
    }
}

#Preview
{
    StreakView()
        .modelContainer(SampleData.shared.modelContainer)
}

