//
//  Topic.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 04-12-24.
//

import SwiftUI

/// Represents a study topic or topic that the user wants to track.
struct Topic: Identifiable, Codable {
    /// The unique identifier for the topic.
    let id: UUID
    /// The name of the topic.
    var name: String
    /// A description or additional details about the topic.
    var description: String?
    /// The time goal associated with the topic.
    var goal: TopicGoal
    /// The time spend studying the topic.
    var timeSpend: TimeSpend
    /// The scheduled reminders for the topic.
    var reminders: [Reminder]
    /// The history of time spent on the topic.
    var history: [TopicHistory]
    /// Theme of the row list of the topics.
    var theme: Theme
    /// Track when we last "reset" or used the daily goal time.
    var lastDailyReset: Date

    /// Initializes a new topic with the given parameters.
    /// - Parameters:
    ///   - id: The unique identifier for the topic.
    ///   - name: The name of the topic.
    ///   - description: A description or additional details about the topic.
    ///   - goal: The goal associated with the topic.
    ///   - timeSpend: The time spend in a topic.
    ///   - reminders: The scheduled reminders for the topic.
    ///   - history: The history of time spent on the topic.
    init(
        id: UUID = UUID(),
        name: String = "",
        description: String? = nil,
        goal: TopicGoal = TopicGoal(dailyMinutesGoal: 0),
        timeSpend: TimeSpend = TimeSpend(dailyMinutesSpend: 0),
        reminders: [Reminder] = [],
        history: [TopicHistory] = [],
        theme: Theme = .kingblue,
        lastDailyReset: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.goal = goal
        self.timeSpend = timeSpend
        self.reminders = reminders
        self.history = history
        self.theme = theme
        self.lastDailyReset = lastDailyReset
    }
}

extension Topic {
    static var emptyTopic: Topic {
        let timeSpend = TimeSpend(dailyMinutesSpend: 0)
        let topicGoal = TopicGoal(dailyMinutesGoal: 0)

        let topic = Topic(
            name: "",
            goal: topicGoal,
            timeSpend: timeSpend,
            theme: .goldenYellow
        )
        return topic
    }
}

extension Topic {
    static let sampleData = [
        Topic(
            name: "Programming",
            goal: TopicGoal(dailyMinutesGoal: 60),
            timeSpend: TimeSpend(dailyMinutesSpend: 10),
            theme: .goldenYellow
        ),
        Topic(
            name: "C Language",
            goal: TopicGoal(dailyMinutesGoal: 60),
            timeSpend: TimeSpend(dailyMinutesSpend: 40),
            theme: .goldenYellow
        ),
        Topic(
            name: "Japanese",
            goal: TopicGoal(dailyMinutesGoal: 60),
            timeSpend: TimeSpend(dailyMinutesSpend: 57),
            theme: .goldenYellow
        )
    ]
}
