1. **Error**

`CalendarView` was doing too much work while SwiftUI was rendering the calendar. The UI hang happened because drawing one month caused repeated expensive calculations on the main thread.

2. **Cause**

Each day cell called `isCompleted(on:)`:

```swift
DayCell(
    date: dayDate,
    completed: isCompleted(dayDate),
    showIndicator: shouldShowIndicator(dayDate)
)
```

But `isCompleted(on:)` recalculated the full goal history every time:

```swift
private func isCompleted(on date: Date) -> Bool
{
    let dayKey = calendar.startOfDay(for: date)
    let completedByDay = GoalEvaluator().reachedGoalsByDay(
        sessions: topicSessions,
        goals: topicGoals
    )
    return completedByDay[dayKey] == true
}
```

So for ~35-42 calendar cells, the app repeatedly ran:

```swift
GoalEvaluator().reachedGoalsByDay(...)
```

That evaluator loops through all sessions, all intervals, and sorts goal/day data. Doing that per cell made rendering slow.

3. **Solution**

I changed it to compute the expensive result once per render:

```swift
private func makeProgressState() -> CalendarProgressState
{
    CalendarProgressState(
        completedByDay: GoalEvaluator().reachedGoalsByDay(
            sessions: topicSessions,
            goals: topicGoals
        ),
        earliestTopicDay: earliestTopicDay()
    )
}
```

Then `body` creates one shared state:

```swift
let progressState = makeProgressState()
```

And passes it into the grid:

```swift
MonthGrid(
    month: startOfMonth,
    calendar: calendar,
    today: today,
    progressState: progressState
)
```

Now each cell uses a fast dictionary lookup:

```swift
private func isCompleted(on date: Date) -> Bool
{
    let dayKey = calendar.startOfDay(for: date)
    return progressState.completedByDay[dayKey] == true
}
```

Result: same UI behavior, but the full goal evaluation runs once instead of dozens of times per render.
