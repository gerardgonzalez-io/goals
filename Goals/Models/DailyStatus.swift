//
//  DailyStatus.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-10-25.
//

import Foundation

/// DailyStatus is a derived aggregation of StudySession (which are the source of truth).
///
/// It represents, for the set of sessions provided by the caller, a per-topic summary with:
/// - The list of topics that appear in the sessions (grouped by Topic.id)
/// - The total duration in minutes per topic (sum of all its sessions' durations)
/// - The goal snapshot in minutes per topic for that day (resolved from Topic.goalChanges using effectiveFromDay)
/// - Whether the goal was met for the day (total duration >= snapshot goalInMinutes)
///
/// The four arrays (topics, durationsInMinutes, goalInMinutes, isMet) are parallel:
/// elements at the same index refer to the same topic.
///
/// Notes:
/// - Goal snapshots are modeled with TopicGoalChange. We never recompute past days using the "current" goal.
/// - If a topic has no applicable snapshot for the computed day, goalInMinutes will be nil and isMet will be false.
/// - Returns nil if the input list of sessions is empty.
struct DailyStatus
{
    let topics: [Topic]
    let durationsInMinutes: [Int]
    let goalInMinutes: [Int?]
    let isMet: [Bool]
}

extension DailyStatus
{
    /// Computes a DailyStatus by aggregating the given study sessions.
    /// - Parameter sessions: The study sessions to aggregate. Typically sessions from the same day.
    /// - Returns: A DailyStatus with parallel arrays for topics, total durations, snapshot goal minutes, and goal attainment; or nil if `sessions` is empty.
    ///
    /// Behavior:
    /// - Groups sessions by Topic.id
    /// - Sums durations in minutes per topic
    /// - Resolves the goal snapshot for the day per topic using Topic.goalChanges (effectiveFromDay <= day)
    /// - Sets isMet to true when the total duration for the topic is greater than or equal to the resolved snapshot goal
    static func compute(from sessions: [StudySession]) -> DailyStatus?
    {
        guard !sessions.isEmpty else { return nil }

        // Assumption: callers pass sessions from the same day.
        // We anchor the computation day to the first session's normalized day (startOfDay).
        let day = sessions[0].normalizedDay

        var topics: [Topic] = []
        var durations: [Int] = []
        var goalsInMinutes: [Int?] = []
        var isGoalAchievedArray: [Bool] = []
        var indexByTopicID: [Topic.ID: Int] = [:]

        for session in sessions
        {
            let topic = session.topic
            let minutes = session.durationInMinutes

            if let index = indexByTopicID[topic.id]
            {
                durations[index] += minutes

                // Re-resolve snapshot goal for safety (in case goalChanges were updated in-memory).
                let snapshotGoal = topic.goalInMinutes(for: day)
                goalsInMinutes[index] = snapshotGoal
                isGoalAchievedArray[index] = (snapshotGoal != nil) && (durations[index] >= snapshotGoal!)
            }
            else
            {
                topics.append(topic)
                durations.append(minutes)

                let snapshotGoal = topic.goalInMinutes(for: day)
                goalsInMinutes.append(snapshotGoal)
                isGoalAchievedArray.append((snapshotGoal != nil) && (minutes >= snapshotGoal!))

                indexByTopicID[topic.id] = topics.count - 1
            }
        }

        return DailyStatus(
            topics: topics,
            durationsInMinutes: durations,
            goalInMinutes: goalsInMinutes,
            isMet: isGoalAchievedArray
        )
    }
}
