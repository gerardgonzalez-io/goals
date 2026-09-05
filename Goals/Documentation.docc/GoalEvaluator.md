# ``GoalEvaluator``

Evaluates whether each studied day reached its active daily goal.

## Overview

`reachedGoalsByDay(sessions:goals:)`:

- Calculates completed study time per day from session intervals.
- Finds the active goal for each studied day. The active goal is the latest goal created at or before that day’s first study timestamp.
- Returns whether each studied day met its active goal.

The method only includes days that have study time. Each returned key is the start of that calendar day.

---

## Reached Goals by Day

`reachedGoalsByDay(sessions:goals:)` evaluates goal completion for each studied day.

### Declaration

```swift
func reachedGoalsByDay(sessions: [StudySession], goals: [Goal]) -> [Date: Bool]
```

### Return Value

A dictionary where each key is a studied day and each value indicates whether the active goal was reached on that day.

- `true`: the completed study time for the day is greater than or equal to the active goal.
- `false`: the day has study time, but no active goal exists yet or the completed time is below the active goal.

### Parameters

- **sessions**

  The study sessions to evaluate. Their intervals are used to calculate completed study time per calendar day.

- **goals**

  The goal history used to determine the active goal for each studied day. The active goal is the latest goal created at or before that day’s first study timestamp.
