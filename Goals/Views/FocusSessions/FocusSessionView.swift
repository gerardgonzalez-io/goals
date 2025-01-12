//
//  FocusSessionView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-12-24.
//

import SwiftUI

struct FocusSessionView: View {
    let topic: Topic
    @StateObject var focusSession = FocusSession()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16.0)
                .fill(topic.theme.mainColor)
            VStack {
                FocusSessionHeaderView(secondsElapsed: focusSession.secondsElapsed, secondsRemaining: focusSession.secondsRemaining, theme: topic.theme)
                FocusSessionTimerView(focusSession: focusSession, theme: topic.theme)
            }
        }
        .padding()
        .foregroundColor(topic.theme.accentColor)
        .onAppear {
            startFocusSession()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func startFocusSession() {
        focusSession.reset(durationInMinutes: Int(topic.goal.dailyMinutesGoal), topic: topic)
        focusSession.start()
    }
}

#Preview {
    let topics = TopicManager().topics
    FocusSessionView(topic: topics[0])
}
