import SwiftUI

struct DashboardCard<Content: View>: View {
    let title: String
    let symbol: String
    let content: () -> Content

    init(title: String, symbol: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.symbol = symbol
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label(title, systemImage: symbol)
                .font(.headline)
            content()
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: Theme.Corner.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Corner.card, style: .continuous)
                .strokeBorder(.separator.opacity(0.5))
        )
    }
}
