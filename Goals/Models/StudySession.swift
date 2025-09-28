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

        return [
            // 1) Hoy: duración 20 minutos.
            //    Explicación: "Hoy se guardó una sesión y duró 20m".
            StudySession(
                topic: topics[0],
                startDate: now.addingTimeInterval(-20 * 60),      // hoy: empezó hace 20m
                endDate:   now,                                   // hoy: terminó ahora
                notes: "Sesión de enfoque (20m)"
            ),

            // 2) Ayer: duración 20 minutos.
            //    Explicación: "Ayer se guardó una sesión y duró 20m".
            StudySession(
                topic: topics[1],
                startDate: now.addingTimeInterval(-24 * 60 * 60 - 2 * 60), // ayer: 24h + 20m atrás
                endDate:   now.addingTimeInterval(-24 * 60 * 60),            // ayer: hace 24h
                notes: "Repaso ligero (20m)"
            ),

            // 3) Antes de ayer: duración < 5 minutos (4m).
            //    Explicación: "Antes de ayer se guardó una sesión y duró 4m".
            StudySession(
                topic: topics[2],
                startDate: now.addingTimeInterval(-48 * 60 * 60 - 4 * 60),   // 48h + 4m atrás
                endDate:   now.addingTimeInterval(-48 * 60 * 60),            // 48h atrás
                notes: "Revisión muy corta (4m)"
            ),

            // 4) 3 días atrás: duración < 5 minutos (3m30s).
            //    Explicación: "Hace 3 días se guardó una sesión y duró 3m30s".
            StudySession(
                topic: topics[3],
                startDate: now.addingTimeInterval(-72 * 60 * 60 - (30 * 60 + 30)), // 72h + 3m30s atrás
                endDate:   now.addingTimeInterval(-72 * 60 * 60),                 // 72h atrás
                notes: "Micro sesión (3m30s)"
            ),

            // 5) 4 días atrás: duración < 5 minutos (3m).
            //    Explicación: "Hace 4 días se guardó una sesión y duró 3m".
            StudySession(
                topic: topics[4],
                startDate: now.addingTimeInterval(-96 * 60 * 60 - 3 * 60),   // 96h + 3m atrás
                endDate:   now.addingTimeInterval(-96 * 60 * 60),            // 96h atrás
                notes: "Micro práctica (3m)"
            ),

            // 6) 5 días atrás: duración < 5 minutos (2m45s).
            //    Explicación: "Hace 5 días se guardó una sesión y duró 2m45s".
            StudySession(
                topic: topics[5],
                startDate: now.addingTimeInterval(-120 * 60 * 60 - (2 * 60 + 45)), // 120h + 2m45s atrás
                endDate:   now.addingTimeInterval(-120 * 60 * 60),                  // 120h atrás
                notes: "Repaso express (2m45s)"
            ),

            // 7) 6 días atrás: duración < 5 minutos (2m30s).
            //    Explicación: "Hace 6 días se guardó una sesión y duró 2m30s".
            StudySession(
                topic: topics[0],
                startDate: now.addingTimeInterval(-144 * 60 * 60 - (2 * 60 + 30)), // 144h + 2m30s atrás
                endDate:   now.addingTimeInterval(-144 * 60 * 60),                  // 144h atrás
                notes: "Sesión breve (2m30s)"
            ),
        ]
    }()
}
