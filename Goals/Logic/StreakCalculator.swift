// Logic before apply improvement of performance with agent
import Foundation

 struct StreakCalculator
 {
     let calendar = Calendar.current

     /*
     ◇ Test "Measure calculateStreak execution time" started.
      calculateStreak took: 0.130747542 seconds
     */
     func calculateStreak(for sessions: [StudySession]) -> Int
     {
         let startOfToday = calendar.startOfDay(for: .now)
         let endOfToday = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfToday)!

         var successfulDays = Set<Date>()

         for session in sessions
         {
             for interval in session.sessionIntervals
             {
                 guard let endDate = interval.endDate, interval.startDate < endDate else
                 {
                     continue
                 }

                 let firstDay = calendar.startOfDay(for: interval.startDate)

                 // Treat interval end as exclusive so boundaries at 00:00 do not count the next day.
                 let inclusiveEnd = endDate.addingTimeInterval(-TimeInterval.leastNonzeroMagnitude)
                 guard inclusiveEnd >= interval.startDate else
                 {
                     continue
                 }

                 let lastDay = calendar.startOfDay(for: inclusiveEnd)
                 var currentDay = firstDay

                 while currentDay <= lastDay
                 {
                     successfulDays.insert(currentDay)
                     currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
                 }
             }
         }

        let daysAgoArray = successfulDays
            .sorted(by: >)
            .map { calendar.dateComponents([.day], from: $0, to: endOfToday) }
            .compactMap { $0.day }
        // `daysAgoArray` stores successful days as offsets from today:
        // `0` = today, `1` = yesterday, `2` = two days ago, etc.
        // Example: [-2, -1, 0] input activity days become [0, 1, 2] after mapping.
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
