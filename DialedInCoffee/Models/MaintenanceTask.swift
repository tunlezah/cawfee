import Foundation
import SwiftData

/// A recurring espresso-machine maintenance task (backflush, descale, etc.).
/// Due-ness is computed from a calendar interval and/or a shot-count interval,
/// whichever falls first. Fully local.
@Model
public final class MaintenanceTask {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var detail: String
    public var symbolName: String

    /// Recurrence by calendar days (nil = not time-based).
    public var intervalDays: Int?
    /// Recurrence by shot count (nil = not count-based).
    public var intervalShots: Int?

    public var lastCompletedDate: Date?
    public var lastCompletedShotCount: Int

    public var isSeeded: Bool
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        name: String,
        detail: String = "",
        symbolName: String = "wrench.and.screwdriver",
        intervalDays: Int? = nil,
        intervalShots: Int? = nil,
        lastCompletedDate: Date? = nil,
        lastCompletedShotCount: Int = 0,
        isSeeded: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.symbolName = symbolName
        self.intervalDays = intervalDays
        self.intervalShots = intervalShots
        self.lastCompletedDate = lastCompletedDate
        self.lastCompletedShotCount = lastCompletedShotCount
        self.isSeeded = isSeeded
        self.sortOrder = sortOrder
    }

    /// Days remaining until the time-based interval is due (negative = overdue).
    public func daysUntilDue(asOf now: Date = Date()) -> Int? {
        guard let intervalDays else { return nil }
        guard let last = lastCompletedDate else { return 0 } // never done → due now
        let elapsed = Calendar.current.dateComponents([.day], from: last, to: now).day ?? 0
        return intervalDays - elapsed
    }

    /// Shots remaining until the count-based interval is due (negative = overdue).
    public func shotsUntilDue(currentShotCount: Int) -> Int? {
        guard let intervalShots else { return nil }
        let elapsed = currentShotCount - lastCompletedShotCount
        return intervalShots - elapsed
    }

    /// Whether the task is due or overdue right now.
    public func isDue(asOf now: Date = Date(), currentShotCount: Int) -> Bool {
        if let d = daysUntilDue(asOf: now), d <= 0 { return true }
        if let s = shotsUntilDue(currentShotCount: currentShotCount), s <= 0 { return true }
        return false
    }

    public func markDone(asOf now: Date = Date(), currentShotCount: Int) {
        lastCompletedDate = now
        lastCompletedShotCount = currentShotCount
    }
}
