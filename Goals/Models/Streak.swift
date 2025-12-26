//
//  Streak.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-10-25.
//

import Foundation

/**
 Functional overview
 - Streak represents streak-related metrics calculated from StudySession as the single source of truth.
 - Streaks are computed per topic using calendar days derived from StudySession.normalizedDay.
 - Missing days (no sessions recorded for that topic) are treated as failures and break the streak.
 - The anchor day is flexible per topic: if today is met for that topic, we anchor at today;
   otherwise, we anchor at yesterday (the last fully completed day) and count backwards.
 - We do not persist explicit "failure" records (e.g., days without sessions or unmet goals).
   Instead, streak values are computed dynamically from existing StudySession records whenever needed.

 Technical notes
 - Day normalization is delegated to StudySession.normalizedDay to avoid duplicate normalization logic and timezone drift.
 - DailyStatus.compute(from:) aggregates sessions per topic within a day and exposes `isMet` per topic.
 - For a given topic, we build a [Date: Bool] map (metByDay) and reuse generic streak algorithms.
 - Performance: we compute one DailyStatus per day (not per topic) and reuse it across per-topic calculations.
*/

/// Streak encapsulates per-topic streak metrics derived from study sessions.
/// - `sessions`: the raw list of StudySession instances used to compute streaks.
struct Streak
{
    let sessions: [StudySession]

    /// Current streak for a specific topic.
    /// - Uses the same anchor rule as before, but computed ONLY for the given topic:
    ///   if today is met for that topic -> anchor today, else anchor yesterday.
    /// - If the topic has no sessions on a day, that day is treated as missing and breaks the streak.
    func currentStreak(for topic: Topic) -> Int
    {
        currentStreak(for: topic.id)
    }

    /// Current streak for a specific topic by ID.
    func currentStreak(for topicID: Topic.ID) -> Int
    {
        let metByDay = metByDayForTopic(topicID)
        return currentStreak(using: metByDay)
    }

    /// Longest historical streak for a specific topic.
    func longestStreak(for topic: Topic) -> Int
    {
        longestStreak(for: topic.id)
    }

    /// Longest historical streak for a specific topic by ID.
    func longestStreak(for topicID: Topic.ID) -> Int
    {
        let metByDay = metByDayForTopic(topicID)
        return longestStreak(using: metByDay)
    }
}

// =========================================================
// INTERNALS
// =========================================================
private extension Streak
{
    /// Builds a day -> met map for a specific topic.
    ///
    /// Performance note:
    /// - We compute a DailyStatus once per day and then read the topic's `isMet` from it.
    /// - This avoids re-resolving topic goals or scanning sessions repeatedly.
    func metByDayForTopic(_ topicID: Topic.ID) -> [Date: Bool]
    {
        let perDay = dailyStatusesByDay(from: sessions)
        return Dictionary(
            uniqueKeysWithValues: perDay.map { ($0.day, isTopicMet(for: topicID, $0.status)) }
        )
    }

    /// Generic longest-streak algorithm based on a day -> met map.
    func longestStreak(using metByDay: [Date: Bool]) -> Int
    {
        let calendar = Calendar.current
        let sortedDays = metByDay.keys.sorted()

        var longest = 0
        var current = 0
        var previousDay: Date? = nil

        for day in sortedDays
        {
            let met = metByDay[day] == true

            if let prev = previousDay
            {
                let diff = calendar.dateComponents([.day], from: prev, to: day).day ?? 0

                if diff == 1
                {
                    // Consecutive day
                    current = met ? (current + 1) : 0
                }
                else if diff > 1
                {
                    // Gap: restart only if the current day is met
                    current = met ? 1 : 0
                }
                else
                {
                    // Same day duplicate (defensive)
                    current = met ? max(current, 1) : current
                }
            }
            else
            {
                // First day
                current = met ? 1 : 0
            }

            longest = max(longest, current)
            previousDay = day
        }

        return longest
    }

    /// Generic current-streak algorithm based on a day -> met map.
    /// - Flexible anchor:
    ///   if today is met -> anchor today, else anchor yesterday.
    func currentStreak(using metByDay: [Date: Bool]) -> Int
    {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        guard
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
                .map({ calendar.startOfDay(for: $0) })
        else
        {
            return 0
        }

        let anchor: Date = (metByDay[today] == true) ? today : yesterday

        var streak = 0
        var offset = 0

        while true
        {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: anchor) else { break }
            let dayStart = calendar.startOfDay(for: day)

            // If the day doesn't exist in the map, there were no sessions for this topic that day -> break.
            guard let met = metByDay[dayStart] else { break }
            guard met else { break }

            streak += 1
            offset += 1
        }

        return streak
    }

    /// Returns whether a given day is met for a specific topic within a DailyStatus.
    /// - If the topic does not appear in that day, returns false.
    /// - Respects DailyStatus' parallel arrays (topics/isMet).
    func isTopicMet(for topicID: Topic.ID, _ status: DailyStatus) -> Bool
    {
        for (idx, topic) in status.topics.enumerated()
        {
            if topic.id == topicID
            {
                guard idx < status.isMet.count else { return false }
                return status.isMet[idx]
            }
        }
        return false
    }
}

/// Computes DailyStatus per normalized day.
/// Sessions are first grouped by `StudySession.normalizedDay` (already normalized),
/// then `DailyStatus.compute(from:)` is applied per group.
/// The result contains one entry per unique normalized day.
private func dailyStatusesByDay(from sessions: [StudySession]) -> [(day: Date, status: DailyStatus)]
{
    var grouped: [Date: [StudySession]] = [:]
    for session in sessions
    {
        let day = session.normalizedDay
        grouped[day, default: []].append(session)
    }

    var result: [(Date, DailyStatus)] = []
    for (day, daySessions) in grouped
    {
        if let status = DailyStatus.compute(from: daySessions)
        {
            result.append((day, status))
        }
    }

    result.sort { $0.0 < $1.0 }
    return result
}
