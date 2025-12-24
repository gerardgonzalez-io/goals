//
//  TopicGoalChange.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 24-12-25.
//

import Foundation
import SwiftData

/**
 Goal snapshots (TopicGoalChange) resolution

 Why we store two dates:
 - effectiveAt: the exact timestamp when the goal change was created (includes time).
 - effectiveFromDay: the normalized start-of-day for effectiveAt (used for day-based grouping/queries).

 How we resolve the goal for a given day:
 1) Normalize the requested date to targetDay = startOfDay(day).
 2) Consider only changes that were already active by that day:
      change.effectiveFromDay <= targetDay
 3) Pick the “latest” applicable change:
    - First by effectiveFromDay (newer day wins)
    - If multiple changes exist on the same day, break ties by effectiveAt (later time wins)

 This ensures:
 - Past days never get recalculated when the goal changes later.
 - Multiple goal changes in the same calendar day are deterministic: the last change of that day wins.
 */

@Model
final class TopicGoalChange: Identifiable
{
    var id: UUID

    /// Start-of-day (normalized) from which this goal is considered active.
    /// Used for day-based queries and grouping.
    var effectiveFromDay: Date

    /// Exact timestamp when this change was created/effective.
    /// Used to break ties when multiple changes happen on the same day.
    var effectiveAt: Date

    /// Snapshot value (do NOT reference a mutable Goal object).
    var goalInMinutes: Int

    @Relationship(inverse: \Topic.goalChanges)
    var topic: Topic

    init(topic: Topic, goalInMinutes: Int, effectiveAt: Date = Date())
    {
        self.id = UUID()
        self.topic = topic
        self.goalInMinutes = goalInMinutes

        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = .current

        self.effectiveAt = effectiveAt
        self.effectiveFromDay = calendarWithTimeZone.startOfDay(for: effectiveAt)
    }
}

/**
 Do we need both `effectiveAt` and `effectiveFromDay`?

 Not strictly.
 - Using ONLY `effectiveAt` (full timestamp) is enough to support the core rule:
   past days use the goal that was active that day (no recalculation).
   Example approach: pick the latest change where effectiveAt <= endOfDay(targetDay).

 Why keep `effectiveFromDay` anyway?
 - Convenience for day-based logic:
   - Easy grouping and display by calendar day.
   - Simpler, consistent day filters/queries.
   - Straightforward validation like “a change already exists today”.
 - It avoids repeating `startOfDay(...)` normalization across the app.

 In short:
 - Minimal model: `effectiveAt` only.
 - More convenient day-based model: `effectiveAt` + `effectiveFromDay`.
 */
