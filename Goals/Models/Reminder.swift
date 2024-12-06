//
//  Reminder.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 04-12-24.
//

import SwiftUI

/// Represents a scheduled reminder for a topic.
struct Reminder: Identifiable, Codable {
    /// The unique identifier for the reminder.
    let id: UUID
    /// The scheduled time for the reminder.
    var time: Date
    /// Indicates whether the reminder is enabled.
    var isEnabled: Bool
    
    /// Initializes a new reminder with the given time and enabled status.
    /// - Parameters:
    ///   - id: The unique identifier for the reminder.
    ///   - time: The scheduled time for the reminder.
    ///   - isEnabled: Whether the reminder is enabled.
    init(
        id: UUID = UUID(),
        time: Date,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.time = time
        self.isEnabled = isEnabled
    }
}
