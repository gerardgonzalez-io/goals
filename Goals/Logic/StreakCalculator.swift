// Logic before apply improvement of performance with agent
import Foundation

struct StreakCalculator
{
    let calendar = Calendar.current

    /*
     ◇ Test "Measure calculateStreak execution time" started.
      calculateStreak took: 0.130747542 seconds
     */
    func calculateStreak(for sessions: [StudySession], goals: [Goal]) -> Int
    {
        let startOfToday = calendar.startOfDay(for: .now)
        let endOfToday = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfToday)!

        let reachedGoalsByDay = GoalEvaluator().reachedGoalsByDay(
            sessions: sessions,
            goals: goals
        )

        let daysAgoArray = reachedGoalsByDay
            .filter { $0.value }
            .keys
            .sorted(by: >)
            .map { calendar.dateComponents([.day], from: $0, to: endOfToday) }
            .compactMap { $0.day }
        // `daysAgoArray` stores successful days as offsets from today:
        // `0` = today, `1` = yesterday, `2` = two days ago, etc.
        // We count consecutive values from 0 or 1 to keep streak active through yesterday.

        var streak = 0
        for daysAgo in daysAgoArray
        {
            if daysAgo == streak
            {
                continue
            }
            else if daysAgo == streak + 1
            {
                streak += 1
            }
            else
            {
                break
            }
        }

        if daysAgoArray.first == 0
        {
            streak += 1
        }

        return streak
    }
}
