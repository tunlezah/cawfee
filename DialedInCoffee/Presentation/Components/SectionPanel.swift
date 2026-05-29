import SwiftUI

public struct SectionPanel<Content: View>: View {
    private let title: String?
    private let systemImage: String?
    private let content: () -> Content

    public init(
        _ title: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if let title {
                HStack(spacing: Theme.Spacing.sm) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .foregroundStyle(.secondary)
                    }
                    Text(title)
                        .font(.headline)
                }
            }
            content()
        }
        .panelStyle()
    }
}

#Preview {
    SectionPanel("Example", systemImage: "leaf") {
        Text("Body content goes here.")
            .font(.body)
    }
    .padding()
    .frame(width: 400)
}
