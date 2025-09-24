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
    
    /// Sample data for previews, tests, or prototyping.
    static let sampleData: [StudySession] = {
        let topics = Topic.sampleData
        let now = Date()
        // Create some sessions in the recent past with reasonable durations
        return [
            StudySession(
                topic: topics[0],
                startDate: now.addingTimeInterval(-60 * 60 * 2),   // 2 hours ago
                endDate:   now.addingTimeInterval(-60 * 60 * 1),   // 1 hour ago
                notes: "Morning focus session"
            ),
            StudySession(
                topic: topics[0],
                startDate: now.addingTimeInterval(-60 * 60 * 5),   // 5 hours ago
                endDate:   now.addingTimeInterval(-60 * 60 * 3),   // 3 hours ago
                notes: "Reading and practice"
            ),
            StudySession(
                topic: topics[2],
                startDate: now.addingTimeInterval(-60 * 30 - 60 * 60 * 24), // 24h 30m ago
                endDate:   now.addingTimeInterval(-60 * 60 * 24),           // 24h ago
                notes: "Short review"
            ),
            StudySession(
                topic: topics[0],
                startDate: now.addingTimeInterval(-60 * 60 * 26),  // 26 hours ago
                endDate:   now.addingTimeInterval(-60 * 60 * 24),  // 24 hours ago
                notes: "Grammar drills"
            ),
            StudySession(
                topic: topics[4],
                startDate: now.addingTimeInterval(-60 * 60 * 50),  // ~2 days + 2 hours ago
                endDate:   now.addingTimeInterval(-60 * 60 * 48),  // ~2 days ago
                notes: "UI prototyping"
            ),
            StudySession(
                topic: topics[5],
                startDate: now.addingTimeInterval(-60 * 20),       // 20 minutes ago
                endDate:   now,                                    // now
                notes: "Quick kata"
            )
        ]
    }()
}
