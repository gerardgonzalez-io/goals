//
//  StudyHistoryView.swift
//  Goals
//
//  Created by Assistant on 25-12-25.
//

import SwiftUI
import SwiftData

/**
 StudyHistoryView — Logic overview (UI + time calculations)

 UI
 - Presents a scrollable “day-by-day” study history.
 - Shows a header (title + subtitle).
 - If there are no StudySession records, displays an empty-state card.
 - Otherwise, renders one card per day:
    - Day header: calendar icon (blue gradient) + formatted date.
    - Rows: one per Topic with “studied Xh Ym”.
    - Footer: “Total for the day” with the summed duration.

 Data & Calculations
 - Source of truth: StudySession and SessionInterval records fetched via SwiftData.
 - Day grouping:
    - Completed intervals are split by calendar-day overlap.
    - One DaySection is produced per unique touched day (sorted newest -> oldest).
 - Per-day aggregation:
    - For each day, intervals are grouped by `session.topicID`.
    - Minutes are summed from interval overlap seconds.
    - Daily total is the sum of all interval overlap minutes for that day.
 - Display formatting:
    - Minutes are converted to “Xh YYm” using `durationString(_:)`.
    - Topic lines are sorted by minutes descending, then topic name.
 */
struct StudyHistoryView: View
{
    @Query(
        sort: [SortDescriptor(\StudySession.startDate, order: .reverse)]
    )
    private var sessions: [StudySession]

    @Query(sort: \Topic.name) private var topics: [Topic]


    var body: some View
    {
        ScrollView
        {
            VStack(alignment: .leading, spacing: 18)
            {
                header

                if daySections.isEmpty
                {
                    emptyState
                }
                else
                {
                    ForEach(daySections) { section in
                        dayCard(section)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Study history")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - UI

private extension StudyHistoryView
{
    var header: some View
    {
        VStack(alignment: .leading, spacing: 6)
        {
            Text("Study history")
                .font(.largeTitle.bold())

            Text("A day-by-day look at what you studied.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 6)
    }

    var emptyState: some View
    {
        SummaryCard(
            title: "No sessions yet",
            subtitle: "Start a focus session to see your daily summary here.",
            systemImage: "calendar.badge.clock",
            showsChevron: false
        )
    }

    func dayCard(_ section: DaySection) -> some View
    {
        VStack(alignment: .leading, spacing: 12)
        {
            // Day header
            HStack(spacing: 12)
            {
                ZStack
                {
                    LinearGradient(
                        colors: [Color("GoalPurple"), Color("GoalLightPurple")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2)
                {
                    Text(section.day.formatted(date: .complete, time: .omitted))
                        .font(.headline)

                    Text("Topics studied")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Topics list
            VStack(spacing: 10)
            {
                ForEach(section.lines) { line in
                    HStack(alignment: .firstTextBaseline)
                    {
                        Text(line.topicName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Text("studied \(durationString(line.minutes))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if line.id != section.lines.last?.id
                    {
                        Divider()
                            .opacity(0.5)
                    }
                }

                Divider()
                    .opacity(0.7)

                HStack
                {
                    Text("Total for the day")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(durationString(section.totalMinutes))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}

// MARK: - Data shaping

private extension StudyHistoryView
{
    struct DaySection: Identifiable
    {
        let id: Date
        let day: Date
        let lines: [TopicLine]
        let totalMinutes: Int
    }

    struct TopicLine: Identifiable
    {
        let id: UUID
        let topicName: String
        let minutes: Int
    }

    var daySections: [DaySection]
    {
        guard !sessions.isEmpty else { return [] }

        var secondsByDayAndTopic: [Date: [UUID: TimeInterval]] = [:]
        let calendar = Calendar.current

        for session in sessions
        {
            for interval in session.sessionIntervals
            {
                add(interval: interval, topicID: session.topicID, to: &secondsByDayAndTopic, calendar: calendar)
            }
        }

        let topicNames = Dictionary(uniqueKeysWithValues: topics.map { ($0.id, $0.name) })
        let sortedDays = secondsByDayAndTopic.keys.sorted(by: >)

        return sortedDays.compactMap { day in
            guard let secondsByTopic = secondsByDayAndTopic[day], !secondsByTopic.isEmpty else { return nil }

            let lines: [TopicLine] = secondsByTopic
                .map { topicID, seconds in
                    TopicLine(
                        id: topicID,
                        topicName: topicNames[topicID] ?? "Unknown topic",
                        minutes: Int(seconds / 60)
                    )
                }
                .filter { $0.minutes > 0 }
                .sorted {
                    if $0.minutes != $1.minutes { return $0.minutes > $1.minutes }
                    return $0.topicName.localizedCaseInsensitiveCompare($1.topicName) == .orderedAscending
                }

            let total = lines.reduce(0) { $0 + $1.minutes }
            guard total > 0 else { return nil }

            return DaySection(id: day, day: day, lines: lines, totalMinutes: total)
        }
    }

    func add(
        interval: SessionInterval,
        topicID: UUID,
        to secondsByDayAndTopic: inout [Date: [UUID: TimeInterval]],
        calendar: Calendar
    )
    {
        guard let endDate = interval.endDate, interval.startDate < endDate else { return }

        var currentDay = calendar.startOfDay(for: interval.startDate)

        while currentDay < endDate
        {
            guard let dayInterval = calendar.dateInterval(of: .day, for: currentDay) else { break }

            let overlapStart = max(interval.startDate, dayInterval.start)
            let overlapEnd = min(endDate, dayInterval.end)

            if overlapStart < overlapEnd
            {
                secondsByDayAndTopic[currentDay, default: [:]][topicID, default: 0] += overlapEnd.timeIntervalSince(overlapStart)
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }
    }

    func durationString(_ minutes: Int) -> String
    {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return String(format: "%dh %02dm", hours, remainingMinutes)
    }
}

#Preview("Dark")
{
    NavigationStack
    {
        StudyHistoryView()
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}

#Preview("Light")
{
    NavigationStack
    {
        StudyHistoryView()
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.light)
    }
}
