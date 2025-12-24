//
//  Goal.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-10-25.
//

import Foundation
import SwiftData

@Model
class Goal
{
    var createdAt: Date
    
    var goalInMinutes: Int

    var goalInSeconds: Int
    {
        goalInMinutes * 60
    }

    var goalInHours: Int
    {
        goalInMinutes / 60
    }

    init(goalInMinutes: Int, createdAt: Date = Date())
    {
        self.goalInMinutes = goalInMinutes
        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = .current
        let normalized = calendarWithTimeZone.startOfDay(for: createdAt)
        self.createdAt = normalized
    }
}

extension Goal
{
    static let sampleData = [
        Goal(goalInMinutes: 60),
    ]
}
