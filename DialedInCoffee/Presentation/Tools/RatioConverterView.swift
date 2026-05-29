import SwiftUI

/// A brew-ratio calculator. Set any two of dose / yield / ratio and the third
/// follows. Tappable Aussie-style ratio presets. No persistence — pure tool.
struct RatioConverterView: View {
    private enum Locked: String, CaseIterable, Identifiable {
        case yield, dose
        var id: String { rawValue }
        var label: String { self == .yield ? "Solve yield" : "Solve dose" }
    }

    @State private var dose: Double = 18
    @State private var yield: Double = 36
    @State private var ratio: Double = 2.0
    @State private var solveFor: Locked = .yield

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    SectionPanel("Brew ratio", systemImage: "divide") {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            Picker("Solve for", selection: $solveFor) {
                                ForEach(Locked.allCases) { Text($0.label).tag($0) }
                            }
                            .pickerStyle(.segmented)

                            ratioReadout

                            Stepper(value: $dose, in: 5...30, step: 0.5) {
                                LabeledContent("Dose", value: String(format: "%.1f g", dose))
                            }
                            .disabled(solveFor == .dose)

                            Stepper(value: $yield, in: 10...140, step: 1) {
                                LabeledContent("Yield", value: String(format: "%.0f g", yield))
                            }
                            .disabled(solveFor == .yield)

                            VStack(alignment: .leading) {
                                LabeledContent("Ratio", value: String(format: "1 : %.2f", ratio))
                                Slider(value: $ratio, in: 1.0...4.0, step: 0.1)
                            }
                        }
                        .onChange(of: dose) { recompute() }
                        .onChange(of: yield) { recompute() }
                        .onChange(of: ratio) { recompute() }
                        .onChange(of: solveFor) { recompute() }
                    }

                    SectionPanel("Aussie style presets", systemImage: "cup.and.saucer") {
                        FlowLayout(spacing: 8) {
                            ForEach(AustralianStylePreset.all) { preset in
                                Button {
                                    ratio = preset.ratio
                                    solveFor = .yield
                                    recompute()
                                } label: {
                                    Text("\(preset.name) · \(preset.ratioText)")
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(.background.tertiary, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Ratio Converter")
        }
    }

    private var ratioReadout: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.md) {
            bigNumber(String(format: "%.1f", dose), "g in")
            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
            bigNumber(String(format: "%.0f", yield), "g out")
            Spacer()
            bigNumber(String(format: "1:%.1f", ratio), "ratio")
        }
    }

    private func bigNumber(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func recompute() {
        switch solveFor {
        case .yield:
            guard dose > 0 else { return }
            yield = (dose * ratio).rounded()
        case .dose:
            guard ratio > 0 else { return }
            dose = (yield / ratio * 10).rounded() / 10
        }
    }
}

#Preview {
    RatioConverterView()
        .frame(width: 600, height: 600)
}
