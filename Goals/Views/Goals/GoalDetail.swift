//
//  GoalDetail.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 06-12-24.
//

import SwiftUI

struct GoalDetail: View {
    let topic: Topic

    var body: some View {
        List {
            Section(header: Text("Focus session info")){
                NavigationLink {
                    FocusSessionView(topic: topic)
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
    }
}

#Preview {
    let topics = TopicManager().topics
    GoalDetail(topic: topics[0])
}
