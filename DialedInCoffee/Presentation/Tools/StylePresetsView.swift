import SwiftUI

/// Read-only reference of Canberra/Australian café drink styles with typical
/// ratios and milk volumes. Pure reference data, fully offline.
struct StylePresetsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Typical Canberra café styles. Ratios are tighter than the international norm — the local flat-white tradition favours a 1:2 double ristretto/espresso.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(AustralianStylePreset.all) { preset in
                        SectionPanel(preset.name, systemImage: preset.symbolName) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                HStack(spacing: Theme.Spacing.lg) {
                                    stat("Ratio", preset.ratioText)
                                    stat("Drink", "\(preset.beverageML) ml")
                                    if preset.milkML > 0 {
                                        stat("Milk", "\(preset.milkML) ml")
                                    } else {
                                        stat("Milk", "—")
                                    }
                                }
                                Text(preset.blurb)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Style Presets")
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    StylePresetsView()
        .frame(width: 600, height: 700)
}
