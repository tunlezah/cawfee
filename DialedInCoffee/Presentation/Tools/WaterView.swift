import SwiftUI
import SwiftData

/// Manage brewing-water mineral profiles. Ships with the Canberra/ACT tap
/// profile pre-loaded. Lets the user add their own and mark a default.
struct WaterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WaterProfile.sortOrder), SortDescriptor(\WaterProfile.name)])
    private var profiles: [WaterProfile]

    @State private var showingEditor = false
    @State private var editing: WaterProfile?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Water chemistry shapes extraction and scale build-up. Canberra tap is soft and low in bicarbonate — kind to the machine, but it can taste flat, so don't be afraid to grind finer.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(profiles) { profile in
                        profileCard(profile)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Water")
            .toolbar {
                ToolbarItem {
                    Button {
                        editing = nil
                        showingEditor = true
                    } label: {
                        Label("New Profile", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                WaterProfileEditor(profile: editing) { result in
                    if editing == nil { modelContext.insert(result) }
                    try? modelContext.save()
                }
            }
        }
    }

    private func profileCard(_ profile: WaterProfile) -> some View {
        SectionPanel(profile.name, systemImage: "drop.fill") {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if !profile.detail.isEmpty {
                    Text(profile.detail).font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: Theme.Spacing.lg) {
                    mineral("Ca", profile.calcium)
                    mineral("Mg", profile.magnesium)
                    mineral("HCO₃", profile.bicarbonate)
                    mineral("Hardness", profile.totalHardness)
                }
                HStack {
                    Label(profile.hardnessAssessment.label, systemImage: "gauge.with.dots.needle.50percent")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint(profile.hardnessAssessment))
                    if profile.isDefault {
                        Text("Default")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(.tint.opacity(0.18), in: Capsule())
                    }
                    Spacer()
                    if !profile.isDefault {
                        Button("Make default") { makeDefault(profile) }
                            .font(.caption)
                    }
                    Button {
                        editing = profile
                        showingEditor = true
                    } label: { Label("Edit", systemImage: "pencil") }
                        .font(.caption)
                    if !profile.isSeeded {
                        Button(role: .destructive) {
                            modelContext.delete(profile)
                            try? modelContext.save()
                        } label: { Label("Delete", systemImage: "trash") }
                            .font(.caption)
                    }
                }
                Text(profile.brewingHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
    }

    private func mineral(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value, format: .number.precision(.fractionLength(0)))")
                .font(.headline.monospacedDigit())
            Text("\(label) mg/L").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func tint(_ a: WaterProfile.Assessment) -> Color {
        switch a {
        case .soft: return .blue
        case .ideal: return .green
        case .hard: return .orange
        }
    }

    private func makeDefault(_ profile: WaterProfile) {
        for p in profiles { p.isDefault = false }
        profile.isDefault = true
        try? modelContext.save()
    }
}

private struct WaterProfileEditor: View {
    @Environment(\.dismiss) private var dismiss
    let existing: WaterProfile?
    let onSave: (WaterProfile) -> Void

    @State private var name: String
    @State private var detail: String
    @State private var calcium: Double
    @State private var magnesium: Double
    @State private var bicarbonate: Double
    @State private var totalHardness: Double

    init(profile: WaterProfile?, onSave: @escaping (WaterProfile) -> Void) {
        self.existing = profile
        self.onSave = onSave
        _name = State(initialValue: profile?.name ?? "")
        _detail = State(initialValue: profile?.detail ?? "")
        _calcium = State(initialValue: profile?.calcium ?? 0)
        _magnesium = State(initialValue: profile?.magnesium ?? 0)
        _bicarbonate = State(initialValue: profile?.bicarbonate ?? 0)
        _totalHardness = State(initialValue: profile?.totalHardness ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(existing == nil ? "New Water Profile" : "Edit Water Profile")
                .font(.title2.weight(.semibold))
            Form {
                TextField("Name", text: $name)
                TextField("Notes", text: $detail)
                Section("Minerals (mg/L)") {
                    stepperRow("Calcium", $calcium)
                    stepperRow("Magnesium", $magnesium)
                    stepperRow("Bicarbonate", $bicarbonate)
                    stepperRow("Total hardness", $totalHardness)
                }
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
        .frame(minWidth: 460, minHeight: 480)
    }

    private func stepperRow(_ label: String, _ value: Binding<Double>) -> some View {
        Stepper(value: value, in: 0...500, step: 1) {
            LabeledContent(label, value: String(format: "%.0f mg/L", value.wrappedValue))
        }
    }

    private func save() {
        if let existing {
            existing.name = name
            existing.detail = detail
            existing.calcium = calcium
            existing.magnesium = magnesium
            existing.bicarbonate = bicarbonate
            existing.totalHardness = totalHardness
            onSave(existing)
        } else {
            let p = WaterProfile(
                name: name, detail: detail,
                calcium: calcium, magnesium: magnesium,
                bicarbonate: bicarbonate, totalHardness: totalHardness,
                sortOrder: 100
            )
            onSave(p)
        }
        dismiss()
    }
}

#Preview {
    WaterView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 700, height: 700)
}
