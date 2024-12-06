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
    /// The scheduled reminders for the topic.
    var reminders: [Reminder]
    /// The history of time spent on the topic.
    var history: [TopicHistory]

    /// Initializes a new topic with the given parameters.
    /// - Parameters:
    ///   - id: The unique identifier for the topic.
    ///   - name: The name of the topic.
    ///   - description: A description or additional details about the topic.
    ///   - goal: The goal associated with the topic.
    ///   - reminders: The scheduled reminders for the topic.
    ///   - history: The history of time spent on the topic.
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        goal: TopicGoal,
        reminders: [Reminder] = [],
        history: [TopicHistory] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.goal = goal
        self.reminders = reminders
        self.history = history
    }
}
