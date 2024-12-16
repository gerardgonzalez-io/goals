//
//  TopicManager.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 04-12-24.
//

import Foundation

/// Manages the user's topics, goals, and tracking of time spent.
/// Allows adding and removing topics, recording topic sessions, and checking goals.
@MainActor
@Observable
class TopicManager {
    /// The list of tipics the user is tracking.
    var topics: [Topic] = load("goalsData.json")
    
    /// Adds a new topic to the list.
    /// - Parameter topic: The topic to add.
    func addTopic(_ topic: Topic) {
        topics.append(topic)
    }
    
    /// Removes a topic from the list.
    /// - Parameter topic: The topic to remove.
    func removeTopic(_ topic: Topic) {
        topics.removeAll { $0.id == topic.id }
    }
    
    /// Retrieves the topic with the given ID.
    /// - Parameter id: The unique identifier of the topic.
    /// - Returns: The topic if found, or nil.
    func getTopic(by id: UUID) -> Topic? {
        return topics.first { $0.id == id }
    }
    
    /// Records a new topic session in the history.
    /// - Parameters:
    ///   - topicID: The unique identifier of the topic.
    ///   - duration: The duration of the session in minutes.
    func recordTopicSession(topicId: UUID, duration: Int) {
        if let index = topics.firstIndex(where: { $0.id == topicId }) {
            let newHistoryEntry = TopicHistory(date: Date(), duration: duration)
            topics[index].history.append(newHistoryEntry)
        }
    }
    
    /// Gets the total time spent on a topic in the current week.
    /// - Parameter topic: The topic to calculate the total for.
    /// - Returns: The total duration in minutes spent on the topic in the current week.
    func weeklyTotal(for topic: Topic) -> Int {
        let calendar = Calendar.current
        let weekStart = calendar.startOfDay(for: Date()).addingTimeInterval(-6 * 24 * 60 * 60)
        let weeklyHistory = topic.history.filter { $0.date >= weekStart }
        let totalDuration = weeklyHistory.reduce(0) { $0 + $1.durationInMinutes }
        return totalDuration
    }
    
    /// Checks if the topic goal was met for a given day.
    /// - Parameters:
    ///   - topic: The topic to check.
    ///   - date: The date to check, defaulting to today.
    /// - Returns: True if the goal was met, false otherwise.
    func isGoalMet(for topic: Topic, on date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let dailyHistory = topic.history.filter { $0.date >= dayStart && $0.date < dayEnd }
        let totalDuration = dailyHistory.reduce(0) { $0 + $1.durationInMinutes }
        return Double(totalDuration) >= topic.goal.dailyMinutesGoal
    }
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data


    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }


    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }


    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
