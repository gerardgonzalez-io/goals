import Foundation

struct GoalEvaluator {
    let calendar = Calendar.current

    /*
     ◇ Test "Measure reachedGoalsByDay execution time" started.
     
     reachedGoalsByDay took: 0.036813667 seconds

     ✔ Test "Measure reachedGoalsByDay execution time" passed after 0.048 seconds.
     ✔ Suite GoalEvaluatorTests passed after 0.049 seconds.
     ✔ Test run with 1 test in 1 suite passed after 0.050 seconds.
     */
    func reachedGoalsByDay(sessions: [StudySession], goals: [Goal]) -> [Date: Bool]
    {
        let (completedByDay, firstStudyTimestampByDay) = completedSecondsByDay(from: sessions)
        let days = completedByDay.keys.sorted()

        guard !days.isEmpty else {
            return [:]
        }

        let goalsByCreatedAt = goals.sorted { $0.createdAt < $1.createdAt }

        var result: [Date: Bool] = [:]
        result.reserveCapacity(days.count)

        var activeGoal: Goal?
        var goalIndex = 0

        for day in days
        {
            guard let firstStudyTimestamp = firstStudyTimestampByDay[day] else
            {
                result[day] = false
                continue
            }

            while goalIndex < goalsByCreatedAt.count, goalsByCreatedAt[goalIndex].createdAt <= firstStudyTimestamp
            {
                activeGoal = goalsByCreatedAt[goalIndex]
                goalIndex += 1
            }

            guard let goal = activeGoal else
            {
                result[day] = false
                continue
            }

            result[day] = completedByDay[day, default: 0] >= goal.targetSecondsPerDay
        }

        return result
    }

    private func completedSecondsByDay(from sessions: [StudySession]) -> ([Date: TimeInterval], [Date: Date])
    {
        var totals: [Date: TimeInterval] = [:]
        var firstStudyTimestampByDay: [Date: Date] = [:]

        for session in sessions
        {
            for interval in session.sessionIntervals
            {
                guard let endDate = interval.endDate, interval.startDate < endDate else { continue }

                var currentDay = calendar.startOfDay(for: interval.startDate)

                while currentDay < endDate
                {
                    guard let dayInterval = calendar.dateInterval(of: .day, for: currentDay) else
                    {
                        break
                    }

                    let overlapStart = max(interval.startDate, dayInterval.start)
                    let overlapEnd = min(endDate, dayInterval.end)

                    if overlapStart < overlapEnd
                    {
                        totals[currentDay, default: 0] += overlapEnd.timeIntervalSince(overlapStart)
                        if let existing = firstStudyTimestampByDay[currentDay]
                        {
                            if overlapStart < existing
                            {
                                firstStudyTimestampByDay[currentDay] = overlapStart
                            }
                        }
                        else
                        {
                            firstStudyTimestampByDay[currentDay] = overlapStart
                        }
                    }

                    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else
                    {
                        break
                    }

                    currentDay = nextDay
                }
            }
        }

        return (totals, firstStudyTimestampByDay)
    }
}
