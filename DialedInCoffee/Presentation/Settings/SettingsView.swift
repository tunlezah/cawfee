import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var prefsList: [UserPreferences]

    private var prefs: UserPreferences {
        if let p = prefsList.first { return p }
        let p = UserPreferences()
        modelContext.insert(p)
        try? modelContext.save()
        return p
    }

    var body: some View {
        Form {
            Section("Mode") {
                Picker("User mode", selection: bindingMode) {
                    ForEach(UserMode.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                Text(prefs.userMode == .novice
                     ? "Single recommended change, simplified language."
                     : "Full reasoning, rule contributions, alternatives.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Defaults") {
                Picker("Default drink", selection: bindingDrink) {
                    ForEach(DrinkType.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("Default milk", selection: bindingMilk) {
                    ForEach(MilkKind.allCases) { Text($0.displayName).tag($0) }
                }
            }

            Section("Appearance") {
                Picker("Appearance", selection: bindingAppearance) {
                    ForEach(AppearancePreference.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Machine") {
                LabeledContent("Machine", value: "Jura E8 (2023+, P.A.G.2 grinder)")
                LabeledContent("Grinder range", value: "1–7")
                LabeledContent("Strength range", value: "1–10")
                LabeledContent("Volume range", value: "25–240 ml")
                LabeledContent("Milk duration", value: "3–120 s")
            }

            Section("About") {
                LabeledContent("Connection", value: "Fully offline · no network calls")
                LabeledContent("Storage", value: "Local SwiftData")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(maxWidth: 720)
    }

    private var bindingMode: Binding<UserMode> {
        Binding(get: { prefs.userMode }, set: { prefs.userMode = $0; try? modelContext.save() })
    }
    private var bindingDrink: Binding<DrinkType> {
        Binding(get: { prefs.defaultDrink }, set: { prefs.defaultDrink = $0; try? modelContext.save() })
    }
    private var bindingMilk: Binding<MilkKind> {
        Binding(get: { prefs.defaultMilkKind }, set: { prefs.defaultMilkKind = $0; try? modelContext.save() })
    }
    private var bindingAppearance: Binding<AppearancePreference> {
        Binding(get: { prefs.appearance }, set: { prefs.appearance = $0; try? modelContext.save() })
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 700, height: 600)
}
