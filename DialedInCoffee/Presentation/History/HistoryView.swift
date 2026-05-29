import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AdjustmentHistoryEntry.date, order: .reverse) private var entries: [AdjustmentHistoryEntry]
    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var recipes: [Recipe]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(Theme.Spacing.lg)
            if entries.isEmpty {
                ContentUnavailableView(
                    "No history yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Adjustments you apply from Fix My Coffee will appear here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if let lastGood = recipes.first(where: { $0.isLastGood }) {
                        Section("Last good recipe") {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lastGood.name).font(.body.weight(.semibold))
                                Text("Grinder \(lastGood.grinder) · Strength \(lastGood.strength) · \(lastGood.volumeML)ml · \(lastGood.temperature.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section("Recent adjustments") {
                        ForEach(entries) { entry in
                            HistoryRowView(entry: entry)
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(entries[i]) }
                            try? modelContext.save()
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("History")
                .font(.title2.weight(.semibold))
            Text("Track what you've changed and how it tasted. Mark a row as 'Good' to set the last-good baseline.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 900, height: 700)
}
