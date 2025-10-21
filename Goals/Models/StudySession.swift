//
//  StudySession.swift
//  Goals
//
//  Created by Assistant on 19-09-25.
//

import Foundation
import SwiftData

@Model
class StudySession
{
    var topic: Topic
    var goal: Goal
    var startDate: Date
    var endDate: Date

    /// Normalized start of day for this session's startDate using the current calendar and time zone.
    var normalizedDay: Date
    {
        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = TimeZone.current
        return calendarWithTimeZone.startOfDay(for: startDate)
    }

    var durationInMinutes: Int
    {
        let seconds = endDate.timeIntervalSince(startDate)
        if seconds <= 0 { return 0 }
        return Int((seconds / 60))
    }

    init(topic: Topic, goal: Goal, startDate: Date, endDate: Date)
    {
        self.topic = topic
        self.goal = goal
        self.startDate = startDate
        self.endDate = endDate
    }
}

extension StudySession
{
    /// Sample data for previews, tests, or prototyping.
    static let sampleData: [StudySession] = {
        let topics = Topic.sampleData
        let goal = Goal.sampleData.first!

        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = .current

        let now = Date()
        let startOfToday = calendarWithTimeZone.startOfDay(for: now)

        // Helper to get the normalized start of a past day
        func startOfDay(daysAgo: Int) -> Date
        {
            calendarWithTimeZone.date(byAdding: .day, value: -daysAgo, to: startOfToday)!
        }

        // Build sessions so that endDate aligns exactly with the normalized start of the day,
        // preserving the original relative durations.
        let twoDaysAgoStart = startOfDay(daysAgo: 2)
        let threeDaysAgoStart = startOfDay(daysAgo: 3)
        let fiveDaysAgoStart = startOfDay(daysAgo: 5)

        return [
            // 2 days ago: 4 minutes session ending exactly at start of that day
            StudySession(
                topic: topics[2],
                goal: goal,
                startDate: twoDaysAgoStart.addingTimeInterval(-4 * 60),
                endDate:   twoDaysAgoStart
            ),
            // 3 days ago: 30 minutes 30 seconds session ending exactly at start of that day
            StudySession(
                topic: topics[3],
                goal: goal,
                startDate: threeDaysAgoStart.addingTimeInterval(-(30 * 60 + 30)),
                endDate:   threeDaysAgoStart
            ),
            // Duplicate of the previous session (as in original sample data)
            StudySession(
                topic: topics[3],
                goal: goal,
                startDate: threeDaysAgoStart.addingTimeInterval(-(30 * 60 + 30)),
                endDate:   threeDaysAgoStart
            ),
            // 5 days ago: 2 minutes 45 seconds session ending exactly at start of that day
            StudySession(
                topic: topics[5],
                goal: goal,
                startDate: fiveDaysAgoStart.addingTimeInterval(-(2 * 60 + 45)),
                endDate:   fiveDaysAgoStart
            ),
            // Today: a 30-minute session ending at 'now'
            StudySession(
                topic: topics[1],
                goal: goal,
                startDate: now.addingTimeInterval(-70 * 60),
                endDate:   now
            )
        ]
    }()
}
