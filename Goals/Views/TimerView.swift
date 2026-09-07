//
//  TimerView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-10-25.
//

import SwiftUI
import SwiftData

struct TimerView: View
{
    @Environment(\.modelContext) private var modelContext

    @Bindable var timer: StudySessionTimer

    /// Topic que viene desde TopicDetailView
    let preselectedTopic: Topic

    @State private var selectedTopic: Topic? = nil
    @State private var activeSession: StudySession? = nil
    @State private var activeInterval: SessionInterval? = nil
    @State private var didAutoStart = false

    init(timer: StudySessionTimer, preselectedTopic: Topic)
    {
        self._timer = Bindable(wrappedValue: timer)
        self.preselectedTopic = preselectedTopic
    }

    var body: some View
    {
        GeometryReader { geo in
            let dialSize = min(geo.size.width, geo.size.height) * 0.82
            let elapsedTime = TimeInterval(timer.secondsElapsed)

            VStack(spacing: 28)
            {
                topicHeader

                Divider()
                    .opacity(0.15)

                Group
                {
                    TimerDialView(time: elapsedTime)
                        .frame(width: dialSize, height: dialSize)
                        .padding(.top, 4)

                    Text(formatted(elapsedTime))
                        .font(.system(size: 40, weight: .medium, design: .monospaced))
                        .padding(.top, 8)
                }

                Spacer(minLength: 16)

                controlButtons
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        .onAppear
        {
            selectedTopic = preselectedTopic

            guard !didAutoStart else { return }
            startSessionIfNeeded()
            didAutoStart = true
        }
        .onDisappear
        {
            stopSession()
        }
    }
}

private extension TimerView
{
    var topicHeader: some View
    {
        TimerTopicCard(topicName: preselectedTopic.name)
    }

    var controlButtons: some View
    {
        HStack
        {
            let stopEnabled = activeSession != nil
            let startEnabled = selectedTopic != nil

            Button
            {
                stopSession()
            }
            label:
            {
                Circle()
                    .fill(stopEnabled
                          ? AnyShapeStyle(successGradient)
                          : AnyShapeStyle(Color(.secondarySystemFill)))
                    .frame(width: 96, height: 96)
                    .shadow(color: stopEnabled ? successShadow : .clear,
                            radius: 16, x: 0, y: 8)
                    .overlay(
                        Text("Stop")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(stopEnabled ? Color.white : Color.secondary)
                    )
            }
            .disabled(!stopEnabled)

            Spacer()

            Button
            {
                toggleTimerInterval()
            }
            label:
            {
                let running = timer.isRunning
                let title = activeSession == nil ? "Start" : (running ? "Pause" : "Resume")

                Circle()
                    .fill(
                        !startEnabled
                        ? AnyShapeStyle(Color(.secondarySystemFill))
                        : (running
                           ? AnyShapeStyle(brandGradient)
                           : AnyShapeStyle(successGradient))
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: startEnabled ? brandShadow : .clear,
                            radius: 16, x: 0, y: 8)
                    .overlay(
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(startEnabled ? Color.white : Color.secondary)
                    )
            }
            .disabled(!startEnabled)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 32)
    }
}

private extension TimerView
{
    var brandGradient: LinearGradient
    {
        LinearGradient(
            colors: [
                Color("GoalLightPurple"),
                Color("GoalPurple")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var successGradient: LinearGradient
    {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.65, blue: 0.45),
                Color(red: 0.16, green: 0.80, blue: 0.60)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var brandShadow: Color
    {
        Color.black.opacity(0.25)
    }

    var successShadow: Color
    {
        Color.black.opacity(0.25)
    }
}

private extension TimerView
{
    func normalizedNow() -> Date
    {
        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = .current
        let now = Date()
        return calendarWithTimeZone.date(bySetting: .nanosecond, value: 0, of: now) ?? now
    }

    func startSessionIfNeeded()
    {
        guard activeSession == nil, let topic = selectedTopic else { return }

        let now = normalizedNow()
        let interval = SessionInterval(startDate: now)
        let session = StudySession(
            topicID: topic.id,
            startDate: now,
            sessionIntervals: [interval]
        )

        modelContext.insert(session)
        activeSession = session
        activeInterval = interval
        timer.start()
        saveContext()
    }

    func closeActiveInterval(at endDate: Date)
    {
        guard let interval = activeInterval else { return }

        interval.endDate = max(interval.startDate, endDate)
        interval.updatedAt = endDate
        activeInterval = nil
    }

    func pauseSession()
    {
        guard timer.isRunning else { return }

        let now = normalizedNow()
        closeActiveInterval(at: now)
        timer.stop()
        saveContext()
    }

    func resumeSession()
    {
        guard let session = activeSession, activeInterval == nil else { return }

        let now = normalizedNow()
        let interval = SessionInterval(startDate: now, studySession: session)
        session.sessionIntervals.append(interval)
        session.updatedAt = now
        activeInterval = interval
        timer.start()
        saveContext()
    }

    func stopSession()
    {
        guard let session = activeSession else { return }

        let now = normalizedNow()
        closeActiveInterval(at: now)
        session.endDate = max(session.startDate, now)
        session.updatedAt = now
        timer.reset()
        activeSession = nil
        activeInterval = nil
        saveContext()
    }

    func toggleTimerInterval()
    {
        if activeSession == nil
        {
            startSessionIfNeeded()
        }
        else if timer.isRunning
        {
            pauseSession()
        }
        else
        {
            resumeSession()
        }
    }

    func formatted(_ time: TimeInterval) -> String
    {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d,00", minutes, seconds)
    }

    func saveContext()
    {
        do
        {
            try modelContext.save()
        }
        catch
        {
            #if DEBUG
            print("Failed to save study session timer state: \(error)")
            #endif
        }
    }
}

#Preview("Dark")
{
    TimerView(timer: StudySessionTimer(), preselectedTopic: SampleData.shared.topic)
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    TimerView(timer: StudySessionTimer(), preselectedTopic: SampleData.shared.topic)
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
}
