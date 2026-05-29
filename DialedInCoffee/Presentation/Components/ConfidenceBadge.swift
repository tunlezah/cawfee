import SwiftUI

public struct ConfidenceBadge: View {
    public let confidence: Double

    public init(confidence: Double) {
        self.confidence = confidence
    }

    public var body: some View {
        let pct = Int((confidence * 100).rounded())
        let tint: Color = {
            switch confidence {
            case ..<0.4: return .orange
            case ..<0.7: return .yellow
            default: return .green
            }
        }()

        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .imageScale(.small)
            Text("\(pct)% confident")
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
    VStack {
        ConfidenceBadge(confidence: 0.3)
        ConfidenceBadge(confidence: 0.55)
        ConfidenceBadge(confidence: 0.85)
    }
    .padding()
}
