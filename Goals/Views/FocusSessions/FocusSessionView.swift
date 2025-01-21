//
//  FocusSessionView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-12-24.
//

import SwiftUI

struct FocusSessionView: View {
    @Binding var topic: Topic
    @StateObject var focusSession = FocusSession()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16.0)
                .fill(topic.theme.mainColor)
            VStack {
                FocusSessionHeaderView(secondsElapsed: focusSession.secondsElapsed, secondsRemaining: focusSession.secondsRemaining, theme: topic.theme)
                FocusSessionTimerView(focusSession: focusSession, theme: topic.theme, topic: topic)
            }
        }
        .padding()
        .foregroundColor(topic.theme.accentColor)
        .onAppear {
            startFocusSession()
        }
        .onDisappear {
            endFocusSession()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func startFocusSession() {
        // 1) Calculate how many minutes are left from the daily goal
        //    after subtracting what's already been spent.
        //    Use 'max' to avoid negative numbers if the user has
        //    already exceeded the goal.
        let focusSessionDuration = max(0, topic.goal.dailyMinutesGoal - topic.timeSpend.dailyMinutesSpend)
        focusSession.reset(durationInMinutes: Int(focusSessionDuration), topic: topic)
        focusSession.start()
    }
    
    private func endFocusSession() {
        focusSession.stop()
        topic.timeSpend.dailyMinutesSpend += focusSession.timeSpend.dailyMinutesSpend
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
    FocusSessionView(topic: .constant(topic))
}
