import SwiftUI
import SwiftData

/// First-launch dial-in coach. Captures the machine, default drink style and
/// water, then explains the starting workflow. Writes to UserPreferences and
/// flips `hasCompletedOnboarding`. Fully local.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    let prefs: UserPreferences
    var onFinish: () -> Void

    @State private var step = 0
    @State private var machineName = ""
    @State private var drink: DrinkType = .cappuccino

    private let lastStep = 3

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView(value: Double(step), total: Double(lastStep))
                .tint(.accentColor)

            Group {
                switch step {
                case 0: welcome
                case 1: machineStep
                case 2: styleStep
                default: readyStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                if step > 0 {
                    Button("Back") { withAnimation { step -= 1 } }
                }
                Spacer()
                if step < lastStep {
                    Button("Continue") { withAnimation { step += 1 } }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Start brewing") { finish() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(width: 520, height: 460)
    }

    private var welcome: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Welcome to Dialed In")
                .font(.largeTitle.weight(.bold))
            Text("A fully offline espresso companion built for Canberra. Let's set you up in a few taps — your bean library is already loaded with local roasters and supermarket beans.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var machineStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label("Your machine", systemImage: "gearshape.2")
                .font(.title2.weight(.semibold))
            Text("Optional — name your espresso machine so settings feel like yours.")
                .font(.callout).foregroundStyle(.secondary)
            TextField("e.g. Breville Barista Express", text: $machineName)
                .textFieldStyle(.roundedBorder)
            Spacer()
        }
    }

    private var styleStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label("Your usual order", systemImage: "cup.and.saucer.fill")
                .font(.title2.weight(.semibold))
            Text("We'll default new recipes and the shot timer to this drink.")
                .font(.callout).foregroundStyle(.secondary)
            Picker("Default drink", selection: $drink) {
                ForEach(DrinkType.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            if let preset = AustralianStylePreset.all.first(where: { $0.drink == drink }) {
                Text("\(preset.name): aim for a \(preset.ratioText) ratio. \(preset.blurb)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label("You're set", systemImage: "checkmark.seal.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.green)
            Text("How to dial in:")
                .font(.headline)
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                tip("1", "Pick a bean in Beans and add its roast date for freshness tracking.")
                tip("2", "Pull a shot with the Shot Timer — aim for the ratio in Ratio Converter.")
                tip("3", "Taste it. If it's off, use Fix My Coffee to get a single adjustment.")
                tip("4", "Log how it tasted in the Tasting Log and repeat.")
            }
            Text("Everything stays on this device — no account, no internet.")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func tip(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Text(n)
                .font(.caption.weight(.bold))
                .frame(width: 20, height: 20)
                .background(.tint.opacity(0.2), in: Circle())
            Text(text).font(.callout)
        }
    }

    private func finish() {
        prefs.machineName = machineName
        prefs.defaultDrink = drink
        prefs.hasCompletedOnboarding = true
        try? modelContext.save()
        onFinish()
    }
}
