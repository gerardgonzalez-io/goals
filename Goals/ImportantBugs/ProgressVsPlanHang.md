# ProgressVsPlanView Hang

The hang is caused by expensive synchronous work happening inside SwiftUI view recomputation for `ProgressVsPlanView`.

Step by step:

1. `ProgressVsPlanView.report` is a computed property in `Goals/Goals/Views/ImportantBugs/ProgressVsPlanView.swift`.

   Every time SwiftUI reads `report`, it runs:

   ```swift
   ProgressVsPlan.compute(...)
   ```

2. The view reads `report` many times in one render pass.

   `headerSubtitle`, `kpisRow`, `chartSection`, and `insightSection` all access it separately.

   So one screen render can call `ProgressVsPlan.compute` repeatedly, not once.

3. `ProgressVsPlan.compute` starts by filtering and sorting again in `Goals/Goals/Logic/ProgressVsPlan.swift`.

   ```swift
   let topicSessions = sessions.filter { $0.topicID == topic.id }
   let topicGoals = goals.filter { ... }.sorted { ... }
   ```

   But the SwiftData `@Query` in the view already filters by `topicID`, so this repeats work unnecessarily.

4. The expensive part is the nested loop through time periods and sessions.

   For each chart period, it calls `actualSeconds`.

5. `actualSeconds` calls `TimeCalculator.dailyTime`, and `dailyTime` loops through every session and every interval in `Goals/Goals/Logic/TimeCalculator.swift`.

   ```swift
   for session in studySessions {
       for interval in session.sessionIntervals {
           ...
       }
   }
   ```

6. For `7D`, that means roughly:

   ```text
   7 days * all sessions * all intervals
   ```

   For `30D`:

   ```text
   30 days * all sessions * all intervals
   ```

   For `12M`, it loops day-by-day inside each month:

   ```text
   about 365 days * all sessions * all intervals
   ```

7. Because this runs from SwiftUI `body` evaluation, it happens on the main thread. The Instruments screenshot confirms the main thread is stuck during the view's foreground activity, producing severe hangs.

The core problem: `ProgressVsPlanView` performs repeated, full-history, nested aggregation work synchronously during rendering. The more study sessions and intervals there are, the worse it gets. The chart is likely amplifying the issue because SwiftUI and Charts may reevaluate the body multiple times during navigation and layout, causing the expensive report calculation to rerun again and again.
