import Foundation

public enum Symptom: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case tooBitter
    case tooSour
    case tooWatery
    case tooBurnt
    case tooDry
    case tooWeak
    case tooStrong
    case tooFoamy
    case tooHot
    case tastesEmpty
    case notCafeLike
    case sharpAftertaste
    case muddyDull

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .tooBitter: return "Too bitter"
        case .tooSour: return "Too sour"
        case .tooWatery: return "Too watery"
        case .tooBurnt: return "Too burnt"
        case .tooDry: return "Too dry / harsh"
        case .tooWeak: return "Too weak"
        case .tooStrong: return "Too strong"
        case .tooFoamy: return "Too foamy"
        case .tooHot: return "Too hot"
        case .tastesEmpty: return "Tastes empty"
        case .notCafeLike: return "Not cafe-like"
        case .sharpAftertaste: return "Sharp aftertaste"
        case .muddyDull: return "Muddy / dull"
        }
    }

    public var plainExplanation: String {
        switch self {
        case .tooBitter: return "Harsh, dry, dark-chocolate or burnt-toast feel."
        case .tooSour: return "Sharp, lemony, vinegary — drink feels green."
        case .tooWatery: return "Thin, dilute, lacks body."
        case .tooBurnt: return "Ashy or scorched, like over-roasted coffee."
        case .tooDry: return "Astringent, drying on the tongue."
        case .tooWeak: return "Not much coffee flavour — closer to hot milk."
        case .tooStrong: return "Overpowering, intense, hard to drink."
        case .tooFoamy: return "Too much foam on top, drink feels airy."
        case .tooHot: return "Burns the tongue, masks flavour."
        case .tastesEmpty: return "No real flavour — neither bitter nor sweet."
        case .notCafeLike: return "Just doesn't feel like a cafe coffee."
        case .sharpAftertaste: return "Lingering harsh or acidic edge."
        case .muddyDull: return "Flat, heavy, no clarity."
        }
    }

    public var symbolName: String {
        switch self {
        case .tooBitter: return "leaf"
        case .tooSour: return "drop"
        case .tooWatery: return "drop.halffull"
        case .tooBurnt: return "flame"
        case .tooDry: return "wind"
        case .tooWeak: return "tortoise"
        case .tooStrong: return "bolt"
        case .tooFoamy: return "cloud.fill"
        case .tooHot: return "thermometer.sun"
        case .tastesEmpty: return "circle.dashed"
        case .notCafeLike: return "questionmark.circle"
        case .sharpAftertaste: return "triangle"
        case .muddyDull: return "cloud.fog"
        }
    }
}
