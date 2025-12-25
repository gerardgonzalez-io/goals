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
 - Source of truth: StudySession fetched via SwiftData (@Query), sorted by startDate descending.
 - Day grouping:
    - Sessions are grouped by `session.normalizedDay` (startOfDay for startDate).
    - One DaySection is produced per unique normalized day (sorted newest → oldest).
 - Per-day aggregation:
    - For each day, sessions are grouped by `session.topic.id`.
    - Minutes are summed using `session.durationInMinutes`.
    - Daily total is the sum of all sessions’ minutes for that day.
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

    private var brandLight: Color
    {
        Color(red: 63/255, green: 167/255, blue: 214/255) // #3FA7D6
    }
    private var brandDark: Color
    {
        Color(red: 29/255, green: 53/255, blue: 87/255)   // #1D3557
    }

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
        VStack(alignment: .leading, spacing: 10)
        {
            HStack(spacing: 12)
            {
                ZStack
                {
                    LinearGradient(
                        colors: [brandDark, brandLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3)
                {
                    Text("No sessions yet")
                        .font(.headline)

                    Text("Start a focus session to see your daily summary here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
            )
        }
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
                        colors: [brandDark, brandLight],
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

        // Group sessions by normalized day
        let grouped = Dictionary(grouping: sessions, by: { $0.normalizedDay })

        // Build day sections (sorted newest -> oldest)
        let sortedDays = grouped.keys.sorted(by: >)

        return sortedDays.compactMap { day in
            guard let daySessions = grouped[day], !daySessions.isEmpty else { return nil }

            // Group by topic.id and sum minutes
            var minutesByTopic: [UUID: (name: String, minutes: Int)] = [:]
            var total = 0

            for s in daySessions
            {
                let m = s.durationInMinutes
                total += m

                let topicID = s.topic.id
                let name = s.topic.name

                if let existing = minutesByTopic[topicID]
                {
                    minutesByTopic[topicID] = (name: existing.name, minutes: existing.minutes + m)
                }
                else
                {
                    minutesByTopic[topicID] = (name: name, minutes: m)
                }
            }

            // Sort topics by minutes desc, then name
            let lines: [TopicLine] = minutesByTopic
                .map { (topicID, value) in
                    TopicLine(id: topicID, topicName: value.name, minutes: value.minutes)
                }
                .sorted {
                    if $0.minutes != $1.minutes { return $0.minutes > $1.minutes }
                    return $0.topicName.localizedCaseInsensitiveCompare($1.topicName) == .orderedAscending
                }

            return DaySection(id: day, day: day, lines: lines, totalMinutes: total)
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
