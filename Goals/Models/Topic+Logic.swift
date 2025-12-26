//
//  Topic+Logic.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 25-12-25.
//

import Foundation

extension Topic {
    /// Convenience: current goal as of "today" (startOfDay).
    var currentGoalInMinutes: Int? {
        goalInMinutes(for: Date())
    }

    /// Returns the goal (minutes) that was active for a given day (uses startOfDay).
    /// - If no changes exist up to that day, returns nil.
    ///
    /// Note:
    /// - Multiple changes can happen on the same day.
    /// - We choose the latest change by `effectiveAt` among all changes whose `effectiveFromDay` is <= target day.
    func goalInMinutes(for day: Date) -> Int? {
        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = .current
        let targetDay = calendarWithTimeZone.startOfDay(for: day)

        let applicable = goalChanges
            .filter { $0.effectiveFromDay <= targetDay }
            .sorted {
                if $0.effectiveFromDay != $1.effectiveFromDay {
                    return $0.effectiveFromDay < $1.effectiveFromDay
                }
                // Same day: break ties by exact time of change
                return $0.effectiveAt < $1.effectiveAt
            }
            .last

        return applicable?.goalInMinutes
    }
}

extension Topic
{
    static let sampleData = [
        Topic(name: "iOS"),
        Topic(name: "Swift"),
        Topic(name: "Electronic"),
        Topic(name: "Japanese"),
        Topic(name: "SwiftUI"),
        Topic(name: "C languange"),
    ]
}
