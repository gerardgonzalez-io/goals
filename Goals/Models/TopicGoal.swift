//
//  TopicGoal.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 04-12-24.
//

import Foundation

/// Represents the goal associated with a topic.
struct TopicGoal: Codable {
    /// The daily time goal in minutes.
    var dailyMinutesGoal: Double
    
    /// Initializes a new topic goal with the given daily time goal in minutes.
    /// - Parameter dailyTimeGoal: The daily time goal in minutes.
    init(dailyMinutesGoal: Double) {
        self.dailyMinutesGoal = dailyMinutesGoal
    }
}
