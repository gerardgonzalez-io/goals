# ``TimeCalculator``

Calculates active study time from session intervals.

## Overview

`TimeCalculator`:

- A `StudySession` can contain multiple `SessionInterval` values to represent pause/resume cycles.
- Time is always calculated from interval ranges, not from the session's outer start/end dates.
- `dailyTime` sums only the overlap between each interval and the requested day, so intervals crossing midnight are automatically split across days.
- `totalTime` sums the full duration of all intervals across all sessions.

---

## Daily Time

`dailyTime(from:on:calendar:)` calculates study time for one calendar day.

### Declaration

```swift
static func dailyTime(
    from studySessions: [StudySession],
    on date: Date = .now,
    calendar: Calendar = .current
) -> TimeInterval
```

### Return Value

The number of active study seconds that overlap the requested day.

### Parameters

- **studySessions**

  The sessions to evaluate. Their intervals are used to calculate active study time.

- **date**

  The day to calculate. The method uses the calendar’s day interval for this date.

- **calendar**

  The calendar used to resolve the start and end of the requested day.

---

## Total Time

`totalTime(from:)` calculates accumulated study time across all provided sessions.

### Declaration

```swift
static func totalTime(from studySessions: [StudySession]) -> TimeInterval
```

### Return Value

The total number of active study seconds across all intervals in all provided sessions.

### Parameters

- **studySessions**

  The sessions whose interval durations should be summed.
