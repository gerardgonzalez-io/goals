# StudySession Timer Architecture

`StudySessionTimer.swift` contains the in-memory count-up timer used by `TimerView` while a focus session is active.

## Responsibilities

`StudySessionTimer` is an `@Observable`, `@MainActor` reference type.

It owns:

- `secondsElapsed`: whole seconds shown by the timer UI.
- `isRunning`: whether the internal scheduled timer is currently active.
- an internal `Foundation.Timer` that updates elapsed seconds once per second.

Public operations:

- `start()`: starts or resumes counting from the current `secondsElapsed` value.
- `stop()`: pauses counting without clearing `secondsElapsed`.
- `reset()`: stops counting and returns `secondsElapsed` to zero.

## Boundaries

`StudySessionTimer` does not know about topics, SwiftData, sessions, intervals, persistence, or scene phase changes. It is only responsible for elapsed display state.

`TimerView` owns the study-session lifecycle:

- creates `StudySession` and the first `SessionInterval` on appear/start.
- closes the current interval on pause.
- creates another interval on resume.
- closes and saves the session on stop or disappear.

## Persistence

Timer state is not saved to `UserDefaults` or restored across launches. If the app is interrupted before a session is closed, `DataContainer` removes unfinished `StudySession` and `SessionInterval` records during startup by deleting records where `endDate == nil`.

## Display Precision

The utility tracks whole seconds. `TimerView` is responsible for formatting those seconds for display and for passing the elapsed value to `TimerDialView`.
