//
//  GoalTests.swift
//  GoalsTests
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-12-25.
//

import Foundation
import Testing
@testable import Goals

struct GoalTests
{

    @Test("Goal.createdAt is normalized to start of day")
    func goalCreatedAtNormalized() {
        let input = TestDates.date(2025, 10, 12, 19, 45, 30)
        let goal = Goal(goalInMinutes: 60, createdAt: input)

        var cal = Calendar.current
        cal.timeZone = .current
        let expected = cal.startOfDay(for: input)

        #expect(goal.createdAt == expected)
    }

    @Test("Goal derived units are consistent", arguments: [
        (minutes: 0, expectedSeconds: 0, expectedHours: 0),
        (minutes: 59, expectedSeconds: 3540, expectedHours: 0),
        (minutes: 60, expectedSeconds: 3600, expectedHours: 1),
        (minutes: 61, expectedSeconds: 3660, expectedHours: 1),
        (minutes: 120, expectedSeconds: 7200, expectedHours: 2),
    ])
    func goalDerivedUnits(minutes: Int, expectedSeconds: Int, expectedHours: Int) {
        let g = Goal(goalInMinutes: minutes, createdAt: TestDates.date(2025, 10, 12, 12, 0))
        #expect(g.goalInSeconds == expectedSeconds)
        #expect(g.goalInHours == expectedHours)
    }
}
