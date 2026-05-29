import Foundation

public enum MilkKind: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case devondaleFullCreamUHT
    case fullCreamFresh
    case skim
    case lactoseFree
    case oat
    case soy
    case almond

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .devondaleFullCreamUHT: return "Devondale Full Cream UHT"
        case .fullCreamFresh: return "Full Cream (Fresh)"
        case .skim: return "Skim"
        case .lactoseFree: return "Lactose-Free"
        case .oat: return "Oat"
        case .soy: return "Soy"
        case .almond: return "Almond"
        }
    }
}

public struct Milk: Codable, Hashable, Sendable {
    public var kind: MilkKind
    public var sweetness: Double       // 0...1
    public var bodyWeight: Double      // 0...1 (perceived body / fat)
    public var foamability: Double     // 0...1
    public var perceivedBitterness: Double // 0...1, how much it amplifies bitterness

    public init(
        kind: MilkKind,
        sweetness: Double,
        bodyWeight: Double,
        foamability: Double,
        perceivedBitterness: Double
    ) {
        self.kind = kind
        self.sweetness = sweetness
        self.bodyWeight = bodyWeight
        self.foamability = foamability
        self.perceivedBitterness = perceivedBitterness
    }

    public static let devondaleFullCreamUHT = Milk(
        kind: .devondaleFullCreamUHT,
        sweetness: 0.65,
        bodyWeight: 0.75,
        foamability: 0.7,
        perceivedBitterness: 0.35
    )

    public static let fullCreamFresh = Milk(
        kind: .fullCreamFresh,
        sweetness: 0.7,
        bodyWeight: 0.8,
        foamability: 0.85,
        perceivedBitterness: 0.3
    )

    public static let skim = Milk(
        kind: .skim,
        sweetness: 0.55,
        bodyWeight: 0.35,
        foamability: 0.9,
        perceivedBitterness: 0.55
    )

    public static let lactoseFree = Milk(
        kind: .lactoseFree,
        sweetness: 0.8,
        bodyWeight: 0.7,
        foamability: 0.75,
        perceivedBitterness: 0.3
    )

    public static let oat = Milk(
        kind: .oat,
        sweetness: 0.6,
        bodyWeight: 0.65,
        foamability: 0.6,
        perceivedBitterness: 0.5
    )

    public static let soy = Milk(
        kind: .soy,
        sweetness: 0.5,
        bodyWeight: 0.55,
        foamability: 0.55,
        perceivedBitterness: 0.6
    )

    public static let almond = Milk(
        kind: .almond,
        sweetness: 0.4,
        bodyWeight: 0.35,
        foamability: 0.4,
        perceivedBitterness: 0.7
    )

    public static func canonical(for kind: MilkKind) -> Milk {
        switch kind {
        case .devondaleFullCreamUHT: return .devondaleFullCreamUHT
        case .fullCreamFresh: return .fullCreamFresh
        case .skim: return .skim
        case .lactoseFree: return .lactoseFree
        case .oat: return .oat
        case .soy: return .soy
        case .almond: return .almond
        }
    }

    public static let allCanonical: [Milk] = MilkKind.allCases.map(Milk.canonical(for:))
}
