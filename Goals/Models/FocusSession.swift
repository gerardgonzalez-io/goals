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
    @Published var durationInMinutes: Int = 0
    /// The number of seconds that have elapsed since the start of the session.
    @Published var secondsElapsed: Int = 0
    /// The number of seconds remaining in the session.
    @Published var secondsRemaining: Int = 0
    /// The time spent studying the topic.
    @Published var timeSpend: TimeSpend
    /// Indicates whether the focus session is active.
    @Published var isActive: Bool = false

    /// The date when the session started, used to calculate elapsed time.
    private var startDate: Date?
    /// A frequency for the timer updates, default once per second.
    private var frequency: TimeInterval { 1.0 }
    private var timer: Timer?
    private var timerStopped = false

    /// Convert the total duration from minutes to seconds.
    private var durationInSeconds: Int {
        durationInMinutes * 60
    }

    /// Compute the remaining minutes from the remaining seconds.
    var minutesRemaining: Int {
        secondsRemaining / 60
    }

    /// Initializes a new focus session with the given topic and duration.
    /// - Parameters:
    ///   - topic: The topic to focus on.
    init(topic: Topic = Topic(), durationInMinutes: Int = 0, timeSpend: TimeSpend = TimeSpend(dailyMinutesSpend: 0)) {
        self.topic = topic
        self.durationInMinutes = durationInMinutes
        self.timeSpend = timeSpend
    }

    /// Starts the focus session timer.
    func start() {
        isActive = true
        timerStopped = false
        // Record the start date.
        startDate = Date()

        // Initialize secondsElapsed and secondsRemaining.
        secondsElapsed = 0
        //secondsRemaining = durationInSeconds // Set initial remaining time in seconds

        // Schedule the timer to run at the given frequency.
        timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.update()
            }
        }
        timer?.tolerance = 0.1
    }
    
    /// Stops the focus session timer.
    func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
        timerStopped = true
    }
    
    /// Updates the elapsed and remaining time by comparing current time to the start date.
    private func update() {
        guard let startDate, !timerStopped else { return }

        // Calculate how many seconds have passed since the start of the session.
        let elapsed = Int(Date().timeIntervalSince1970 - startDate.timeIntervalSince1970)
        secondsElapsed = elapsed
        secondsRemaining = max(durationInSeconds - secondsElapsed, 0)

        // If one full minute has passed, update the dailyMinutesSpend.
        if secondsElapsed % 60 == 0 {
            // Convert elapsed seconds to minutes
            let minutesSpent = Double(secondsElapsed) / 60.0
            // Update timeSpend with the new calculated minutes
            timeSpend.dailyMinutesSpend = minutesSpent
        }

        // If no time remains, stop the session.
        if secondsRemaining <= 0 {
            stop()
        }
    }
    
    /**
     Reset the timer with a new focus session.
     
     - Parameters:
         - durationInMinutes: The meeting duration.
         - topic: The topic of the focus session.
     */
    func reset(durationInMinutes: Int, topic: Topic) {
        self.durationInMinutes = durationInMinutes
        self.topic = topic
        secondsRemaining = durationInSeconds
    }
}
