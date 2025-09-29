import Foundation
import SwiftData

@Model
final class GoalChange
{
    // Relationship back to AppSettings (optional to allow creation before linking if needed)
    @Relationship(inverse: \AppSettings.changes) var settings: AppSettings?

    /// Goal minutes that become effective at `effectiveAt`.
    var minutes: Int

    /// The date and time when this goal becomes effective.
    /// We will typically set this to the start of the next day so changes apply from tomorrow.
    var effectiveAt: Date

    init(minutes: Int, effectiveAt: Date, settings: AppSettings? = nil)
    {
        self.minutes = minutes
        self.effectiveAt = effectiveAt
        self.settings = settings
    }
}
