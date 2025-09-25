//
//  StopwatchView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 26-08-25.
//

import SwiftUI
import SwiftData

struct TimerView: View
{
    @Query(sort: \Topic.name) private var topics: [Topic]
    // No se esta usando en esta vista por ahora, ya que se esta persistiendo desde el modelo TimerModel
    @EnvironmentObject private var timer: TimerModel
    @State private var selectedTopic: Topic? = nil
    @State private var isPresentingTopicSheet: Bool = false
    @State private var draftSelectedTopic: Topic? = nil

    var body: some View
    {
        GeometryReader
        { geo in

            VStack
            {
                Spacer()

                TimelineView(.animation)
                { timeline in
                    let now = timeline.date
                    let t = timer.displayTime(at: now)

                    TimerDialView(time: t)
                        .frame(width: min(geo.size.width, geo.size.height) * 0.9)

                    Text(timer.formatted(t))
                        .font(.system(size: 40, weight: .medium, design: .monospaced))
                        //.foregroundColor(.white)
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
                            selectedTopic = nil
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

#Preview("Dark")
{
    @Previewable @Environment(\.modelContext) var context

    TimerView()
        .environmentObject(TimerModel(context: context))
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    @Previewable @Environment(\.modelContext) var context

    TimerView()
        .environmentObject(TimerModel(context: context))
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
}
