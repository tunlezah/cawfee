import SwiftUI

public struct MachineSettingsEditor: View {
    @Binding public var settings: MachineSettings
    public var showsMilk: Bool

    public init(settings: Binding<MachineSettings>, showsMilk: Bool = true) {
        self._settings = settings
        self.showsMilk = showsMilk
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            row(label: "Grinder", value: settings.grinder, range: MachineRanges.grinderRange) { settings.grinder = $0 }
            row(label: "Strength", value: settings.strength, range: MachineRanges.strengthRange) { settings.strength = $0 }
            row(label: "Volume (ml)", value: settings.volumeML, range: MachineRanges.volumeRange, step: 5) { settings.volumeML = $0 }
            if showsMilk {
                row(label: "Milk (s)", value: settings.milkSeconds, range: MachineRanges.milkDurationRange) { settings.milkSeconds = $0 }
            }
            HStack {
                Text("Temperature")
                    .frame(width: 110, alignment: .leading)
                Picker("", selection: $settings.temperature) {
                    ForEach(TemperatureLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
        }
    }

    @ViewBuilder
    private func row(
        label: String,
        value: Int,
        range: ClosedRange<Int>,
        step: Int = 1,
        set: @escaping (Int) -> Void
    ) -> some View {
        HStack {
            Text(label)
                .frame(width: 110, alignment: .leading)
            Stepper(value: Binding(get: { value }, set: { set($0) }), in: range, step: step) {
                Text("\(value)")
                    .monospacedDigit()
                    .frame(minWidth: 36, alignment: .leading)
            }
        }
    }
}

#Preview {
    StatefulPreviewWrapper(MachineSettings()) { binding in
        MachineSettingsEditor(settings: binding)
            .padding()
            .frame(width: 360)
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initial)
        self.content = content
    }

    var body: some View { content($value) }
}
