//
//  TopicGoalChange+Samples.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 29-12-25.
//

import Foundation

extension TopicGoalChange
{
    /// Sample data for previews, tests, or prototyping.
    static let sampleData: [TopicGoalChange] =
    {
        let topics = Topic.sampleData

        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = .current

        let now = Date()
        let startOfToday = calendarWithTimeZone.startOfDay(for: now)

        func day(_ offset: Int) -> Date
        {
            calendarWithTimeZone.startOfDay(
                for: calendarWithTimeZone.date(byAdding: .day, value: offset, to: startOfToday)!
            )
        }

        var changes: [TopicGoalChange] = []
        changes.reserveCapacity(6)

        func addGoalChange(topic: Topic, minutes: Int, effectiveDayOffset: Int)
        {
            let effectiveAt = day(effectiveDayOffset).addingTimeInterval(12 * 3600) // midday
            let g = TopicGoalChange(topic: topic, goalInMinutes: minutes, effectiveAt: effectiveAt)

            // Keep relationship consistent (same pattern you used before)
            topic.goalChanges.append(g)
            changes.append(g)
        }

        // Topic.sampleData indices (from your Topic+Samples.swift):
        // 0 iOS, 1 Swift, 2 Electronic, 3 Japanese, 4 SwiftUI, 5 C languange

        // iOS: 60m/day since 120d ago, then 90m/day since 10d ago, then 30m/day since 4d ago
        addGoalChange(topic: topics[0], minutes: 60, effectiveDayOffset: -120)
        addGoalChange(topic: topics[0], minutes: 90, effectiveDayOffset: -10)
        addGoalChange(topic: topics[0], minutes: 30, effectiveDayOffset: -4)

        // SwiftUI: 45m/day since 20d ago
        addGoalChange(topic: topics[4], minutes: 45, effectiveDayOffset: -20)

        // Japanese: 30m/day since 40d ago
        addGoalChange(topic: topics[3], minutes: 30, effectiveDayOffset: -40)

        return changes
    }()
}
