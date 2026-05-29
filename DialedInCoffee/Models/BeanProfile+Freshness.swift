import Foundation

/// Lifecycle stage of a bag of beans, derived from its roast date.
/// Espresso-oriented windows: beans need a few days to de-gas, hit a peak
/// window, then gradually fade. All computed locally — no network.
public enum FreshnessStage: String, CaseIterable, Sendable {
    case unknown      // no roast date entered
    case resting      // too fresh, still de-gassing
    case peak         // prime drinking window
    case good         // still very good
    case fading       // past best, drinkable
    case stale        // well past it

    public var label: String {
        switch self {
        case .unknown: return "No roast date"
        case .resting: return "Resting"
        case .peak: return "Peak"
        case .good: return "Good"
        case .fading: return "Fading"
        case .stale: return "Stale"
        }
    }

    public var symbolName: String {
        switch self {
        case .unknown: return "calendar.badge.questionmark"
        case .resting: return "hourglass"
        case .peak: return "star.fill"
        case .good: return "checkmark.circle.fill"
        case .fading: return "clock.badge.exclamationmark"
        case .stale: return "xmark.bin"
        }
    }
}

/// A computed freshness assessment for a bean at a given moment.
public struct Freshness: Sendable, Hashable {
    public let stage: FreshnessStage
    public let daysSinceRoast: Int?

    /// Short status line, e.g. "Peak · 12 days" or "Add a roast date".
    public var summary: String {
        guard let days = daysSinceRoast else { return "Add a roast date to track freshness" }
        let dayWord = days == 1 ? "day" : "days"
        switch stage {
        case .resting:
            return "Resting · \(days) \(dayWord) — let it de-gas"
        case .peak, .good, .fading:
            return "\(stage.label) · \(days) \(dayWord) since roast"
        case .stale:
            return "Stale · \(days) \(dayWord) since roast"
        case .unknown:
            return "Add a roast date to track freshness"
        }
    }
}

public extension BeanProfile {
    /// Espresso de-gas / peak window boundaries, in days since roast.
    private enum Window {
        static let restUntil = 6      // 0–6 days: resting
        static let peakUntil = 21     // 7–21 days: peak
        static let goodUntil = 35     // 22–35 days: good
        static let fadingUntil = 60   // 36–60 days: fading; beyond: stale
    }

    /// Whole days between roast date and `now` (clamped at 0).
    func daysSinceRoast(asOf now: Date = Date()) -> Int? {
        guard let roastDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: roastDate, to: now).day ?? 0
        return max(0, days)
    }

    /// Current freshness assessment.
    func freshness(asOf now: Date = Date()) -> Freshness {
        guard let days = daysSinceRoast(asOf: now) else {
            return Freshness(stage: .unknown, daysSinceRoast: nil)
        }
        let stage: FreshnessStage
        switch days {
        case ...Window.restUntil: stage = .resting
        case ...Window.peakUntil: stage = .peak
        case ...Window.goodUntil: stage = .good
        case ...Window.fadingUntil: stage = .fading
        default: stage = .stale
        }
        return Freshness(stage: stage, daysSinceRoast: days)
    }
}
