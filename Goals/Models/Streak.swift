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
 - The current streak is computed from calendar days derived from StudySession.normalizedDay.
 - Missing days (no sessions recorded) are treated as failures and break the streak.
 - The anchor day is flexible: if today is already met, we anchor at today; otherwise, we anchor at yesterday (the last fully completed day) and count backwards.
 - The rule for a day being "met" is currently: at least one topic's goal was met for that day (see isDayMet).
 - We do not persist explicit "failure" records (e.g., days without sessions or unmet goals). Instead, streak values are computed dynamically from existing StudySession records whenever needed.

 Technical notes
 - Day normalization is delegated to StudySession.normalizedDay to avoid duplicate normalization logic and timezone drift.
 - DailyStatus.compute(from:) aggregates sessions per topic within a day and exposes `isMet` per topic; we derive a single boolean per day via isDayMet.
 - The computation builds a [Date: Bool] map (metByDay) using normalized days and iterates backward from the chosen anchor, stopping on gaps or unmet days.
*/

/// Streak encapsulates streak metrics derived from study sessions.
/// - `sessions`: the raw list of StudySession instances used to compute streaks.
/// - Exposes global streaks and per-topic streaks computed from the same source of truth.
struct Streak
{
    
    let sessions: [StudySession]

    var isCurrentStreakActive: Bool { self.currentStreak > 0 }

    /// Longest historical streak across all normalized days in `sessions`.
    ///
    /// Computes the maximum length of any consecutive run of met days.
    /// Days without sessions count as gaps and break the streak.
    /// The computation is derived from sessions (no persistence required).
    var longestStreak: Int
    {
        let perDay = dailyStatusesByDay(from: self.sessions)
        let metByDay: [Date: Bool] = Dictionary(
            uniqueKeysWithValues: perDay.map { ($0.day, isDayMet($0.status)) }
        )

        // Reutiliza el algoritmo genérico de longest streak.
        return longestStreak(using: metByDay)
    }

    /// Current streak computed from normalized calendar days.
    ///
    /// Functional behavior:
    /// - Uses StudySession.normalizedDay as the single source of truth for day boundaries.
    /// - Builds a per-day map of whether the goal was met.
    /// - Anchor selection is flexible: if today is met, anchor at today; otherwise anchor at yesterday (last fully completed day).
    /// - Missing days (no sessions) are treated as failures and break the streak.
    ///
    /// Technical details:
    /// - Aggregates sessions per day with `dailyStatusesByDay(from:)` and flattens `DailyStatus.isMet` via `isDayMet`.
    /// - Iterates backwards from the anchor day using Calendar.current, comparing against the `metByDay` dictionary.
    var currentStreak: Int
    {
        let perDay = dailyStatusesByDay(from: self.sessions)
        let metByDay: [Date: Bool] = Dictionary(
            uniqueKeysWithValues: perDay.map { ($0.day, isDayMet($0.status)) }
        )

        // Reutiliza el algoritmo genérico de current streak.
        return currentStreak(using: metByDay)
    }
    // =========================================================
    // NUEVA FEATURE: RACHAS POR TOPIC
    // =========================================================

    /// Current streak para un topic específico.
    /// - Usa las mismas reglas del streak global, pero
    ///   el "met" del día se calcula SOLO para ese topic.
    /// - Si el topic no tiene sesiones ese día, el día se considera no met.
    func currentStreak(for topic: Topic) -> Int
    {
        currentStreak(for: topic.id)
    }

    /// Current streak para un topic específico por ID.
    func currentStreak(for topicID: Topic.ID) -> Int
    {
        let perDay = dailyStatusesByDay(from: self.sessions)

        // Para cada día, evaluamos si el topic específico cumplió su meta.
        let metByDay: [Date: Bool] = Dictionary(
            uniqueKeysWithValues: perDay.map { ($0.day, isTopicMet(for: topicID, $0.status)) }
        )

        return currentStreak(using: metByDay)
    }

    /// Longest streak histórico para un topic específico.
    func longestStreak(for topic: Topic) -> Int
    {
        longestStreak(for: topic.id)
    }

    /// Longest streak histórico para un topic específico por ID.
    func longestStreak(for topicID: Topic.ID) -> Int
    {
        let perDay = dailyStatusesByDay(from: self.sessions)

        // Para cada día, evaluamos si el topic específico cumplió su meta.
        let metByDay: [Date: Bool] = Dictionary(
            uniqueKeysWithValues: perDay.map { ($0.day, isTopicMet(for: topicID, $0.status)) }
        )

        return longestStreak(using: metByDay)
    }
}

// =========================================================
// HELPERS REUTILIZABLES (GLOBAL + POR TOPIC)
// =========================================================
private extension Streak
{
    /// Algoritmo genérico de longest streak basado en un mapa day -> met.
    /// - Reutilizable para el streak global y por-topic.
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
                    // Día consecutivo
                    current = met ? (current + 1) : 0
                }
                else if diff > 1
                {
                    // Gap: reinicia streak solo si el día actual está met
                    current = met ? 1 : 0
                }
                else
                {
                    // Mismo día duplicado (defensivo)
                    current = met ? max(current, 1) : current
                }
            }
            else
            {
                // Primer día
                current = met ? 1 : 0
            }

            longest = max(longest, current)
            previousDay = day
        }

        return longest
    }

    /// Algoritmo genérico de current streak basado en un mapa day -> met.
    /// - Respeta el anchor flexible:
    ///   si hoy está met -> anchor hoy, sino anchor ayer.
    func currentStreak(using metByDay: [Date: Bool]) -> Int
    {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
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

            // Si el día no existe en el mapa, significa que no hubo sesiones para ese eje.
            guard let met = metByDay[dayStart] else { break }
            guard met else { break }

            streak += 1
            offset += 1
        }

        return streak
    }

    /// Determina si un día está "met" para un topic específico dentro de un DailyStatus.
    /// - Si el topic no aparece en ese día, retorna false.
    /// - Respeta la estructura paralela de DailyStatus (topics/isMet).
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
/// Sessions are first grouped by `StudySession.normalizedDay` (already normalized), then `DailyStatus.compute(from:)` is applied per group.
/// The result contains one entry per unique normalized day.
private func dailyStatusesByDay(from sessions: [StudySession]) -> [(day: Date, status: DailyStatus)]
{
    // Group sessions by their already-normalized day (skip sessions without startDate)
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

/// Determines if a day is considered "met" based on DailyStatus.
/// Current rule: returns true if at least one topic's goal was met (`contains(true)`).
/// Adjust to `allSatisfy` if the business rule requires all topics to be met.
private func isDayMet(_ status: DailyStatus) -> Bool
{
    return status.isMet.contains(true)
}
