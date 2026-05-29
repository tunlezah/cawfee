import SwiftUI

struct SymptomPickerView: View {
    @Binding var selection: Set<Symptom>

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 150, maximum: 240), spacing: 8, alignment: .leading)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("What tastes wrong?")
                .font(.headline)
            Text("Tap one or more. Use simple words — no jargon.")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(Symptom.allCases) { symptom in
                    SymptomChip(symptom: symptom, isSelected: selection.contains(symptom)) {
                        if selection.contains(symptom) {
                            selection.remove(symptom)
                        } else {
                            selection.insert(symptom)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    StatefulPreviewWrapper(Set<Symptom>([.tooBitter])) { binding in
        SymptomPickerView(selection: binding)
            .padding()
            .frame(width: 700)
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
