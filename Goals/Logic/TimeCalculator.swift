import Foundation

struct TimeCalculator
{
    /*
     ◇ Test "Measure dailyTime execution time" started.
     dailyTime took: 0.018348834 seconds
     */
    static func dailyTime(
        from studySessions: [StudySession],
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> TimeInterval
    {
        guard let dayInterval = calendar.dateInterval(of: .day, for: date) else
        {
            return 0
        }

        let dayStart = dayInterval.start
        let dayEnd = dayInterval.end

        var total: TimeInterval = 0

        for session in studySessions
        {
            for interval in session.sessionIntervals
            {
                guard let endDate = interval.endDate else { continue }

                let overlapStart = max(interval.startDate, dayStart)
                let overlapEnd = min(endDate, dayEnd)

                if overlapStart < overlapEnd {
                    total += overlapEnd.timeIntervalSince(overlapStart)
                }
            }
        }

        return total
    }

    /*
     ◇ Test "Measure totalTime execution time" started.
     totalTime took: 0.022743 seconds
    */
    static func totalTime(from studySessions: [StudySession]) -> TimeInterval
    {
        var total: TimeInterval = 0

        for session in studySessions
        {
            for interval in session.sessionIntervals
            {
                total += interval.durationSeconds
            }
        }

        return total
    }
}
