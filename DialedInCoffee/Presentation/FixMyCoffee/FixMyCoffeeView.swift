import SwiftUI
import SwiftData

struct FixMyCoffeeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BeanProfile.name) private var beans: [BeanProfile]
    @Query(sort: \AdjustmentHistoryEntry.date, order: .reverse) private var history: [AdjustmentHistoryEntry]
    @Query private var prefsList: [UserPreferences]

    @State private var vm = FixMyCoffeeViewModel()
    @State private var didLoadDefaults = false

    private var prefs: UserPreferences? { prefsList.first }
    private var novice: Bool { (prefs?.userMode ?? .novice) == .novice }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header

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
                        Button("Clear", role: .destructive) { vm.clearSymptoms() }
                            .buttonStyle(.borderless)
                            .disabled(vm.selectedSymptoms.isEmpty)
                        Button("Get recommendation") {
                            vm.evaluate(beans: beans, history: history, novice: novice)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: [.command])
                        .disabled(vm.selectedSymptoms.isEmpty)
                    }
                }

                if let rec = vm.recommendation {
                    RecommendationCardView(recommendation: rec, novice: novice) {
                        guard let primary = rec.primary else { return }
                        vm.applyAndLog(
                            primary: primary,
                            secondary: rec.secondary,
                            context: modelContext,
                            beans: beans
                        )
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Fix My Coffee")
        .onAppear {
            if !didLoadDefaults {
                vm.loadDefaults(from: prefs)
                didLoadDefaults = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tell me what's wrong with your cup.")
                .font(.title2.weight(.semibold))
            Text("Pick what tastes off, then we'll suggest one or two changes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Fix My Coffee — Light") {
    FixMyCoffeeView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 900, height: 700)
        .preferredColorScheme(.light)
}

#Preview("Fix My Coffee — Dark") {
    FixMyCoffeeView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 900, height: 700)
        .preferredColorScheme(.dark)
}
