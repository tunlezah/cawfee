import SwiftUI

/// A capsule badge showing a bean's freshness stage. Mirrors `ConfidenceBadge`.
public struct FreshnessBadge: View {
    public let freshness: Freshness
    public var compact: Bool

    public init(freshness: Freshness, compact: Bool = false) {
        self.freshness = freshness
        self.compact = compact
    }

    private var tint: Color {
        switch freshness.stage {
        case .unknown: return .secondary
        case .resting: return .blue
        case .peak: return .green
        case .good: return .mint
        case .fading: return .orange
        case .stale: return .red
        }
    }

    private var text: String {
        if compact {
            if let days = freshness.daysSinceRoast {
                return "\(freshness.stage.label) · \(days)d"
            }
            return freshness.stage.label
        }
        return freshness.summary
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: freshness.stage.symbolName)
                .imageScale(.small)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(tint.opacity(0.18), in: Capsule())
        .foregroundStyle(tint)
        .overlay(Capsule().strokeBorder(tint.opacity(0.35)))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        FreshnessBadge(freshness: Freshness(stage: .unknown, daysSinceRoast: nil))
        FreshnessBadge(freshness: Freshness(stage: .resting, daysSinceRoast: 3))
        FreshnessBadge(freshness: Freshness(stage: .peak, daysSinceRoast: 12))
        FreshnessBadge(freshness: Freshness(stage: .good, daysSinceRoast: 28))
        FreshnessBadge(freshness: Freshness(stage: .fading, daysSinceRoast: 45))
        FreshnessBadge(freshness: Freshness(stage: .stale, daysSinceRoast: 90))
        FreshnessBadge(freshness: Freshness(stage: .peak, daysSinceRoast: 12), compact: true)
    }
    .padding()
}
