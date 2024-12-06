//
//  TopicHistory.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 04-12-24.
//

import Foundation

/// Represents a record of time spent on a topic.
struct TopicHistory: Identifiable, Codable {
    /// The unique identifier for the history entry.
    let id: UUID
    /// The date of the topic session.
    var date: Date
    /// The duration of the session in minutes.
    var duration: Int
    
    /// Initializes a new topic history entry with the given date and duration.
    /// - Parameters:
    ///   - id: The unique identifier for the history entry.
    ///   - date: The date of the topic session.
    ///   - duration: The duration of the session in minutes.
    init(
        id: UUID = UUID(),
        date: Date,
        duration: Int
    ) {
        self.id = id
        self.date = date
        self.duration = duration
    }
}
