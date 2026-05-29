import SwiftUI

struct CurrentSettingsPanel: View {
    @Binding var drink: DrinkType
    @Binding var milkKind: MilkKind
    @Binding var settings: MachineSettings
    @Binding var beanSlug: String?
    let beans: [BeanProfile]
    let onResetForDrink: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Current cup")
                    .font(.headline)
                Spacer()
                Button("Use defaults for drink", action: onResetForDrink)
                    .buttonStyle(.borderless)
                    .font(.caption)
            }
            HStack(alignment: .top, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    pickerRow("Drink", selection: $drink) {
                        ForEach(DrinkType.allCases) { d in
                            Label(d.displayName, systemImage: d.symbolName).tag(d)
                        }
                    }
                    pickerRow("Milk", selection: $milkKind) {
                        ForEach(MilkKind.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    pickerRow("Bean", selection: Binding(
                        get: { beanSlug ?? "" },
                        set: { beanSlug = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("None").tag("")
                        ForEach(beans, id: \.slug) { bean in
                            Text("\(bean.roaster) — \(bean.name)").tag(bean.slug)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                MachineSettingsEditor(settings: $settings, showsMilk: drink.isMilkBased)
                    .frame(maxWidth: .infinity)
            }
        }
        .panelStyle()
    }

    @ViewBuilder
    private func pickerRow<Value: Hashable, Content: View>(
        _ label: String,
        selection: Binding<Value>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(label)
                .frame(width: 60, alignment: .leading)
            Picker(label, selection: selection) {
                content()
            }
            .labelsHidden()
        }
    }
}
