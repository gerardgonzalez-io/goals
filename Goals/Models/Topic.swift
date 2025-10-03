//
//  Topic.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 26-08-25.
//

import Foundation
import SwiftData

/// Topic is a domain entity representing a subject of study or interest.
/// Time tracking is modeled via related StudySession records rather than persisted total or daily time.
@Model
class Topic
{
    var name: String
    var id: UUID
    /// Sessions associated with this topic, representing study sessions for time tracking.
    var sessions: [StudySession] = []
    
    init(name: String)
    {
        self.id = UUID()
        self.name = name
    }
    
    static let sampleData = [
        Topic(name: "iOS"),
        Topic(name: "Swift"),
        Topic(name: "Electronic"),
        Topic(name: "Japanese"),
        Topic(name: "SwiftUI"),
        Topic(name: "C languange"),
    ]
}
