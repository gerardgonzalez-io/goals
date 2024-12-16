//
//  TimeSpend.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 09-12-24.
//

import Foundation

/// Represents the time spend studying a topic.
struct TimeSpend: Codable {
    /// The daily time spend in a topic in minutes.
    var dailyMinutesSpend: Double
    
    /// Initializes a new time spend in minutes.
    /// - Parameter dailyMinutesSpend: The daily time spend in minutes.
    init(dailyMinutesSpend: Double) {
        self.dailyMinutesSpend = dailyMinutesSpend
    }
}
