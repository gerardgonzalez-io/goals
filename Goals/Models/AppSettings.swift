import Foundation
import SwiftData

/// A SwiftData model representing app-wide settings.
@Model
final class AppSettings
{
    var dailyStudyGoalMinutes: Int
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
