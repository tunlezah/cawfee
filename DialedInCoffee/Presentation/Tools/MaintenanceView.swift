import SwiftUI
import SwiftData

/// Espresso-machine maintenance tracker. Tasks become "due" by calendar
/// interval or by shot count (whichever comes first). The shot count is the
/// total number of saved shots. Fully local — no notifications required.
struct MaintenanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\MaintenanceTask.sortOrder), SortDescriptor(\MaintenanceTask.name)])
    private var tasks: [MaintenanceTask]
    @Query private var shots: [Shot]

    @State private var showingEditor = false

    private var shotCount: Int { shots.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    summary
                    ForEach(tasks) { task in
                        taskCard(task)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Maintenance")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("New Task", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                MaintenanceEditor { newTask in
                    modelContext.insert(newTask)
                    try? modelContext.save()
                }
            }
        }
    }

    private var summary: some View {
        let due = tasks.filter { $0.isDue(currentShotCount: shotCount) }.count
        return HStack {
            Label("\(shotCount) shots logged", systemImage: "cup.and.saucer")
            Spacer()
            if due == 0 {
                Label("All up to date", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("\(due) due", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .font(.subheadline)
    }

    private func taskCard(_ task: MaintenanceTask) -> some View {
        let due = task.isDue(currentShotCount: shotCount)
        return SectionPanel(task.name, systemImage: task.symbolName) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if !task.detail.isEmpty {
                    Text(task.detail).font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: Theme.Spacing.lg) {
                    if let days = task.daysUntilDue() {
                        statusChip(
                            days <= 0 ? "Overdue" : "in \(days)d",
                            systemImage: "calendar",
                            overdue: days <= 0
                        )
                    }
                    if let s = task.shotsUntilDue(currentShotCount: shotCount) {
                        statusChip(
                            s <= 0 ? "Overdue" : "in \(s) shots",
                            systemImage: "cup.and.saucer",
                            overdue: s <= 0
                        )
                    }
                    Spacer()
                }
                HStack {
                    if let last = task.lastCompletedDate {
                        Text("Last done \(last.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2).foregroundStyle(.secondary)
                    } else {
                        Text("Never done").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        task.markDone(currentShotCount: shotCount)
                        try? modelContext.save()
                    } label: {
                        Label("Mark done", systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    if !task.isSeeded {
                        Button(role: .destructive) {
                            modelContext.delete(task)
                            try? modelContext.save()
                        } label: { Image(systemName: "trash") }
                            .controlSize(.small)
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if due {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func statusChip(_ text: String, systemImage: String, overdue: Bool) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background((overdue ? Color.orange : Color.secondary).opacity(0.18), in: Capsule())
            .foregroundStyle(overdue ? .orange : .secondary)
    }
}

private struct MaintenanceEditor: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (MaintenanceTask) -> Void

    @State private var name = ""
    @State private var detail = ""
    @State private var useDays = true
    @State private var days = 14
    @State private var useShots = false
    @State private var shots = 100

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("New Maintenance Task").font(.title2.weight(.semibold))
            Form {
                TextField("Name", text: $name)
                TextField("Notes", text: $detail)
                Section("Recurs by") {
                    Toggle("Every N days", isOn: $useDays)
                    if useDays {
                        Stepper(value: $days, in: 1...730) {
                            LabeledContent("Days", value: "\(days)")
                        }
                    }
                    Toggle("Every N shots", isOn: $useShots)
                    if useShots {
                        Stepper(value: $shots, in: 1...2000, step: 10) {
                            LabeledContent("Shots", value: "\(shots)")
                        }
                    }
                }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Create") {
                    onSave(MaintenanceTask(
                        name: name,
                        detail: detail,
                        intervalDays: useDays ? days : nil,
                        intervalShots: useShots ? shots : nil,
                        sortOrder: 100
                    ))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || (!useDays && !useShots))
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(minWidth: 460, minHeight: 420)
    }
}

#Preview {
    MaintenanceView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 700, height: 700)
}
