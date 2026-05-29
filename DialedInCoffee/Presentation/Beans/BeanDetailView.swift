import SwiftUI
import SwiftData

struct BeanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var bean: BeanProfile
    @State private var isEditing: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                SectionPanel("Recommended starting settings", systemImage: "slider.horizontal.3") {
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 6) {
                        gridRow("Grinder", "\(bean.recGrinder) / 7")
                        gridRow("Strength", "\(bean.recStrength) / 10")
                        gridRow("Volume", "\(bean.recVolumeML) ml")
                        gridRow("Milk", "\(bean.recMilkSeconds) s")
                        gridRow("Temperature", TemperatureLevel(rawValue: bean.recTemperatureRaw)?.displayName ?? "Normal")
                    }
                }

                SectionPanel("Freshness & bag", systemImage: "calendar") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        if let roastDate = bean.roastDate {
                            LabeledContent("Roasted", value: roastDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        if let openedDate = bean.openedDate {
                            LabeledContent("Opened", value: openedDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        if let grind = bean.currentGrindSetting {
                            LabeledContent("Dialled grind", value: "\(grind) / 7")
                        }
                        FreshnessBadge(freshness: bean.freshness())
                        if bean.roastDate == nil {
                            Text("Set a roast date in Edit to track the de-gas, peak and stale windows.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                SectionPanel("Flavour notes", systemImage: "sparkles") {
                    if bean.flavourNotes.isEmpty {
                        Text("No tasting notes recorded.")
                            .foregroundStyle(.secondary)
                    } else {
                        FlowLayout(spacing: 6) {
                            ForEach(bean.flavourNotes, id: \.self) { note in
                                Text(note)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.background.tertiary, in: Capsule())
                            }
                        }
                    }
                }

                SectionPanel("Notes", systemImage: "note.text") {
                    TextEditor(text: $bean.notes)
                        .frame(minHeight: 100)
                        .font(.body)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle(bean.name)
        .toolbar {
            ToolbarItem {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            BeanEditorView(bean: bean) { _ in
                try? modelContext.save()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(bean.roaster)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(bean.name)
                .font(.largeTitle.weight(.semibold))
            HStack(spacing: 12) {
                Label(bean.roastLevel.displayName, systemImage: "flame")
                if bean.milkFriendly {
                    Label("Milk-friendly", systemImage: "drop")
                }
                if bean.isSeeded {
                    Label("Seed catalog", systemImage: "checkmark.seal")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            FreshnessBadge(freshness: bean.freshness())
        }
    }

    @ViewBuilder
    private func gridRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary)
            Text(value).monospacedDigit()
        }
    }
}

#Preview {
    let container = PreviewData.previewContainer()
    let bean = try! container.mainContext.fetch(FetchDescriptor<BeanProfile>()).first!
    return BeanDetailView(bean: bean)
        .modelContainer(container)
        .frame(width: 600, height: 600)
}
