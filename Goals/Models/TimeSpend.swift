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
    var dailyTimeSpend: Double
    
    /// Initializes a new time spend in minutes.
    /// - Parameter dailyTimeSpend: The daily time spend in minutes.
    init(dailyTimeSpend: Double) {
        self.dailyTimeSpend = dailyTimeSpend
    }
}
