//
//  DailyStatus.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-10-25.
//

/// DailyStatus is a derived aggregation of StudySession (which are the source of truth).
///
/// It represents, for the set of sessions provided by the caller, a per-topic summary with:
/// - The list of topics that appear in the sessions (grouped by Topic.id)
/// - The total duration in minutes per topic (sum of all its sessions' durations)
/// - The most recent goal per topic (chosen by goal.createdAt among the provided sessions)
/// - Whether the goal was met for the day (total duration >= selected goal's goalInMinutes)
///
/// The four arrays (topics, durationsInMinutes, goals, isMet) are parallel: elements at the same index refer to the same topic.
/// The function returns nil if the input list of sessions is empty.
struct DailyStatus
{
    let topics: [Topic]
    let durationsInMinutes: [Int]
    let goals: [Goal]
    let isMet: [Bool]
}

extension DailyStatus
{
    /// Computes a DailyStatus by aggregating the given study sessions.
    /// - Parameter sessions: The study sessions to aggregate. Typically sessions from the same day.
    /// - Returns: A DailyStatus with parallel arrays for topics, total durations, most recent goals, and goal attainment; or nil if `sessions` is empty.
    ///
    /// Behavior:
    /// - Groups sessions by Topic.id
    /// - Sums durations in minutes per topic
    /// - Selects the most recent goal per topic using Goal.createdAt
    /// - Sets isMet to true when the total duration for the topic is greater than or equal to the selected goal's goalInMinutes
    static func compute(from sessions: [StudySession]) -> DailyStatus?
    {
        guard !sessions.isEmpty else { return nil }
        var topics: [Topic] = []
        var durations: [Int] = []
        var goals: [Goal] = []
        var isGoalAchievedArray: [Bool] = []
        var indexByTopicID: [Topic.ID: Int] = [:]

        for session in sessions
        {
            let topic = session.topic
            let durationsInMinutes = session.durationInMinutes
            let goal = session.goal
            let isGoalAchived = durationsInMinutes >= goal.goalInMinutes

            if let index = indexByTopicID[topic.id]
            {
                // Means that the topic already exists
                if goal.createdAt > goals[index].createdAt
                {
                    goals[index] = goal
                }
                durations[index] += durationsInMinutes
                isGoalAchievedArray[index] = durations[index] >= goals[index].goalInMinutes
            }
            else
            {
                // New topic, added
                topics.append(topic)
                durations.append(durationsInMinutes)
                goals.append(goal)
                isGoalAchievedArray.append(isGoalAchived)
                // the dictionary value is equivalent to index of array, so the arrays keeps parallels
                indexByTopicID[topic.id] = topics.count - 1
            }
        }
        return DailyStatus(
            topics: topics,
            durationsInMinutes: durations,
            goals: goals,
            isMet: isGoalAchievedArray
        )
    }
}
