import Foundation
import SwiftData

public enum UserMode: String, Codable, CaseIterable, Sendable, Identifiable {
    case novice
    case expert

    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .novice: return "Novice"
        case .expert: return "Expert"
        }
    }
}

public enum AppearancePreference: String, Codable, CaseIterable, Sendable, Identifiable {
    case system
    case light
    case dark

    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .system: return "Match System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

@Model
public final class UserPreferences {
    @Attribute(.unique) public var singletonKey: String
    public var userModeRaw: String
    public var defaultMilkKindRaw: String
    public var defaultDrinkRaw: String
    public var appearanceRaw: String
    public var hasSeededBeans: Bool
    public var hasCompletedOnboarding: Bool
    public var machineName: String

    public init(
        singletonKey: String = "default",
        userMode: UserMode = .novice,
        defaultMilkKind: MilkKind = .devondaleFullCreamUHT,
        defaultDrink: DrinkType = .cappuccino,
        appearance: AppearancePreference = .system,
        hasSeededBeans: Bool = false,
        hasCompletedOnboarding: Bool = false,
        machineName: String = ""
    ) {
        self.singletonKey = singletonKey
        self.userModeRaw = userMode.rawValue
        self.defaultMilkKindRaw = defaultMilkKind.rawValue
        self.defaultDrinkRaw = defaultDrink.rawValue
        self.appearanceRaw = appearance.rawValue
        self.hasSeededBeans = hasSeededBeans
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.machineName = machineName
    }

    public var userMode: UserMode {
        get { UserMode(rawValue: userModeRaw) ?? .novice }
        set { userModeRaw = newValue.rawValue }
    }
    public var defaultMilkKind: MilkKind {
        get { MilkKind(rawValue: defaultMilkKindRaw) ?? .devondaleFullCreamUHT }
        set { defaultMilkKindRaw = newValue.rawValue }
    }
    public var defaultDrink: DrinkType {
        get { DrinkType(rawValue: defaultDrinkRaw) ?? .cappuccino }
        set { defaultDrinkRaw = newValue.rawValue }
    }
    public var appearance: AppearancePreference {
        get { AppearancePreference(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}
