import Foundation

public enum AdjustmentParameter: String, Codable, Hashable, Sendable {
    case grinder
    case strength
    case volume
    case milkDuration
    case temperature
    case beans
}

public struct Adjustment: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var parameter: AdjustmentParameter
    public var fromInt: Int?
    public var toInt: Int?
    public var fromTemp: TemperatureLevel?
    public var toTemp: TemperatureLevel?
    public var reason: String
    public var expectedOutcome: String

    public init(
        id: UUID = UUID(),
        parameter: AdjustmentParameter,
        fromInt: Int? = nil,
        toInt: Int? = nil,
        fromTemp: TemperatureLevel? = nil,
        toTemp: TemperatureLevel? = nil,
        reason: String,
        expectedOutcome: String
    ) {
        self.id = id
        self.parameter = parameter
        self.fromInt = fromInt
        self.toInt = toInt
        self.fromTemp = fromTemp
        self.toTemp = toTemp
        self.reason = reason
        self.expectedOutcome = expectedOutcome
    }

    public var summary: String {
        switch parameter {
        case .grinder:
            return "Grinder: \(fromInt ?? 0) → \(toInt ?? 0)"
        case .strength:
            return "Strength: \(fromInt ?? 0) → \(toInt ?? 0)"
        case .volume:
            return "Volume: \(fromInt ?? 0)ml → \(toInt ?? 0)ml"
        case .milkDuration:
            return "Milk: \(fromInt ?? 0)s → \(toInt ?? 0)s"
        case .temperature:
            return "Temperature: \(fromTemp?.displayName ?? "?") → \(toTemp?.displayName ?? "?")"
        case .beans:
            return "Consider a fresher / different bean."
        }
    }

    public var directionSymbol: String {
        switch parameter {
        case .grinder, .strength, .volume, .milkDuration:
            guard let from = fromInt, let to = toInt else { return "arrow.right" }
            if to > from { return "arrow.up.right" }
            if to < from { return "arrow.down.right" }
            return "arrow.right"
        case .temperature:
            let order: [TemperatureLevel] = [.low, .normal, .high]
            guard let from = fromTemp, let to = toTemp,
                  let fi = order.firstIndex(of: from), let ti = order.firstIndex(of: to) else { return "arrow.right" }
            if ti > fi { return "arrow.up.right" }
            if ti < fi { return "arrow.down.right" }
            return "arrow.right"
        case .beans:
            return "leaf"
        }
    }

    public func apply(to settings: MachineSettings) -> MachineSettings {
        switch parameter {
        case .grinder: return settings.with(grinder: toInt ?? settings.grinder)
        case .strength: return settings.with(strength: toInt ?? settings.strength)
        case .volume: return settings.with(volumeML: toInt ?? settings.volumeML)
        case .milkDuration: return settings.with(milkSeconds: toInt ?? settings.milkSeconds)
        case .temperature: return settings.with(temperature: toTemp ?? settings.temperature)
        case .beans: return settings
        }
    }
}
