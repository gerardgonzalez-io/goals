//
//  NewTopicView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 26-08-25.
//

import SwiftUI
import SwiftData

struct NewTopicView: View
{
    @Bindable private var topic: Topic
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    init(topic: Topic)
    {
        self.topic = topic
    }

    var body: some View
    {
        Form
        {
            TextField("Topic name", text: $topic.name)
                .autocorrectionDisabled()
        }
        .navigationTitle("New Topic")
        .toolbar
        {
            ToolbarItem(placement: .confirmationAction)
            {
                Button("Save")
                {
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction)
            {
                Button("Cancel")
                {
                    context.delete(topic)
                    dismiss()
                }
            }
        }
    }
}

#Preview
{
    NavigationStack
    {
        NewTopicView(topic: SampleData.shared.topic)
    }
}
