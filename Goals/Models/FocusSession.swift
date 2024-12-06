//
//  FocusSession.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 04-12-24.
//

import Foundation

/// Manages a focus session for a given topic.
/// Keeps track of the session duration and minimizes distractions during the session.
@MainActor
class FocusSession: ObservableObject {
    /// The topic associated with the focus session.
    @Published var topic: Topic
    /// The duration of the focus session in minutes.
    @Published var duration: Int
    /// The remaining time in the focus session, in seconds.
    @Published var timeRemaining: Int
    /// The number of seconds since the beginning of the focus session.
    @Published var timeElapsed = 0
    /// Indicates whether the focus session is active.
    @Published var isActive: Bool = false

    private var timer: Timer?
    
    /// Initializes a new focus session with the given topic and duration.
    /// - Parameters:
    ///   - topic: The topic to focus on.
    ///   - duration: The duration of the session in minutes.
    init(topic: Topic, duration: Int) {
        self.topic = topic
        self.duration = duration
        self.timeRemaining = duration * 60 // Convert minutes to seconds
    }
    
    /// Starts the focus session timer.
    func start() {
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    /// Stops the focus session timer.
    func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            stop()
            // You can add additional actions here when the timer finishes.
        }
    }
}
