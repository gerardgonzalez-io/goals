//
//  Topic.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 26-08-25.
//

import Foundation
import SwiftData

@Model
class Topic: Identifiable
{
    var id: UUID
    var name: String

    @Relationship(deleteRule: .cascade, inverse: \StudySession.topic)
    var studySessions: [StudySession] = []

    init(name: String, studySessions: [StudySession] = [])
    {
        self.id = UUID()
        self.name = name
        self.studySessions = studySessions
    }
}

extension Topic
{
    static let sampleData = [
        Topic(name: "iOS"),
        Topic(name: "Swift"),
        Topic(name: "Electronic"),
        Topic(name: "Japanese"),
        Topic(name: "SwiftUI"),
        Topic(name: "C languange"),
    ]
}
