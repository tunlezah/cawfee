import Foundation

public enum AppSection: String, CaseIterable, Hashable, Identifiable, Codable, Sendable {
    case dashboard
    case fixMyCoffee
    case shotTimer
    case machine
    case beans
    case recipes
    case tastingLog
    case ratioConverter
    case styles
    case water
    case maintenance
    case expertMode
    case history
    case settings

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .fixMyCoffee: return "Fix My Coffee"
        case .shotTimer: return "Shot Timer"
        case .machine: return "Machine"
        case .beans: return "Beans"
        case .recipes: return "Recipes"
        case .tastingLog: return "Tasting Log"
        case .ratioConverter: return "Ratio Converter"
        case .styles: return "Style Presets"
        case .water: return "Water"
        case .maintenance: return "Maintenance"
        case .expertMode: return "Expert Mode"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

    public var symbolName: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.50percent"
        case .fixMyCoffee: return "wand.and.stars"
        case .shotTimer: return "timer"
        case .machine: return "antenna.radiowaves.left.and.right"
        case .beans: return "leaf"
        case .recipes: return "book.closed"
        case .tastingLog: return "circle.hexagongrid"
        case .ratioConverter: return "divide"
        case .styles: return "cup.and.saucer"
        case .water: return "drop"
        case .maintenance: return "wrench.and.screwdriver"
        case .expertMode: return "slider.horizontal.3"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }
}
