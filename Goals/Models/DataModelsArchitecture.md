# Data Models Architecture

This project is a SwiftUI + SwiftData study tracking app. Its core loop is:

1. User completes onboarding.
2. User creates study topics, each with a daily goal.
3. User starts focus sessions for a topic.
4. Sessions are saved as one or more timed intervals.
5. The app summarizes study time, streaks, calendar completion, goal history, and progress versus plan.

## Data Models

The active runtime schema is `GoalsSchemaV3`, exposed through `CurrentModels.swift`:

```swift
typealias Topic = GoalsSchemaV3.Topic
typealias Goal = GoalsSchemaV3.Goal
typealias StudySession = GoalsSchemaV3.StudySession
typealias SessionInterval = GoalsSchemaV3.SessionInterval
```

### Topic

Represents a study subject.

Main fields:

- `id`
- `name`
- `createdAt`
- `updatedAt`
- `isArchived`

In V3, `Topic` no longer owns direct relationships to sessions or goals. Other records point to it through `topicID`.

### Goal

Represents a daily target snapshot for a topic.

Main fields:

- `topicID`
- `targetSecondsPerDay`
- `createdAt`
- `effectiveFromDay`
- `updatedAt`
- `isArchived`

Goals are historical snapshots. When the user changes a goal, the app inserts a new `Goal` instead of mutating the old one. This lets past days keep the goal that was active at that time.

### StudySession

Represents a completed focus session for a topic.

Main fields:

- `topicID`
- `startDate`
- `endDate`
- `sessionIntervals`
- `createdAt`
- `updatedAt`
- `isArchived`

A session can contain multiple intervals, which allows pause/resume tracking inside one logical study session.

### SessionInterval

Represents one continuous focused interval.

Main fields:

- `startDate`
- `endDate`
- `studySession`
- `durationSeconds`
- `createdAt`
- `updatedAt`
- `isArchived`

`durationSeconds` returns zero for unfinished or invalid intervals.

## Sample Data

`SampleData.swift` owns an in-memory SwiftData container for previews and sample runs.

The sample model extensions provide reusable examples:

- `Topic+Samples.swift` creates Mathematics, Chemistry, and History topics.
- `Goal+Samples.swift` creates topic-specific daily goal snapshots.
- `StudySession+Samples.swift` creates sessions with one or more intervals.

The sample data mirrors the V3 model shape: goals and sessions point to topics through `topicID`, and sessions contain interval records.

## Overall Architecture

The app is organized cleanly around three layers:

- Models: SwiftData schema versions, current typealiases, sample data.
- Logic: pure or mostly pure calculators for time, goals, streaks, progress, plus timer state.
- Views: SwiftUI screens that query SwiftData, call logic helpers, and render navigation flows.

The strongest architectural choice is the V3 move toward immutable goal snapshots and interval-based sessions. That gives the app enough historical accuracy to answer questions like “did I meet the goal that was active on that day?” and “how much time belongs to each calendar day?” without rewriting old records.
