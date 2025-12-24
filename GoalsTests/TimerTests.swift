//
//  TimerTests.swift
//  GoalsTests
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-12-25.
//

import Foundation
import Testing
@testable import Goals

struct TimerTests
{

    private let snapshotKey = "timer.snapshot.v1" // matches Timer.swift

    @Test("Timer start/pause/stop affects running state and displayTime")
    @MainActor
    func timerStartPauseStop() async throws {
        UserDefaults.standard.removeObject(forKey: snapshotKey)

        let timer = Timer()
        #expect(timer.isRunning == false)
        #expect(timer.displayTime() == 0)

        timer.start()
        #expect(timer.isRunning == true)

        try await Task.sleep(nanoseconds: 120_000_000) // ~0.12s
        let t1 = timer.displayTime()
        #expect(t1 > 0)

        timer.pause()
        #expect(timer.isRunning == false)

        let frozen = timer.displayTime()
        try await Task.sleep(nanoseconds: 120_000_000)
        #expect(timer.displayTime() == frozen)

        timer.stop()
        #expect(timer.isRunning == false)
        #expect(timer.displayTime() == 0)
        #expect(timer.lengthInSeconds == 0)
        #expect(timer.lengthInMinutes == 0)
    }

    @Test("Timer.formatted outputs MM:SS,CC")
    @MainActor
    func timerFormatted()
    {
        let timer = Timer()
        #expect(timer.formatted(0) == "00:00,00")
        #expect(timer.formatted(65.12).hasPrefix("01:05,"))
    }

    @Test("Timer save/restore snapshot (not running) restores elapsed and stays paused")
    @MainActor
    func timerSnapshotNotRunning() {
        UserDefaults.standard.removeObject(forKey: snapshotKey)

        let timer = Timer()
        timer.start()
        timer.pause()
        timer.saveSnapshot()

        let restored = Timer()
        restored.restoreFromSnapshotAndResume()

        #expect(restored.isRunning == false)
        #expect(restored.displayTime() > 0)
    }

    @Test("Timer save/restore snapshot (running) resumes and recalculates elapsed during background")
    @MainActor
    func timerSnapshotRunningRecalculates() async throws {
        UserDefaults.standard.removeObject(forKey: snapshotKey)

        let timer = Timer()
        timer.start()
        try await Task.sleep(nanoseconds: 120_000_000)
        timer.saveSnapshot()

        let restored = Timer()
        restored.restoreFromSnapshotAndResume()

        #expect(restored.isRunning == true)
        let afterRestore = restored.displayTime()
        #expect(afterRestore > 0)

        try await Task.sleep(nanoseconds: 120_000_000)
        #expect(restored.displayTime() > afterRestore)
    }
}
