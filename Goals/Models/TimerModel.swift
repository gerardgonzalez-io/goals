//
//  TimerModel.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-09-25.
//

import SwiftUI
import SwiftData

/// TimerModel manages timing functionality and tracks elapsed time.
/// It optionally accepts a ModelContext to persist StudySession data as the source of truth.
final class TimerModel: ObservableObject
{
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var isRunning = false
    private var startDate: Date?
    /// Injected ModelContext used to persist StudySession instances
    private let context: ModelContext?

    init(context: ModelContext? = nil)
    {
        self.context = context
    }

    func toggle() { isRunning ? pause() : start() }

    func start()
    {
        guard !isRunning else { return }
        startDate = Date()
        isRunning = true
    }

    func pause()
    {
        guard isRunning, let s = startDate else { return }
        elapsed += Date().timeIntervalSince(s)
        startDate = nil
        isRunning = false
    }

    func stop()
    {
        if isRunning { pause() }
        elapsed = 0
    }

    /// Stops the timer and persists the elapsed time as a StudySession associated with the given topic.
    /// If the timer is running, it first folds the current interval into elapsed time.
    /// If no time was elapsed, no session will be persisted.
    /// This method treats the StudySession as the source of truth for the tracked time.
    func done(for topic: Topic)
    {
        if isRunning
        {
            pause()
        }
        let now = Date()
        let total = elapsed
        guard total > 0 else
        {
            stop()
            return
        }
        // instanciar esta clase en la vista TimerView
        let session = StudySession(topic: topic, startDate: now.addingTimeInterval(-total), endDate: now)
        if let context = context
        {
            context.insert(session)
            do
            {
                try context.save()
            }
            catch
            {
                // Handle error appropriately, e.g. log or show alert
            }
        }
        stop()
    }

    func displayTime(at date: Date) -> TimeInterval
    {
        if isRunning, let s = startDate
        {
            return elapsed + date.timeIntervalSince(s)
        }
        else
        {
            return elapsed
        }
    }

    func formatted(_ t: TimeInterval) -> String
    {
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        let centiseconds = Int((t - floor(t)) * 100)
        return String(format: "%02d:%02d,%02d", minutes, seconds, centiseconds)
    }
}
