import SwiftUI
import SwiftData

struct ExpertModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BeanProfile.name) private var beans: [BeanProfile]
    @Query(sort: \AdjustmentHistoryEntry.date, order: .reverse) private var history: [AdjustmentHistoryEntry]

    @State private var vm = FixMyCoffeeViewModel()
    @State private var didInit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expert Mode")
                        .font(.title2.weight(.semibold))
                    Text("See the full extraction reasoning. Adjust freely; nothing is hidden.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                CurrentSettingsPanel(
                    drink: $vm.drink,
                    milkKind: $vm.milkKind,
                    settings: $vm.settings,
                    beanSlug: $vm.selectedBeanSlug,
                    beans: beans,
                    onResetForDrink: { vm.resetSettingsForDrink() }
                )

                SectionPanel("Symptoms", systemImage: "questionmark.bubble") {
                    SymptomPickerView(selection: $vm.selectedSymptoms)
                    HStack {
                        Spacer()
                        Button("Evaluate") {
                            vm.evaluate(beans: beans, history: history, novice: false)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.selectedSymptoms.isEmpty)
                    }
                }

                if let rec = vm.recommendation {
                    RecommendationCardView(recommendation: rec, novice: false) {
                        guard let primary = rec.primary else { return }
                        vm.applyAndLog(
                            primary: primary,
                            secondary: rec.secondary,
                            context: modelContext,
                            beans: beans
                        )
                    }

                    SectionPanel("Rule contributions", systemImage: "chart.bar.doc.horizontal") {
                        RuleContributionsView(recommendation: rec)
                    }

                    if !rec.alternativeCauses.isEmpty {
                        SectionPanel("Alternative causes", systemImage: "questionmark.circle") {
                            ForEach(rec.alternativeCauses, id: \.cause) { alt in
                                HStack {
                                    Text(alt.cause.displayName)
                                    Spacer()
                                    Text(String(format: "%.0f%%", alt.confidence * 100))
                                        .font(.callout.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Expert Mode")
        .onAppear {
            if !didInit {
                vm.settings = MachineSettings.defaults(for: vm.drink)
                didInit = true
            }
        }
    }
}

#Preview {
    ExpertModeView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 900, height: 700)
}
