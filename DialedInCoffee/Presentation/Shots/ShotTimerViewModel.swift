import Foundation

/// Drives the shot timer. Wall-clock based (computes elapsed from a start
/// timestamp) so it stays accurate even if the tick fires irregularly.
/// Fully local, no dependencies.
@MainActor
@Observable
public final class ShotTimerViewModel {
    public private(set) var elapsed: TimeInterval = 0
    public private(set) var isRunning: Bool = false
    /// Elapsed time at the moment pre-infusion was marked, if any.
    public private(set) var preInfusionSeconds: TimeInterval?

    private var startDate: Date?
    private var accumulated: TimeInterval = 0
    private var ticker: Timer?

    public init() {}

    public var canSave: Bool { elapsed > 0 && !isRunning }

    public func startOrStop() {
        isRunning ? stop() : start()
    }

    public func start() {
        guard !isRunning else { return }
        startDate = Date()
        isRunning = true
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    public func stop() {
        guard isRunning, let startDate else { return }
        accumulated += Date().timeIntervalSince(startDate)
        elapsed = accumulated
        isRunning = false
        self.startDate = nil
        ticker?.invalidate()
        ticker = nil
    }

    /// Records the current elapsed time as the end of pre-infusion.
    public func markPreInfusion() {
        guard isRunning else { return }
        preInfusionSeconds = elapsed
    }

    public func reset() {
        ticker?.invalidate()
        ticker = nil
        startDate = nil
        accumulated = 0
        elapsed = 0
        isRunning = false
        preInfusionSeconds = nil
    }

    private func tick() {
        guard isRunning, let startDate else { return }
        elapsed = accumulated + Date().timeIntervalSince(startDate)
    }

    /// "27.4" style seconds string.
    public static func format(_ t: TimeInterval) -> String {
        String(format: "%.1f", t)
    }
}
