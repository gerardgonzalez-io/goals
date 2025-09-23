//
//  StudySession.swift
//  Goals
//
//  Created by Assistant on 19-09-25.
//
//  This model represents a single study event (a "session") tied to a Topic.
//  It is the source of truth for time tracking. Daily and total times are
//  computed by aggregating sessions rather than storing denormalized totals
//  on Topic. This follows Apple's guidance to keep entities cohesive and use
//  relationships for derived data.

import Foundation
import SwiftData

@Model
final class StudySession
{
    /// The topic this session belongs to.
    var topic: Topic

    /// When the session started.
    var startDate: Date

    /// When the session ended.
    var endDate: Date

    /// Convenience computed duration in seconds.
    var duration: TimeInterval { endDate.timeIntervalSince(startDate) }

    /// Optional notes or metadata about the session.
    var notes: String?

    /// Timestamps for auditing or sorting (optional but useful).
    var createdAt: Date
    var modifiedAt: Date

    /// Designated initializer.
    init(topic: Topic, startDate: Date, endDate: Date, notes: String? = nil, createdAt: Date = Date(), modifiedAt: Date = Date())
    {
        self.topic = topic
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
