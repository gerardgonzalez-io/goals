# ``StreakCalculator``

Calculates study streaks from session intervals.

## Overview

`calculateStreak(for:)`:

- Calculates the current consecutive-day streak from active study intervals.
- Counts a day as successful when completed study time reaches that day's active goal.
- Keeps the streak active when the user reached yesterday's goal, even if not today.

---

## Streak Rules

- A day counts toward the streak when completed study time reaches that day's active goal.
- The streak is still active if the user reached yesterday's goal, even if not today.
- The streak breaks after one full day where the active goal was not reached.

---

## How It Works

- Input: `[StudySession]` and `[Goal]`, where each session can contain multiple `SessionInterval` values.
- Intervals are the source of truth for completed time; session outer `startDate`/`endDate` do not define successful days.
- If an interval crosses midnight, completed time is split across each overlapped calendar day.
- Output: `Int` representing the current consecutive-day streak up to today.

---

## Examples

- Goal reached only today -> streak `1`.
- Goal not reached today, but reached yesterday -> streak `1`.
- Goal reached today and yesterday -> streak `2`.
- Goal reached today and two days ago, but not yesterday -> streak `1` (gap breaks streak).
- Goal reached yesterday and two days ago, but not today -> streak `2` (active from yesterday).

---

## Calculate Streak

`calculateStreak(for:)` returns the current study streak for the provided sessions.

### Declaration

```swift
func calculateStreak(for sessions: [StudySession], goals: [Goal]) -> Int
```

### Return Value

An integer representing the current consecutive-day streak up to today.

### Parameters

- **sessions**

  The study sessions to evaluate. Their intervals are used to calculate completed study time per day.

- **goals**

  The goal history used to determine whether each day's completed time reached the active daily target.
