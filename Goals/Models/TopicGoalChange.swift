//
//  TopicGoalChange.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 24-12-25.
//

import Foundation
import SwiftData

@Model
final class TopicGoalChange: Identifiable
{
    var id: UUID

    /// Start-of-day (normalized) from which this goal is considered active.
    var effectiveFromDay: Date

    /// Snapshot value (do NOT reference a mutable Goal object).
    var goalInMinutes: Int

    @Relationship(inverse: \Topic.goalChanges)
    var topic: Topic

    init(topic: Topic, goalInMinutes: Int, effectiveFromDay: Date = Date())
    {
        self.id = UUID()
        self.topic = topic
        self.goalInMinutes = goalInMinutes

        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = .current
        self.effectiveFromDay = calendarWithTimeZone.startOfDay(for: effectiveFromDay)
    }
}
