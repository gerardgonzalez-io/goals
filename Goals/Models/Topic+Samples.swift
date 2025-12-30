//
//  Topic+Samples.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 29-12-25.
//

import Foundation

// ⚠️ WARNING / IMPORTANT
// `Topic.sampleData` is the “source of truth” used to build sample data for other models.
// `StudySession.sampleData` and `TopicGoalChange.sampleData` reference `Topic.sampleData` BY INDEX
// (e.g. topics[0], topics[1], etc.).
//
// This means the ORDER must remain stable, or you’ll end up attaching sessions/goals
// to the wrong Topic without the compiler warning you.
//
// Expected indices right now:
// 0 = iOS
// 1 = Swift
// 2 = Electronic
// 3 = Japanese
// 4 = SwiftUI
// 5 = C languange
//
// If you reorder, insert a new topic in the middle, or remove one,
// make sure to update the indices in:
// - StudySession+Samples.swift
// - TopicGoalChange+Samples.swift
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
