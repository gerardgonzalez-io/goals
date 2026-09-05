# Migration Architecture

This project is a SwiftUI + SwiftData study tracking app. Its core loop is:

1. User completes onboarding.
2. User creates study topics, each with a daily goal.
3. User starts focus sessions for a topic.
4. Sessions are saved as one or more timed intervals.
5. The app summarizes study time, streaks, calendar completion, goal history, and progress versus plan.

## Schema History And Migration

There are three schemas:

### GoalsSchemaV1

Had:

- `Topic`
- `Goal`
- `StudySession`

In V1, each `StudySession` directly referenced a `Goal`.

### GoalsSchemaV2

Removed the standalone `Goal` model and introduced `TopicGoalChange`.

A topic had:

- `goalChanges`
- `studySessions`

A goal change stored:

- `goalInMinutes`
- `effectiveAt`
- `effectiveFromDay`

### GoalsSchemaV3

Current version.

Changes:

- `TopicGoalChange` became `Goal`.
- `StudySession` now stores `topicID` instead of a `Topic` relationship.
- `SessionInterval` was added to support paused/resumed sessions.

`GoalsMigrationPlan.swift` handles:

- V1 -> V2: converts old session-linked goals into topic goal-change snapshots.
- V2 -> V3: converts `TopicGoalChange` into `Goal`, assigns `topicID` to sessions, and creates initial `SessionInterval` records for migrated sessions.

## Overall Architecture

The app is organized cleanly around three layers:

- Models: SwiftData schema versions, current typealiases, sample data.
- Logic: pure or mostly pure calculators for time, goals, streaks, progress, plus timer state.
- Views: SwiftUI screens that query SwiftData, call logic helpers, and render navigation flows.

The strongest architectural choice is the V3 move toward immutable goal snapshots and interval-based sessions. That gives the app enough historical accuracy to answer questions like “did I meet the goal that was active on that day?” and “how much time belongs to each calendar day?” without rewriting old records.
