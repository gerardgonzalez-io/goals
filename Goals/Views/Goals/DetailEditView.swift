//
//  DetailEditView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 21-01-25.
//

import SwiftUI

struct DetailEditView: View {
    @Binding var topic: Topic

    var body: some View {
        Form {
            Section(header: Text("Topic Info")) {
                TextField("Name", text: $topic.name)
                HStack {
                    Slider(value: $topic.goal.dailyMinutesGoal, in: 5...200, step: 1) {
                        Text("Length")
                    }
                    Spacer()
                    Text("\(Int(topic.goal.dailyMinutesGoal)) minutes")
                }
                ThemePicker(selection: $topic.theme)
            }
        }
    }
}

#Preview {
    let timeSpend = TimeSpend(dailyMinutesSpend: 23)
    let topicGoal = TopicGoal(dailyMinutesGoal: 60)
    let topic = Topic(
        name: "Programming",
        goal: topicGoal,
        timeSpend: timeSpend,
        theme: .goldenYellow
    )
    DetailEditView(topic: .constant(topic))
}
