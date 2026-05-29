import Foundation

public enum RoastLevel: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case light
    case mediumLight
    case medium
    case mediumDark
    case dark

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .light: return "Light"
        case .mediumLight: return "Medium-Light"
        case .medium: return "Medium"
        case .mediumDark: return "Medium-Dark"
        case .dark: return "Dark"
        }
    }
}

public struct BeanSnapshot: Codable, Hashable, Sendable, Identifiable {
    public var id: String          // stable slug
    public var name: String
    public var roaster: String
    public var roastLevel: RoastLevel
    public var milkFriendly: Bool
    public var flavourNotes: [String]
    public var recommendedSettings: MachineSettings

    public init(
        id: String,
        name: String,
        roaster: String,
        roastLevel: RoastLevel,
        milkFriendly: Bool,
        flavourNotes: [String],
        recommendedSettings: MachineSettings
    ) {
        self.id = id
        self.name = name
        self.roaster = roaster
        self.roastLevel = roastLevel
        self.milkFriendly = milkFriendly
        self.flavourNotes = flavourNotes
        self.recommendedSettings = recommendedSettings
    }
}
