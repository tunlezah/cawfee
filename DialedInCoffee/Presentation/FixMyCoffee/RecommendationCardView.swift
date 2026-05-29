import SwiftUI

struct RecommendationCardView: View {
    let recommendation: Recommendation
    let novice: Bool
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Label("Recommendation", systemImage: "wand.and.stars")
                    .font(.title3.weight(.semibold))
                Spacer()
                if recommendation.confidence > 0 {
                    ConfidenceBadge(confidence: recommendation.confidence)
                }
            }

            if recommendation.suggestRevertToLastGood {
                Text(recommendation.rationale)
                    .font(.body)
                    .foregroundStyle(.primary)
                Label("Consider rolling back to your last good recipe.", systemImage: "arrow.uturn.backward.circle")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                Text(recommendation.rationale)
                    .font(.body)
                if let primary = recommendation.primary {
                    adjustmentRow(primary, badge: "Primary")
                    if !novice, let secondary = recommendation.secondary {
                        adjustmentRow(secondary, badge: "Also try")
                    }
                } else {
                    Text("No actionable change identified.")
                        .foregroundStyle(.secondary)
                }
            }

            if recommendation.hasAnyAdjustment && !recommendation.suggestRevertToLastGood {
                HStack {
                    Spacer()
                    Button("Apply & Log", action: onApply)
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .panelStyle()
    }

    private func adjustmentRow(_ adj: Adjustment, badge: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: adj.directionSymbol)
                .imageScale(.large)
                .foregroundStyle(.tint)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(badge.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(adj.summary)
                        .font(.body.weight(.semibold))
                }
                Text(adj.reason)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("Expected: \(adj.expectedOutcome)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview("Recommendation") {
    let rec = Recommendation(
        primary: Adjustment(
            parameter: .grinder, fromInt: 5, toInt: 4,
            reason: "Coarser grind reduces over-extraction.",
            expectedOutcome: "Less bitterness, smoother body."
        ),
        secondary: Adjustment(
            parameter: .temperature, fromTemp: .high, toTemp: .normal,
            reason: "Lower temperature reveals sweetness.",
            expectedOutcome: "Smoother, less burnt."
        ),
        topCause: .overExtraction,
        confidence: 0.78,
        rationale: "Symptoms point to over-extraction.",
        contributions: [],
        alternativeCauses: []
    )
    return RecommendationCardView(recommendation: rec, novice: false) {}
        .padding()
        .frame(width: 640)
}
