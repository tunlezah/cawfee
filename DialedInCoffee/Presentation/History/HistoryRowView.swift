import SwiftUI

struct HistoryRowView: View {
    @Bindable var entry: AdjustmentHistoryEntry

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(Self.dateFormatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let beanName = entry.beanName {
                    Text("·").foregroundStyle(.secondary)
                    Text(beanName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Outcome", selection: $entry.outcome) {
                    ForEach(AdjustmentOutcome.allCases, id: \.self) { o in
                        Text(o.displayName).tag(o)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }
            HStack(spacing: 6) {
                Image(systemName: "cup.and.saucer")
                Text(entry.drink.displayName)
                Text("·").foregroundStyle(.secondary)
                Text("\(parameterName(entry.primaryParameter)): \(beforeValue) → \(afterValue)")
                    .monospaced()
                    .font(.callout)
            }
            if !entry.symptoms.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(entry.symptoms) { symptom in
                        Text(symptom.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.background.tertiary, in: Capsule())
                    }
                }
            }
            if !entry.rationale.isEmpty {
                Text(entry.rationale)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var beforeValue: String { displayValue(parameter: entry.primaryParameter, settings: entry.beforeSettings) }
    private var afterValue: String { displayValue(parameter: entry.primaryParameter, settings: entry.afterSettings) }

    private func displayValue(parameter: AdjustmentParameter, settings: MachineSettings) -> String {
        switch parameter {
        case .grinder: return "\(settings.grinder)"
        case .strength: return "\(settings.strength)"
        case .volume: return "\(settings.volumeML)ml"
        case .milkDuration: return "\(settings.milkSeconds)s"
        case .temperature: return settings.temperature.displayName
        case .beans: return "—"
        }
    }

    private func parameterName(_ param: AdjustmentParameter) -> String {
        switch param {
        case .grinder: return "Grinder"
        case .strength: return "Strength"
        case .volume: return "Volume"
        case .milkDuration: return "Milk"
        case .temperature: return "Temp"
        case .beans: return "Bean"
        }
    }
}
