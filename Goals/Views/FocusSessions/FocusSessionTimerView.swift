//
//  FocusSessionTimerView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-12-24.
//

import SwiftUI

struct FocusSessionTimerView: View {

    let focusSession: FocusSession
    let theme: Theme
    let topic: Topic

    var body: some View {
        Circle()
            .strokeBorder(lineWidth: 24)
            .overlay {
                VStack {
                    Text(topic.name)
                        .font(.title)
                    Text("Focus session")
                }
                .foregroundStyle(theme.accentColor)
            }
            .overlay {
                ForEach(0..<Int(focusSession.timeSpend.dailyMinutesSpend), id: \.self) { timeSpend in
                    MinutesArc(minuteIndex: timeSpend, totalMinutes: focusSession.durationInMinutes)
                        .rotation(Angle(degrees: -90))
                        .stroke(theme.mainColor, lineWidth: 12)
                }
            }
            .padding(.horizontal)
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
    
    let focusSession = FocusSession(topic: topic, durationInMinutes: 60, timeSpend: timeSpend)
    FocusSessionTimerView(focusSession: focusSession, theme: .goldenYellow, topic: topic)
}
