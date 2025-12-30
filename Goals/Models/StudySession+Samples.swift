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

        // Helper to get the normalized start of a day relative to today
        func day(_ offset: Int) -> Date
        {
            calendarWithTimeZone.startOfDay(
                for: calendarWithTimeZone.date(byAdding: .day, value: offset, to: startOfToday)!
            )
        }

        // Helper to create a session with a start hour (avoid midnight edge cases)
        func makeSession(topic: Topic, dayOffset: Int, hour: Int, minutes: Int) -> StudySession
        {
            let start = day(dayOffset).addingTimeInterval(TimeInterval(hour * 3600))
            let end = start.addingTimeInterval(TimeInterval(minutes * 60))
            return StudySession(topic: topic, startDate: start, endDate: end)
        }

        // Topic.sampleData indices:
        // 0 iOS, 1 Swift, 2 Electronic, 3 Japanese, 4 SwiftUI, 5 C languange

        return [
            // iOS — last 7 days (so Progress vs Plan has movement)
            makeSession(topic: topics[0], dayOffset: -6, hour: 9,  minutes: 10),
            makeSession(topic: topics[0], dayOffset: -5, hour: 9,  minutes: 20),
            makeSession(topic: topics[0], dayOffset: -4, hour: 9,  minutes: 40),
            makeSession(topic: topics[0], dayOffset: -3, hour: 9,  minutes: 150),
            makeSession(topic: topics[0], dayOffset: -2, hour: 9,  minutes: 40),
            makeSession(topic: topics[0], dayOffset: -1, hour: 20, minutes: 40),
            makeSession(topic: topics[0], dayOffset:  0, hour: 8,  minutes: 40),

            // Extra sessions for other screens/topics
            makeSession(topic: topics[4], dayOffset: -2, hour: 10, minutes: 50), // SwiftUI
            makeSession(topic: topics[3], dayOffset: -4, hour: 18, minutes: 35)  // Japanese
        ]
    }()
}
