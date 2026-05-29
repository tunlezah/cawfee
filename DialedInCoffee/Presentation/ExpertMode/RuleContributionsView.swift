import SwiftUI

struct RuleContributionsView: View {
    let recommendation: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if recommendation.contributions.isEmpty {
                Text("No rules triggered yet — run an evaluation in Fix My Coffee.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recommendation.contributions, id: \.cause) { contribution in
                    row(contribution)
                }
            }
        }
    }

    private func row(_ contribution: CauseContribution) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(contribution.cause.displayName)
                    .font(.body.weight(.semibold))
                Spacer()
                Text(String(format: "%.0f%%", contribution.confidence * 100))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: contribution.confidence)
                .progressViewStyle(.linear)
            if !contribution.ruleIDs.isEmpty {
                Text(contribution.ruleIDs.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
