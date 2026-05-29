import SwiftUI

public struct SymptomChip: View {
    public let symptom: Symptom
    public let isSelected: Bool
    public let onTap: () -> Void

    public init(symptom: Symptom, isSelected: Bool, onTap: @escaping () -> Void) {
        self.symptom = symptom
        self.isSelected = isSelected
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: symptom.symbolName)
                    .imageScale(.small)
                Text(symptom.displayName)
                    .font(.callout)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                ? AnyShapeStyle(Color.accentColor.opacity(0.22))
                : AnyShapeStyle(.background.tertiary),
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.55) : Color.separator.opacity(0.6),
                    lineWidth: isSelected ? 1.2 : 0.8
                )
            )
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension Color {
    static var separator: Color { Color.secondary.opacity(0.4) }
}

#Preview {
    HStack {
        SymptomChip(symptom: .tooBitter, isSelected: false) {}
        SymptomChip(symptom: .tooSour, isSelected: true) {}
    }
    .padding()
}
