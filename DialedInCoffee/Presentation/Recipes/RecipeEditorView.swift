import SwiftUI

struct RecipeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let existing: Recipe?
    let beans: [BeanProfile]
    let onSave: (Recipe) -> Void

    @State private var name: String
    @State private var drink: DrinkType
    @State private var milkKind: MilkKind
    @State private var settings: MachineSettings
    @State private var beanSlug: String
    @State private var notes: String
    @State private var isFavourite: Bool
    @State private var isLastGood: Bool

    init(recipe: Recipe?, beans: [BeanProfile], onSave: @escaping (Recipe) -> Void) {
        self.existing = recipe
        self.beans = beans
        self.onSave = onSave
        _name = State(initialValue: recipe?.name ?? "Untitled Recipe")
        _drink = State(initialValue: recipe?.drink ?? .cappuccino)
        _milkKind = State(initialValue: recipe?.milkKind ?? .devondaleFullCreamUHT)
        _settings = State(initialValue: recipe?.settings ?? .defaultCappuccino)
        _beanSlug = State(initialValue: recipe?.bean?.slug ?? "")
        _notes = State(initialValue: recipe?.notes ?? "")
        _isFavourite = State(initialValue: recipe?.isFavourite ?? false)
        _isLastGood = State(initialValue: recipe?.isLastGood ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(existing == nil ? "New Recipe" : "Edit Recipe")
                .font(.title2.weight(.semibold))

            Form {
                TextField("Name", text: $name)
                Picker("Drink", selection: $drink) {
                    ForEach(DrinkType.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("Milk", selection: $milkKind) {
                    ForEach(MilkKind.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("Bean", selection: $beanSlug) {
                    Text("None").tag("")
                    ForEach(beans, id: \.slug) { Text("\($0.roaster) — \($0.name)").tag($0.slug) }
                }
                Section("Settings") {
                    MachineSettingsEditor(settings: $settings, showsMilk: drink.isMilkBased)
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                Toggle("Favourite", isOn: $isFavourite)
                Toggle("Last good", isOn: $isLastGood)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button(existing == nil ? "Create" : "Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(minWidth: 460, minHeight: 600)
    }

    private func save() {
        let bean = beans.first(where: { $0.slug == beanSlug })
        if let existing {
            existing.name = name
            existing.drink = drink
            existing.milkKind = milkKind
            existing.settings = settings
            existing.bean = bean
            existing.notes = notes
            existing.isFavourite = isFavourite
            existing.isLastGood = isLastGood
            onSave(existing)
        } else {
            let recipe = Recipe(
                name: name,
                drink: drink,
                milkKind: milkKind,
                settings: settings,
                bean: bean,
                isFavourite: isFavourite,
                isLastGood: isLastGood,
                notes: notes
            )
            onSave(recipe)
        }
        dismiss()
    }
}
