//
//  GoalDetail.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 06-12-24.
//

import SwiftUI

struct GoalDetail: View {
    @Binding var topic: Topic
    @State private var editingTopic = Topic.emptyTopic
    @State private var isPresentingEditView = false

    var body: some View {
        List {
            Section(header: Text("Focus session info")){
                NavigationLink {
                    FocusSessionView(topic: $topic)
                } label: {
                    Label("Start focus session", systemImage: "timer")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                HStack {
                    Label("Daily goal", systemImage: "clock")
                    Spacer()
                    Text(String("\(Int(topic.goal.dailyMinutesGoal)) minutes"))
                }
                HStack {
                    Label("Time spend", systemImage: "hourglass")
                    Spacer()
                    Text(String("\(Int(topic.timeSpend.dailyMinutesSpend)) minutes"))
                }
                HStack {
                    Label("Theme", systemImage: "paintpalette")
                    Spacer()
                    Text(topic.theme.name)
                        .padding(4)
                        .foregroundColor(topic.theme.accentColor)
                        .background(topic.theme.mainColor)
                        .cornerRadius(4)
                }
            }
            
            Section(header: Text("History")) {
                if topic.history.isEmpty {
                    Label("No focus sessions yet", systemImage: "calendar.badge.exclamationmark")
                }
                ForEach(topic.history) { history in
                    HStack {
                        Image(systemName: "calendar")
                        Text(history.date, style: .date)
                    }
                }
            }
        }
        .navigationTitle(topic.name)
        .toolbar {
            Button("Edit") {
                isPresentingEditView = true
                editingTopic = topic
            }
        }
        .sheet(isPresented: $isPresentingEditView) {
            NavigationStack {
                DetailEditView(topic: $editingTopic)
                    .navigationTitle(topic.name)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isPresentingEditView = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isPresentingEditView = false
                                topic = editingTopic
                            }
                        }
                    }
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
        theme: .goldenyellow
    )
    GoalDetail(topic: .constant(topic))
}
