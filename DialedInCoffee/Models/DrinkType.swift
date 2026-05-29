import Foundation

public enum DrinkType: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case flatWhite
    case cappuccino
    case latte
    case longBlack
    case espresso

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .flatWhite: return "Flat White"
        case .cappuccino: return "Cappuccino"
        case .latte: return "Latte"
        case .longBlack: return "Long Black"
        case .espresso: return "Espresso"
        }
    }

    public var isMilkBased: Bool {
        switch self {
        case .flatWhite, .cappuccino, .latte: return true
        case .longBlack, .espresso: return false
        }
    }

    public var symbolName: String {
        switch self {
        case .flatWhite: return "cup.and.saucer.fill"
        case .cappuccino: return "cup.and.saucer.fill"
        case .latte: return "mug.fill"
        case .longBlack: return "cup.and.saucer"
        case .espresso: return "cup.and.saucer"
        }
    }
}
