//
//  NewTopicView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI
import SwiftData

struct NewTopicView: View
{
    @Bindable private var topic: Topic
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var selectedMinutes: Int

    private let minuteRange = Array(1...240)

    init(topic: Topic)
    {
        self.topic = topic
        _selectedMinutes = State(initialValue: topic.currentGoalInMinutes ?? 60)
    }

    private var trimmedName: String
    {
        topic.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool
    {
        !trimmedName.isEmpty && selectedMinutes > 0
    }

    var body: some View
    {
        Form
        {
            Section
            {
                TextField("Topic name", text: $topic.name)
                    .autocorrectionDisabled()
            }

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
                }
            }
            footer:
            {
                Text("Set how many minutes you want to study for this topic each day. You can change it later, and past days will keep their original goal.")
            }
        }
        .navigationTitle("New Topic")
        .toolbar
        {
            ToolbarItem(placement: .confirmationAction)
            {
                Button("Save")
                {
                    save()
                }
                .disabled(!canSave)
            }

            ToolbarItem(placement: .cancellationAction)
            {
                Button("Cancel")
                {
                    context.delete(topic)
                    do { try context.save() } catch { }
                    dismiss()
                }
            }
        }
    }

    private func save()
    {
        topic.name = trimmedName
        guard canSave else { return }

        // Create initial snapshot (required)
        if topic.goalChanges.isEmpty
        {
            let change = TopicGoalChange(
                topic: topic,
                goalInMinutes: selectedMinutes,
                effectiveAt: Date()
            )
            topic.goalChanges.append(change)
            context.insert(change)
        }

        do
        {
            try context.save()
        }
        catch
        {
            #if DEBUG
            print("Failed to save Topic / TopicGoalChange: \(error)")
            #endif
        }

        dismiss()
    }
}

#Preview
{
    NavigationStack
    {
        NewTopicView(topic: SampleData.shared.topic)
    }
}
