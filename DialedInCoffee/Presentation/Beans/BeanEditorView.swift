import SwiftUI

struct BeanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let existing: BeanProfile?
    let onSave: (BeanProfile) -> Void

    @State private var name: String
    @State private var roaster: String
    @State private var roastLevel: RoastLevel
    @State private var milkFriendly: Bool
    @State private var flavourNotesText: String
    @State private var settings: MachineSettings
    @State private var notes: String
    @State private var hasRoastDate: Bool
    @State private var roastDate: Date
    @State private var hasOpenedDate: Bool
    @State private var openedDate: Date
    @State private var hasGrind: Bool
    @State private var grind: Int

    init(bean: BeanProfile?, onSave: @escaping (BeanProfile) -> Void) {
        self.existing = bean
        self.onSave = onSave
        _name = State(initialValue: bean?.name ?? "")
        _roaster = State(initialValue: bean?.roaster ?? "")
        _roastLevel = State(initialValue: bean?.roastLevel ?? .medium)
        _milkFriendly = State(initialValue: bean?.milkFriendly ?? true)
        _flavourNotesText = State(initialValue: (bean?.flavourNotes ?? []).joined(separator: ", "))
        _settings = State(initialValue: bean?.recommendedSettings ?? MachineSettings())
        _notes = State(initialValue: bean?.notes ?? "")
        _hasRoastDate = State(initialValue: bean?.roastDate != nil)
        _roastDate = State(initialValue: bean?.roastDate ?? Date())
        _hasOpenedDate = State(initialValue: bean?.openedDate != nil)
        _openedDate = State(initialValue: bean?.openedDate ?? Date())
        _hasGrind = State(initialValue: bean?.currentGrindSetting != nil)
        _grind = State(initialValue: bean?.currentGrindSetting ?? 4)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(existing == nil ? "New Bean" : "Edit Bean")
                .font(.title2.weight(.semibold))

            Form {
                TextField("Name", text: $name)
                TextField("Roaster", text: $roaster)
                Picker("Roast", selection: $roastLevel) {
                    ForEach(RoastLevel.allCases) { Text($0.displayName).tag($0) }
                }
                Toggle("Milk-friendly", isOn: $milkFriendly)
                Section("Bag tracking") {
                    Toggle("Track roast date", isOn: $hasRoastDate)
                    if hasRoastDate {
                        DatePicker("Roasted", selection: $roastDate, in: ...Date(), displayedComponents: .date)
                    }
                    Toggle("Track opened date", isOn: $hasOpenedDate)
                    if hasOpenedDate {
                        DatePicker("Opened", selection: $openedDate, in: ...Date(), displayedComponents: .date)
                    }
                    Toggle("Record dialled grind", isOn: $hasGrind)
                    if hasGrind {
                        Stepper(value: $grind, in: 1...7) {
                            LabeledContent("Grind", value: "\(grind) / 7")
                        }
                    }
                }
                TextField("Flavour notes (comma-separated)", text: $flavourNotesText)
                Section("Recommended Settings") {
                    MachineSettingsEditor(settings: $settings)
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button(existing == nil ? "Create" : "Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty || roaster.isEmpty)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(minWidth: 460, minHeight: 520)
    }

    private func save() {
        let notesArray = flavourNotesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let resolvedRoastDate = hasRoastDate ? roastDate : nil
        let resolvedOpenedDate = hasOpenedDate ? openedDate : nil
        let resolvedGrind = hasGrind ? grind : nil
        if let existing {
            existing.name = name
            existing.roaster = roaster
            existing.roastLevel = roastLevel
            existing.milkFriendly = milkFriendly
            existing.flavourNotes = notesArray
            existing.recommendedSettings = settings
            existing.notes = notes
            existing.roastDate = resolvedRoastDate
            existing.openedDate = resolvedOpenedDate
            existing.currentGrindSetting = resolvedGrind
            onSave(existing)
        } else {
            let slug = makeSlug(roaster: roaster, name: name)
            let bean = BeanProfile(
                slug: slug,
                name: name,
                roaster: roaster,
                roastLevel: roastLevel,
                milkFriendly: milkFriendly,
                flavourNotes: notesArray,
                recommendedSettings: settings,
                notes: notes,
                isSeeded: false,
                roastDate: resolvedRoastDate,
                openedDate: resolvedOpenedDate,
                currentGrindSetting: resolvedGrind
            )
            onSave(bean)
        }
        dismiss()
    }

    private func makeSlug(roaster: String, name: String) -> String {
        let base = "\(roaster)-\(name)".lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        let trimmed = base.filter { $0.isLetter || $0.isNumber || $0 == "-" }
        return "\(trimmed)-\(UUID().uuidString.prefix(6).lowercased())"
    }
}
