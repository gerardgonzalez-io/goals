# Logic Architecture

This project is a SwiftUI + SwiftData study tracking app. Its core loop is:

1. User completes onboarding.
2. User creates study topics, each with a daily goal.
3. User starts focus sessions for a topic.
4. Sessions are saved as one or more timed intervals.
5. The app summarizes study time, streaks, calendar completion, goal history, and progress versus plan.

## Data Container

`DataContainer.swift` owns SwiftData setup.

Responsibilities:

- Builds the model schema.
- Uses `GoalsMigrationPlan` for normal persistent storage.
- Uses in-memory storage for sample data.
- Injects the `ModelContainer` into SwiftUI.
- Deletes unfinished `StudySession` and `SessionInterval` records on startup.

That cleanup matters because a timer session may be interrupted before it is completed.

## Logic Layer

### StudySessionTimer.swift

An observable count-up timer used by `TimerView`.

Responsibilities:

- Tracks elapsed seconds.
- Supports start, stop-as-pause, and reset.
- Keeps elapsed time in memory only.

It does not persist snapshots. `TimerView` creates and closes `StudySession` and `SessionInterval` records directly.

### TimeCalculator.swift

Provides aggregate time calculations.

Functions:

- `dailyTime(from:on:calendar:)`
- `totalTime(from:)`

Important behavior:

- It iterates through `SessionInterval` records, not only session start/end.
- `dailyTime` splits overlap by day, so an interval crossing midnight contributes only the relevant seconds to each day.

### GoalEvaluator.swift

Determines whether goals were reached by day.

Main function:

- `reachedGoalsByDay(sessions:goals:) -> [Date: Bool]`

Important behavior:

- Aggregates completed seconds per day.
- Splits intervals across midnight.
- Finds the first study timestamp per day.
- Selects the active goal whose `createdAt` was before that day’s first study timestamp.
- Marks the day complete if actual seconds meet `targetSecondsPerDay`.

### StreakCalculator.swift

Calculates current streak from study sessions.

Behavior:

- Builds a set of days that had any valid interval.
- Treats interval ends as exclusive, so ending exactly at midnight does not incorrectly count the next day.
- Counts consecutive active days from today or yesterday.

This streak is activity-based, not goal-completion-based.

### ProgressVsPlan.swift

Builds chart/report data.

Main output:

- `ProgressVsPlan.Report`

It includes:

- cumulative actual minutes
- cumulative planned minutes
- delta
- ahead/behind status
- insight text
- chart points

Supported ranges:

- last 7 days
- last 30 days
- last 12 months

It filters sessions/goals by topic, computes actual time from intervals, computes plan time from active goals, then accumulates both over the selected period.

## Overall Architecture

The app is organized cleanly around three layers:

- Models: SwiftData schema versions, current typealiases, sample data.
- Logic: pure or mostly pure calculators for time, goals, streaks, progress, plus timer state.
- Views: SwiftUI screens that query SwiftData, call logic helpers, and render navigation flows.

The strongest architectural choice is the V3 move toward immutable goal snapshots and interval-based sessions. That gives the app enough historical accuracy to answer questions like “did I meet the goal that was active on that day?” and “how much time belongs to each calendar day?” without rewriting old records.
