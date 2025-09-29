import Foundation
import SwiftData

/// A SwiftData model representing app-wide settings.
@Model
final class AppSettings
{
    var dailyStudyGoalMinutes: Int
    @Relationship var changes: [GoalChange] = []
    var createdAt: Date
    var modifiedAt: Date

    init(
        dailyStudyGoalMinutes: Int = 15,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.dailyStudyGoalMinutes = dailyStudyGoalMinutes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
    
    static let sampleData: [AppSettings] = [
        AppSettings(dailyStudyGoalMinutes: 10)
    ]
}

extension AppSettings
{
    /// Default daily study goal minutes. Adjust this value as needed.
    static let defaultGoalMinutes = 15
}

extension AppSettings
{
    /// Returns the goal minutes that were effective on the given date.
    /// If there is a change with effectiveAt <= date, we use the most recent one; otherwise fallback to current value or default.
    func goalMinutes(effectiveOn date: Date) -> Int
    {
        // Find the most recent change whose effective date is on or before the given date
        if let change = changes
            .filter({ $0.effectiveAt <= date })
            .max(by: { $0.effectiveAt < $1.effectiveAt })
        {
            return change.minutes
        }
        return dailyStudyGoalMinutes
    }
}
