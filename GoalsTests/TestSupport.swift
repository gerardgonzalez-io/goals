//
//  TestSupport.swift
//  GoalsTests
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-12-25.
//

import Foundation
import Testing
@testable import Goals

enum TestDates
{
    /// Creates a stable Date in the *current* timezone (matches your production normalization logic).
    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) -> Date {
        var comps = DateComponents()
        comps.calendar = Calendar.current
        comps.timeZone = .current
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        comps.second = second
        return comps.date!
    }
}

func makeSession(
    topic: Topic,
    start: Date,
    minutes: Int,
    extraSeconds: Int = 0
) -> StudySession {
    let end = start.addingTimeInterval(TimeInterval(minutes * 60 + extraSeconds))
    return StudySession(topic: topic, startDate: start, endDate: end)
}
