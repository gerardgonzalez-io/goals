//
//  StreakView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 11-08-25.
//

import SwiftUI
import SwiftData

struct StreakView: View
{
    @EnvironmentObject private var timer: TimerModel
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings] // por que query se declara como array?
    @Query private var todaySessions: [StudySession]
    @State private var showingLongestStreak = false
    @State private var showingGoalPicker = false
    @State private var tempGoalMinutes: Int = 15

    private var goalMinutes: Int
    {
        appSettings.first?.dailyStudyGoalMinutes ?? 1
    }

    private var persistedToday: TimeInterval
    {
        todaySessions.reduce(0)
        {
            $0 + $1.duration
        }
    }

    private var totalToday: TimeInterval
    {
        // Tiempo total del día = sesiones guardadas hoy + tiempo actual del cronómetro (aunque esté en pausa)
        persistedToday + timer.elapsed
    }

    private var progress: CGFloat
    {
        let target = max(1, goalMinutes) // evitar división entre 0
        let p = CGFloat(totalToday) / CGFloat(target * 60)
        return min(max(p, 0), 1)
    }

    private func formatHM(_ interval: TimeInterval) -> String
    {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    init()
    {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? Date()

        let pred = #Predicate<StudySession>
        { session in
            session.startDate >= start && session.startDate < end
        }
        _todaySessions = Query(filter: pred)
        _appSettings = Query()
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
                    
                    Text(formatHM(totalToday))
                        .font(.system(size: 60, weight: .light, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Button
                    {
                        tempGoalMinutes = goalMinutes
                        showingGoalPicker = true
                    }
                    label:
                    {
                        HStack(spacing: 4)
                        {
                            Text("of your \(goalMinutes)-minute goal")
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

            WeekRow()

            VStack(spacing: 4)
            {
                Button(action: { showingLongestStreak = true })
                {
                    HStack(spacing: 6)
                    {
                        Text("Start a new streak.")
                            .font(.callout.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                
                Text("Your record is 9 days.")
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
                LongestStreakView()
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
            GoalMinutesPickerSheet(selectedMinutes: $tempGoalMinutes)
            {
                // Update settings and record a historical change effective from start of next day
                let calendar = Calendar.current
                let startOfToday = calendar.startOfDay(for: Date())

                let settings: AppSettings
                if let existing = appSettings.first
                {
                    settings = existing
                    settings.dailyStudyGoalMinutes = tempGoalMinutes
                    settings.modifiedAt = Date()
                }
                else
                {
                    let newSettings = AppSettings(dailyStudyGoalMinutes: tempGoalMinutes)
                    modelContext.insert(newSettings)
                    settings = newSettings
                }

                // Insert a GoalChange snapshot
                let snapshot = GoalChange(minutes: tempGoalMinutes, effectiveAt: startOfToday, settings: settings)
                modelContext.insert(snapshot)

                try? modelContext.save()
                showingGoalPicker = false
            }
        }
    }
}

struct SemiRing: Shape
{
    func path(in rect: CGRect) -> Path
    {
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

struct GoalMinutesPickerSheet: View {
    @Binding var selectedMinutes: Int
    var onDone: () -> Void

    private let range = Array(1...240)

    var body: some View
    {
        NavigationStack
        {
            VStack(spacing: 0)
            {
                // Wheel-style picker
                Picker("Minutes", selection: $selectedMinutes)
                {
                    ForEach(range, id: \.self)
                    { minute in
                        Text("\(minute)")
                            .font(.title2)
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .navigationTitle("Daily Study Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar
            {
                ToolbarItem(placement: .topBarTrailing)
                {
                    Button("Done")
                    {
                        onDone()
                    }
                }
            }
        }
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
    }
}

#Preview("Dark")
{
    @Previewable @Environment(\.modelContext) var context
    StreakView()
        .environmentObject(TimerModel(context: context))
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    @Previewable @Environment(\.modelContext) var context
    StreakView()
        .environmentObject(TimerModel(context: context))
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
}
