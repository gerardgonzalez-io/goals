//
//  StudySessionTests.swift
//  GoalsTests
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-12-25.
//

import Foundation
import Testing
@testable import Goals

struct StudySessionTests
{

    @Test("StudySession.normalizedDay normalizes to start of day (same day -> same normalizedDay)")
    func normalizedDaySameCalendarDay() {
        let topic = Topic(name: "SwiftUI")
        let goal = Goal(goalInMinutes: 30, createdAt: TestDates.date(2025, 10, 12, 9, 0))

        let baseDay = TestDates.date(2025, 10, 12, 0, 0)
        let s1 = makeSession(topic: topic, goal: goal, start: TestDates.date(2025, 10, 12, 9, 15), minutes: 10)
        let s2 = makeSession(topic: topic, goal: goal, start: TestDates.date(2025, 10, 12, 23, 59), minutes: 1)

        #expect(s1.normalizedDay == baseDay)
        #expect(s2.normalizedDay == baseDay)
    }

    @Test("StudySession.durationInMinutes floors seconds to minutes and never returns negative", arguments: [
        (minutes: 2, extraSeconds: 59, expected: 2), // 2:59 -> 2
        (minutes: 0, extraSeconds: 59, expected: 0), // 0:59 -> 0
        (minutes: 1, extraSeconds: 1,  expected: 1), // 1:01 -> 1
    ])
    func durationFloors(minutes: Int, extraSeconds: Int, expected: Int) {
        let topic = Topic(name: "Japanese")
        let goal = Goal(goalInMinutes: 1, createdAt: TestDates.date(2025, 10, 12, 9, 0))
        let start = TestDates.date(2025, 10, 12, 10, 0)

        let s = makeSession(topic: topic, goal: goal, start: start, minutes: minutes, extraSeconds: extraSeconds)
        #expect(s.durationInMinutes == expected)
    }

    @Test("StudySession.durationInMinutes returns 0 when endDate <= startDate")
    func durationNonPositiveIsZero() {
        let topic = Topic(name: "C language")
        let goal = Goal(goalInMinutes: 1, createdAt: TestDates.date(2025, 10, 12, 9, 0))
        let start = TestDates.date(2025, 10, 12, 10, 0)

        let s1 = StudySession(topic: topic, goal: goal, startDate: start, endDate: start)
        #expect(s1.durationInMinutes == 0)

        let s2 = StudySession(topic: topic, goal: goal, startDate: start, endDate: start.addingTimeInterval(-10))
        #expect(s2.durationInMinutes == 0)
    }
}
