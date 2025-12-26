//
//  TopicGoal.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 24-12-25.
//

import SwiftUI
import SwiftData

struct TopicGoal: View
{
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let topic: Topic

    @State private var selectedMinutes: Int
    @State private var errorMessage: String?

    private let minuteRange = Array(1...240)

    init(topic: Topic)
    {
        self.topic = topic
        _selectedMinutes = State(initialValue: topic.currentGoalInMinutes ?? 60)
    }

    private var currentMinutes: Int?
    {
        topic.currentGoalInMinutes
    }

    private var canSave: Bool
    {
        guard selectedMinutes > 0 else { return false }
        // Avoid "duplicate" snapshots where the goal didn't actually change.
        if let currentMinutes, currentMinutes == selectedMinutes { return false }
        return true
    }

    var body: some View
    {
        Form
        {
            Section
            {
                VStack(alignment: .leading, spacing: 10)
                {
                    HStack
                    {
                        Text("Daily goal")
                            .font(.headline)

                        Spacer()

                        Text("\(selectedMinutes) min")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Minutes", selection: $selectedMinutes)
                    {
                        ForEach(minuteRange, id: \.self) { minute in
                            Text("\(minute)")
                                .font(.title2)
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                    .clipped()
                    .overlay(alignment: .trailing)
                    {
                        Text("min")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 12)
                    }

                    Text("Changes you make here apply starting today. Past days will keep the goal that was active on those dates.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            footer:
            {
                if let currentMinutes
                {
                    Text(currentMinutes == selectedMinutes
                         ? "Pick a different goal to save a new change."
                         : "Your current goal is \(currentMinutes) min.")
                }
                else
                {
                    Text("Pick a goal to start tracking this topic.")
                }
            }

            if let errorMessage
            {
                Section
                {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            if !topic.goalChanges.isEmpty
            {
                Section("History")
                {
                    // Newest first: day, then exact time
                    let sorted = topic.goalChanges.sorted
                    {
                        if $0.effectiveFromDay != $1.effectiveFromDay
                        {
                            return $0.effectiveFromDay > $1.effectiveFromDay
                        }
                        return $0.effectiveAt > $1.effectiveAt
                    }

                    ForEach(sorted)
                    { change in
                        HStack
                        {
                            Text(change.effectiveFromDay, style: .date)
                                .foregroundStyle(.primary)

                            Spacer()

                            Text("\(change.goalInMinutes) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar
        {
            ToolbarItem(placement: .topBarTrailing)
            {
                Button("Save")
                {
                    saveSnapshot()
                }
                .disabled(!canSave)
            }
        }
    }

    private func saveSnapshot()
    {
        errorMessage = nil
        guard canSave else
        {
            // Friendly message if user tries to save the same goal.
            if let currentMinutes, currentMinutes == selectedMinutes
            {
                errorMessage = "That’s already your current goal."
            }
            return
        }

        // IMPORTANT: use the real timestamp so multiple changes in the same day are deterministic.
        let now = Date()

        let change = TopicGoalChange(
            topic: topic,
            goalInMinutes: selectedMinutes,
            effectiveAt: now
        )

        // Ensure relationship is set even without relying on inverse inference
        topic.goalChanges.append(change)
        context.insert(change)

        do
        {
            try context.save()
            dismiss()
        }
        catch
        {
            #if DEBUG
            print("Failed to save TopicGoalChange: \(error)")
            #endif
            errorMessage = "Couldn't save. Please try again."
        }
    }
}

#Preview
{
    NavigationStack
    {
        TopicGoal(topic: SampleData.shared.topic)
            .modelContainer(SampleData.shared.modelContainer)
    }
}
