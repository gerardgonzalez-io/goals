//
//  Timer.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-10-25.
//

import SwiftUI
import Foundation

private let kTimerSnapshotKey = "timer.snapshot.v1"

private struct TimerSnapshot: Codable
{
    let isRunning: Bool
    let startDate: Date?
    let accumulatedBeforeStart: TimeInterval
    let elapsed: TimeInterval
}

@MainActor
@Observable
final class Timer
{
    private(set) var elapsed: TimeInterval = 0
    private(set) var isRunning = false

    private var startDate: Date?
    private weak var timer: Foundation.Timer?
    private let frequency: TimeInterval = 1.0 / 60.0
    private var accumulatedBeforeStart: TimeInterval = 0

    var lengthInSeconds: Int
    {
        Int(displayTime())
    }
    var lengthInMinutes: Int
    {
        lengthInSeconds / 60
    }

    func toggle() { isRunning ? pause() : start() }

    func start()
    {
        guard !isRunning else { return }
        startDate = Date()
        accumulatedBeforeStart = elapsed
        isRunning = true
        timer = Foundation.Timer.scheduledTimer(withTimeInterval: frequency, repeats: true)
        { [weak self] _ in
            self?.update()
        }
        timer?.tolerance = 0.1
    }

    func pause()
    {
        guard isRunning else { return }
        timer?.invalidate()
        timer = nil
        if let start = startDate {
            let total = accumulatedBeforeStart + Date().timeIntervalSince(start)
            elapsed = total
        }
        startDate = nil
        isRunning = false
    }

    func stop()
    {
        if isRunning { pause() }
        timer?.invalidate()
        timer = nil
        startDate = nil
        accumulatedBeforeStart = 0
        elapsed = 0
    }

    func done(for topic: Topic)
    {
        if isRunning
        {
            pause()
        }
        let total = elapsed
        guard total > 0 else
        {
            stop()
            return
        }
        stop()
    }

    func displayTime() -> TimeInterval
    {
        if isRunning, let start = startDate
        {
            return accumulatedBeforeStart + Date().timeIntervalSince(start)
        }
        else
        {
            return elapsed
        }
    }

    nonisolated private func update()
    {
        Task
        { @MainActor in
            guard isRunning, let start = startDate else { return }
            elapsed = accumulatedBeforeStart + Date().timeIntervalSince(start)
        }
    }

    func formatted(_ time: TimeInterval) -> String
    {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time - floor(time)) * 100)
        return String(format: "%02d:%02d,%02d", minutes, seconds, centiseconds)
    }
    
    func saveSnapshot()
    {
        let snap = TimerSnapshot(
            isRunning: isRunning,
            startDate: startDate,
            accumulatedBeforeStart: accumulatedBeforeStart,
            elapsed: elapsed
        )
        if let data = try? JSONEncoder().encode(snap)
        {
            UserDefaults.standard.set(data, forKey: kTimerSnapshotKey)
        }
    }

    func restoreFromSnapshotAndResume()
    {
        guard
            let data = UserDefaults.standard.data(forKey: kTimerSnapshotKey),
            let snap = try? JSONDecoder().decode(TimerSnapshot.self, from: data)
        else { return }

        timer?.invalidate(); timer = nil

        if snap.isRunning, let start = snap.startDate
        {
            // Recalcular el tiempo transcurrido durante el background
            let recalculated = snap.accumulatedBeforeStart + Date().timeIntervalSince(start)
            elapsed = recalculated
            accumulatedBeforeStart = recalculated
            startDate = Date()
            isRunning = true
            timer = Foundation.Timer.scheduledTimer(withTimeInterval: frequency, repeats: true)
            { [weak self] _ in
                self?.update()
            }
            timer?.tolerance = 0.1
        }
        else
        {
            isRunning = false
            startDate = nil
            accumulatedBeforeStart = snap.accumulatedBeforeStart
            elapsed = snap.elapsed
        }
    }
}
