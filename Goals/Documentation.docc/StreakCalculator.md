# ``StreakCalculator``

Calculates study streaks from session intervals.

## Overview

`calculateStreak(for:)`:

- Calculates the current consecutive-day streak from active study intervals.
- Counts a day as successful when at least one interval overlaps that day.
- Keeps the streak active when the user studied yesterday, even if not today.

---

## Streak Rules

- A day counts toward the streak when at least one interval overlaps that day.
- The streak is still active if the user studied yesterday (even if not today).
- The streak breaks after one full missed day between successful days.

---

## How It Works

- Input: `[StudySession]`, where each session can contain multiple `SessionInterval` values.
- Intervals are the source of truth; session outer `startDate`/`endDate` do not define successful days.
- If an interval crosses midnight, activity is split across each overlapped calendar day.
- Output: `Int` representing the current consecutive-day streak up to today.

---

## Examples

- Activity only today -> streak `1`.
- No activity today, but activity yesterday -> streak `1`.
- Activity on today and yesterday -> streak `2`.
- Activity on today and two days ago, but not yesterday -> streak `1` (gap breaks streak).
- Activity on yesterday and two days ago, but not today -> streak `2` (active from yesterday).

---

## Calculate Streak

`calculateStreak(for:)` returns the current study streak for the provided sessions.

### Declaration

```swift
func calculateStreak(for sessions: [StudySession]) -> Int
```

### Return Value

An integer representing the current consecutive-day streak up to today.

### Parameters

- **sessions**

  The study sessions to evaluate. Their intervals are used to determine successful study days.
