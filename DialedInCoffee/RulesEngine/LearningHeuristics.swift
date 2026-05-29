import Foundation

public enum LearningHeuristics {
    /// True when there are 3+ recent adjustments to the same parameter in the same direction
    /// with no "good" outcome between them — the user is chasing their tail.
    public static func detectRepeatedFailure(history: [HistorySnapshot]) -> Bool {
        guard history.count >= 3 else { return false }
        let recent = Array(history.suffix(5))

        // Group by parameter; bail if any "good" outcome appears recently.
        if recent.contains(where: { $0.outcome == .good }) { return false }

        // Find the most-touched parameter in recent history.
        let counts = Dictionary(grouping: recent, by: { $0.primaryAdjustmentParameter })
            .mapValues { $0.count }
        guard let (param, count) = counts.max(by: { $0.value < $1.value }), count >= 3 else { return false }

        // Check those touches all move in the same direction.
        let touches = recent.filter { $0.primaryAdjustmentParameter == param }
        return monotonicallySameDirection(touches, parameter: param)
    }

    /// Most recent "good"-marked snapshot, if any.
    public static func lastGood(history: [HistorySnapshot]) -> HistorySnapshot? {
        history.reversed().first { $0.outcome == .good }
    }

    private static func monotonicallySameDirection(
        _ snapshots: [HistorySnapshot],
        parameter: AdjustmentParameter
    ) -> Bool {
        var lastDelta: Int? = nil
        for snap in snapshots {
            let delta: Int
            switch parameter {
            case .grinder: delta = snap.afterSettings.grinder - snap.beforeSettings.grinder
            case .strength: delta = snap.afterSettings.strength - snap.beforeSettings.strength
            case .volume: delta = snap.afterSettings.volumeML - snap.beforeSettings.volumeML
            case .milkDuration: delta = snap.afterSettings.milkSeconds - snap.beforeSettings.milkSeconds
            case .temperature:
                let order: [TemperatureLevel] = [.low, .normal, .high]
                let bi = order.firstIndex(of: snap.beforeSettings.temperature) ?? 1
                let ai = order.firstIndex(of: snap.afterSettings.temperature) ?? 1
                delta = ai - bi
            case .beans:
                return false
            }
            if delta == 0 { return false }
            if let last = lastDelta {
                if (last > 0) != (delta > 0) { return false }
            }
            lastDelta = delta
        }
        return lastDelta != nil
    }
}
