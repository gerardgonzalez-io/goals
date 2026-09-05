# Views Architecture

This project is a SwiftUI + SwiftData study tracking app. Its core loop is:

1. User completes onboarding.
2. User creates study topics, each with a daily goal.
3. User starts focus sessions for a topic.
4. Sessions are saved as one or more timed intervals.
5. The app summarizes study time, streaks, calendar completion, goal history, and progress versus plan.

## View Hierarchy

### GoalsApp

App entry point.

Flow:

- Reads `hasCompletedOnboarding` from `@AppStorage`.
- If false, shows `OnboardingView`.
- If true, shows `ContentView`.
- Injects `DataContainer` and SwiftData model container.

### OnboardingView

A paged `TabView`.

Children:

- `WelcomePage`
- `FeaturePage`

### WelcomePage

Shows the app welcome message and icon.

### FeaturePage

Shows feature cards and a `Get Started` button. Pressing the button calls `onFinish`, which sets `hasCompletedOnboarding = true`.

### FeatureCard

Reusable row-style card for onboarding feature descriptions.

## Main App Flow

### ContentView

The post-onboarding home screen.

Structure:

- `NavigationStack`
- Summary title/subtitle
- `SummaryCard` link to Topics
- `SummaryCard` link to Study History

It owns a shared `@State private var timer = StudySessionTimer()` and passes it into topic/timer views.

Routes:

- `.topics` -> `TopicListView`
- `.studyHistory` -> `StudyHistoryView`

### SummaryCard

Reusable navigation card with:

- SF Symbol icon
- title
- subtitle
- optional chevron

## Topic Flow

### TopicListView

Lists all topics using:

```swift
@Query(sort: \Topic.name) private var topics
```

Responsibilities:

- Show topic list.
- Add a new topic.
- Delete a topic and manually delete related sessions/goals by matching `topicID`.
- Navigate to `TopicDetailView`.

Adding a topic:

- Inserts a blank `Topic`.
- Presents `NewTopicView` in a sheet.
- If canceled, the blank topic is deleted.
- If saved, the topic gets a name and initial goal snapshot.

### NewTopicView

Form for creating a topic.

Fields:

- topic name
- daily goal picker from 1 to 240 minutes

On save:

- Trims the topic name.
- Creates an initial `Goal`.
- Saves both topic and goal.

### TopicDetailView

Topic dashboard.

It filters sessions by the selected `topicID`.

Shows:

- Focus session card
- Today’s study time
- Total study time
- Navigation cards for calendar, streak, goal editing, and progress

Routes:

- `.focus` -> `TimerView`
- `.calendar` -> `CalendarView`
- `.streak` -> `StreakPerTopicView`
- `.topicGoal` -> `TopicGoal`
- `.progressVsPlan` -> `ProgressVsPlanView`

### TopicCard

Reusable metric card for topic detail stats, used for Today and Total study time.

## Timer Flow

### TimerView

Focus session screen for a preselected topic.

Responsibilities:

- Selects the preselected topic on appear.
- Automatically starts a new session when opened.
- Creates a `StudySession` immediately with `endDate == nil`.
- Creates the first open `SessionInterval` immediately.
- Uses `StudySessionTimer` only for in-memory elapsed-time display.
- Pauses by closing the active interval and stopping the timer without resetting elapsed seconds.
- Resumes by creating a new interval on the same active session.
- Stops by closing the active interval and session, saving SwiftData, resetting the timer, and clearing active state.
- Stops the active session on disappear.

Key state:

- `selectedTopic`
- `activeSession`
- `activeInterval`
- `didAutoStart`

Timer persistence notes:

- `TimerView` no longer uses `UserDefaults` timer snapshots.
- Unfinished sessions and intervals are represented by `endDate == nil` and are cleaned up by `DataContainer` on startup.

### TimerDialView

Draws the stopwatch-like dial using SwiftUI `Canvas`.

It renders:

- second tick marks
- minute subdial
- second hand
- minute hand
- numeric labels

## History And Progress Views

### StudyHistoryView

Global history screen across all topics.

Data:

- Fetches all `StudySession` records.
- Fetches all `Topic` records.

Behavior:

- Splits intervals across calendar days.
- Groups time by day and topic.
- Shows newest days first.
- Shows per-topic studied time and total time for each day.

### CalendarView

Per-topic calendar.

Data:

- Fetches sessions for the topic.
- Fetches non-archived goals for the topic.

Behavior:

- Displays a month grid.
- Shows previous months through `monthOffset`.
- Does not allow browsing into future months.
- Uses `GoalEvaluator` to determine whether a day met the goal.
- Shows indicators only after the topic has activity, for past days, and for today only if complete.

Day states:

- success: goal met
- missed: goal not met
- none: future/no relevant data

### StreakPerTopicView

Per-topic streak screen.

Data:

- Fetches sessions for the topic.

Shows:

- current streak
- longest streak
- tip text

Current streak comes from `StreakCalculator`.
Longest streak is calculated locally in the view from successful activity days.

### TopicGoal

Goal editing screen for a topic.

Data:

- Fetches non-archived goals for the topic, newest first.

Behavior:

- Loads the current goal into a wheel picker.
- Prevents saving if the selected value matches the current goal.
- Saves a new `Goal` snapshot when changed.
- Displays goal history.

### ProgressVsPlanView

Per-topic chart screen.

Data:

- Fetches sessions for the topic.
- Fetches non-archived goals for the topic.

UI:

- Header with date range.
- Segmented picker for 7D, 30D, 12M.
- Previous/next period buttons.
- KPI row: Actual, Plan, Ahead/Behind.
- Swift Charts line chart comparing actual cumulative progress against planned cumulative progress.
- Insight text from `ProgressVsPlan.Report`.

## Overall Architecture

The app is organized cleanly around three layers:

- Models: SwiftData schema versions, current typealiases, sample data.
- Logic: pure or mostly pure calculators for time, goals, streaks, and progress.
- Utilities: observable app helpers such as `StudySessionTimer`.
- Views: SwiftUI screens that query SwiftData, call logic/utilities, and render navigation flows.

The strongest architectural choice is the V3 move toward immutable goal snapshots and interval-based sessions. That gives the app enough historical accuracy to answer questions like “did I meet the goal that was active on that day?” and “how much time belongs to each calendar day?” without rewriting old records.
