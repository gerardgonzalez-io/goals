import Testing
@testable import Goals

@MainActor
struct StudySessionTimerTests
{
    @Test("Start marks timer as running")
    func startMarksTimerAsRunning()
    {
        let timer = StudySessionTimer()

        timer.start()

        #expect(timer.isRunning)
        timer.reset()
    }

    @Test("Stop pauses without resetting elapsed seconds")
    func stopPausesWithoutResettingElapsedSeconds()
    {
        let timer = StudySessionTimer()
        timer.secondsElapsed = 42

        timer.start()
        timer.stop()

        #expect(!timer.isRunning)
        #expect(timer.secondsElapsed == 42)
    }

    @Test("Reset stops and clears elapsed seconds")
    func resetStopsAndClearsElapsedSeconds()
    {
        let timer = StudySessionTimer()
        timer.secondsElapsed = 42

        timer.start()
        timer.reset()

        #expect(!timer.isRunning)
        #expect(timer.secondsElapsed == 0)
    }
}
