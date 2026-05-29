import SwiftUI
import SwiftData

struct ShotTimerView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\BeanProfile.roaster), SortDescriptor(\BeanProfile.name)])
    private var beans: [BeanProfile]

    @Query(sort: \Shot.date, order: .reverse)
    private var shots: [Shot]

    @State private var vm = ShotTimerViewModel()

    @State private var selectedBeanSlug: String?
    @State private var drink: DrinkType = .flatWhite
    @State private var dose: Double = 18
    @State private var yield: Double = 36
    @State private var rating: Int = 0
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    timerPanel
                    detailsPanel
                    saveButton
                    recentPanel
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Shot Timer")
        }
    }

    // MARK: - Timer

    private var timerPanel: some View {
        SectionPanel("Timer", systemImage: "timer") {
            VStack(spacing: Theme.Spacing.md) {
                Text("\(ShotTimerViewModel.format(vm.elapsed))s")
                    .font(.system(size: 72, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity)

                if let pi = vm.preInfusionSeconds {
                    Label("Pre-infusion at \(ShotTimerViewModel.format(pi))s", systemImage: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        vm.startOrStop()
                    } label: {
                        Label(vm.isRunning ? "Stop" : "Start",
                              systemImage: vm.isRunning ? "stop.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .tint(vm.isRunning ? .red : .green)

                    Button {
                        vm.markPreInfusion()
                    } label: {
                        Label("Pre-infusion", systemImage: "drop")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!vm.isRunning)

                    Button(role: .destructive) {
                        vm.reset()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(vm.elapsed == 0 && vm.preInfusionSeconds == nil)
                }
            }
        }
    }

    // MARK: - Details

    private var detailsPanel: some View {
        SectionPanel("This shot", systemImage: "slider.horizontal.3") {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Picker("Bean", selection: $selectedBeanSlug) {
                    Text("None").tag(String?.none)
                    ForEach(beans) { bean in
                        Text("\(bean.name) · \(bean.roaster)").tag(Optional(bean.slug))
                    }
                }

                Picker("Drink", selection: $drink) {
                    ForEach(DrinkType.allCases) { Text($0.displayName).tag($0) }
                }

                Stepper(value: $dose, in: 5...30, step: 0.5) {
                    LabeledContent("Dose", value: String(format: "%.1f g", dose))
                }
                Stepper(value: $yield, in: 10...120, step: 1) {
                    LabeledContent("Yield", value: String(format: "%.0f g", yield))
                }

                LabeledContent("Ratio", value: ratioText)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text("Rating")
                    Spacer()
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundStyle(star <= rating ? .yellow : .secondary)
                            .onTapGesture { rating = (rating == star) ? 0 : star }
                    }
                }

                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var ratioText: String {
        guard dose > 0 else { return "—" }
        return String(format: "1:%.1f", yield / dose)
    }

    private var saveButton: some View {
        Button {
            saveShot()
        } label: {
            Label("Save shot", systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!vm.canSave)
    }

    // MARK: - Recent

    @ViewBuilder
    private var recentPanel: some View {
        if !shots.isEmpty {
            SectionPanel("Recent shots", systemImage: "clock.arrow.circlepath") {
                VStack(spacing: 0) {
                    ForEach(shots.prefix(15)) { shot in
                        recentRow(shot)
                        if shot.id != shots.prefix(15).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func recentRow(_ shot: Shot) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(shot.beanName ?? "Unknown bean")
                    .font(.body)
                Text("\(shot.drink.displayName) · \(shot.date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(ShotTimerViewModel.format(shot.totalSeconds))s · \(shot.ratioText)")
                    .font(.callout.monospacedDigit())
                if shot.rating > 0 {
                    HStack(spacing: 1) {
                        ForEach(0..<shot.rating, id: \.self) { _ in
                            Image(systemName: "star.fill").imageScale(.small)
                        }
                    }
                    .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(shot)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func saveShot() {
        let bean = beans.first { $0.slug == selectedBeanSlug }
        let shot = Shot(
            beanName: bean?.name,
            beanSlug: bean?.slug,
            drink: drink,
            doseGrams: dose,
            yieldGrams: yield,
            preInfusionSeconds: vm.preInfusionSeconds ?? 0,
            totalSeconds: vm.elapsed,
            grindSetting: bean?.recGrinder,
            rating: rating,
            notes: notes
        )
        modelContext.insert(shot)
        try? modelContext.save()

        // Reset for the next shot, keeping bean/drink/dose selections.
        vm.reset()
        rating = 0
        notes = ""
    }
}

#Preview {
    ShotTimerView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 700, height: 800)
}
