//
//  StudySession+Samples.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 25-12-25.
//

import Foundation

extension StudySession
{
    /// Sample data for previews, tests, or prototyping.
    static let sampleData: [StudySession] =
    {
        let topics = Topic.sampleData

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
                startDate: twoDaysAgoStart.addingTimeInterval(-4 * 60),
                endDate:   twoDaysAgoStart
            ),
            // 3 days ago: 30 minutes 30 seconds session ending exactly at start of that day
            StudySession(
                topic: topics[3],
                startDate: threeDaysAgoStart.addingTimeInterval(-(30 * 60 + 30)),
                endDate:   threeDaysAgoStart
            ),
            // Duplicate of the previous session (as in original sample data)
            StudySession(
                topic: topics[3],
                startDate: threeDaysAgoStart.addingTimeInterval(-(30 * 60 + 30)),
                endDate:   threeDaysAgoStart
            ),
            // 5 days ago: 2 minutes 45 seconds session ending exactly at start of that day
            StudySession(
                topic: topics[5],
                startDate: fiveDaysAgoStart.addingTimeInterval(-(2 * 60 + 45)),
                endDate:   fiveDaysAgoStart
            ),
            // Today: a 30-minute session ending at 'now'
            StudySession(
                topic: topics[1],
                startDate: now.addingTimeInterval(-70 * 60),
                endDate:   now
            )
        ]
    }()
}
