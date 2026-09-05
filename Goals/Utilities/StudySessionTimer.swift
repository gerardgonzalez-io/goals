//
//  StudySessionTimer.swift
//  Goals
//

import Foundation
import Observation

/// A simple count-up timer for tracking study session duration.
///
/// The timer starts at `0` seconds and increases `secondsElapsed` once per second.
/// Calling `start()` begins or resumes the timer.
/// Calling `stop()` pauses the timer without resetting the elapsed time.
/// Calling `reset()` stops the timer and sets `secondsElapsed` back to `0`.
///
/// This timer does not have a fixed duration and will keep running until `stop()`
/// or `reset()` is called.
@MainActor
@Observable
final class StudySessionTimer
{
    var secondsElapsed = 0
    var isRunning = false

    private weak var internalTimer: Timer?
    private var timerStopped = true
    private var frequency: TimeInterval { 1.0 }
    private var startDate: Date?

    init() {}

    func start()
    {
        guard !isRunning else { return }

        isRunning = true
        timerStopped = false

        // Keeps counting from the current secondsElapsed value.
        startDate = Date().addingTimeInterval(TimeInterval(-secondsElapsed))

        internalTimer = Foundation.Timer.scheduledTimer(
            withTimeInterval: frequency,
            repeats: true
        )
        { [weak self] _ in
            self?.update()
        }

        internalTimer?.tolerance = 0.1
    }

    func stop()
    {
        internalTimer?.invalidate()
        internalTimer = nil

        isRunning = false
        timerStopped = true
    }

    func reset()
    {
        stop()

        secondsElapsed = 0
        startDate = nil
        timerStopped = true
    }

    nonisolated private func update()
    {
        Task
        { @MainActor in
            guard let startDate, isRunning, !timerStopped else { return }

            let elapsed = Int(Date().timeIntervalSince(startDate))
            secondsElapsed = max(elapsed, 0)
        }
    }
}
