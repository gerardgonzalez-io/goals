//
//  TimerView.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-10-25.
//

import SwiftUI
import SwiftData

struct TimerView: View
{
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @Query(sort: \Topic.name) private var topics: [Topic]

    @State private var timer = Timer()
    @State private var selectedTopic: Topic? = nil
    @State private var isPresentingTopicSheet: Bool = false
    @State private var draftSelectedTopic: Topic? = nil
    @State private var sessionStartDate: Date? = nil

    var body: some View
    {
        GeometryReader
        { geo in

            VStack
            {
                Spacer()

                Group
                {
                    let t = timer.displayTime()

                    TimerDialView(time: t)
                        .frame(width: min(geo.size.width, geo.size.height) * 0.9)

                    Text(timer.formatted(t))
                        .font(.system(size: 40, weight: .medium, design: .monospaced))
                        .padding(.top, 12)
                }
                
                // Settings-style row to select a Topic (like "When Timer Ends >")
                Button
                {
                    draftSelectedTopic = selectedTopic
                    isPresentingTopicSheet = true
                }
                label:
                {
                    HStack(spacing: 12)
                    {
                        Text(selectedTopic?.name ?? "Select topic")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.vertical, 32)
                
                Spacer()

                HStack
                {
                    
                    // Done button: marks the session done for the topic
                    let doneEnabled = timer.elapsed > 0 && selectedTopic != nil
                    
                    Button
                    {
                        if let topic = selectedTopic
                        {
                            timer.done(for: topic)
                            createAndPersistSession(for: topic)
                            selectedTopic = nil
                            sessionStartDate = nil
                        }
                    }
                    label:
                    {
                        Circle()
                            .fill(doneEnabled ? Color("EmeraldGreen") : Color(.secondarySystemFill))
                            .frame(width: 96, height: 96)
                            .overlay(
                                Text("Done")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(doneEnabled ? Color.white : Color.secondary)
                            )
                    }
                    .disabled(!doneEnabled)

                    Spacer()
                    
                    // Start/Pause/Resume button: toggles the timer running state
                    let startEnabled = selectedTopic != nil
                    Button
                    {
                        createStartDateForSession()
                        timer.toggle()
                    }
                    label:
                    {
                        Circle()
                            .fill(!startEnabled ? Color(.secondarySystemFill) : (timer.isRunning ? Color.accentColor : Color("EmeraldGreen")))
                            .frame(width: 96, height: 96)
                            .overlay(
                                Text(timer.isRunning ? "Pause" : (timer.elapsed == 0 ? "Start" : "Resume"))
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(!startEnabled ? Color.secondary : Color.white)
                            )
                    }
                    .disabled(!startEnabled)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                
                Spacer()
            }
        }
        .sheet(isPresented: $isPresentingTopicSheet)
        {
            NavigationStack
            {
                List
                {
                    ForEach(topics)
                    { topic in
                        HStack
                        {
                            Text(topic.name)
                            Spacer()
                            if draftSelectedTopic?.persistentModelID == topic.persistentModelID
                            {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture
                        {
                            draftSelectedTopic = topic
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Select Topic")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar
                {
                    ToolbarItem(placement: .cancellationAction)
                    {
                        Button
                        {
                            isPresentingTopicSheet = false
                        }
                        label:
                        {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction)
                    {
                        Button("Set")
                        {
                            selectedTopic = draftSelectedTopic
                            isPresentingTopicSheet = false
                        }
                        .disabled(draftSelectedTopic == nil)
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }
            .presentationDetents([.medium, .large])
        }
    }
}

extension TimerView
{
    private func createStartDateForSession()
    {
        if !timer.isRunning && timer.elapsed == 0
        {
            var calendarWithTimeZone = Calendar.current
            calendarWithTimeZone.timeZone = .current
            let now = Date()
            let normalizedStart = calendarWithTimeZone.date(bySetting: .nanosecond, value: 0, of: now) ?? now
            sessionStartDate = normalizedStart
        }
    }

    private func createAndPersistSession(for topic: Topic)
    {
        guard let capturedStart = sessionStartDate
        else
        {
            return
        }

        guard let goal = goals.last
        else
        {
            return
        }

        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = .current

        let now = Date()
        let normalizedEnd = calendarWithTimeZone.date(bySetting: .nanosecond, value: 0, of: now) ?? now

        let session = StudySession(topic: topic,
                                   goal: goal,
                                   startDate: capturedStart,
                                   endDate: normalizedEnd)
        
        modelContext.insert(session)

        do
        {
            try modelContext.save()
        }
        catch
        {
            #if DEBUG
            print("Failed to save StudySession: \(error)")
            #endif
        }
    }
}

#Preview("Dark")
{
    TimerView()
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    TimerView()
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
}
