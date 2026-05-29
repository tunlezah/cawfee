import Foundation

public enum TemperatureLevel: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case low
    case normal
    case high

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }

    public func cooler() -> TemperatureLevel {
        switch self {
        case .high: return .normal
        case .normal: return .low
        case .low: return .low
        }
    }

    public func hotter() -> TemperatureLevel {
        switch self {
        case .low: return .normal
        case .normal: return .high
        case .high: return .high
        }
    }
}
