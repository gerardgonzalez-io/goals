//
//  Topic.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 26-08-25.
//

import Foundation
import SwiftData

@Model
class Topic: Identifiable
{
    var id: UUID
    var name: String
    
    /// Convenience: current goal as of "today" (startOfDay).
    var currentGoalInMinutes: Int?
    {
        goalInMinutes(for: Date())
    }

    /// Goal history (snapshots). The latest applicable change determines the goal for that day.
    @Relationship(deleteRule: .cascade)
    var goalChanges: [TopicGoalChange] = []

    @Relationship(deleteRule: .cascade, inverse: \StudySession.topic)
    var studySessions: [StudySession] = []

    init(name: String, studySessions: [StudySession] = [])
    {
        self.id = UUID()
        self.name = name
        self.studySessions = studySessions
    }
}

extension Topic
{
    /// Returns the goal (minutes) that was active for a given day (uses startOfDay).
    /// - If no changes exist up to that day, returns nil.
    ///
    /// Note:
    /// - Multiple changes can happen on the same day.
    /// - We choose the latest change by `effectiveAt` among all changes whose `effectiveFromDay` is <= target day.
    func goalInMinutes(for day: Date) -> Int?
    {
        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = .current
        let targetDay = calendarWithTimeZone.startOfDay(for: day)

        // Pick the latest change (by effectiveAt) among all changes applicable up to targetDay.
        let applicable = goalChanges
            .filter { $0.effectiveFromDay <= targetDay }
            .sorted
            {
                if $0.effectiveFromDay != $1.effectiveFromDay
                {
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
