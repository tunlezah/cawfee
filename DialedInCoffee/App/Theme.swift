import SwiftUI

public enum Theme {
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 32
    }

    public enum Corner {
        public static let panel: CGFloat = 12
        public static let card: CGFloat = 16
        public static let chip: CGFloat = 999
    }

    public enum Sidebar {
        public static let minWidth: CGFloat = 200
        public static let idealWidth: CGFloat = 220
        public static let maxWidth: CGFloat = 260
    }

    public enum Detail {
        public static let minWidth: CGFloat = 640
        public static let idealWidth: CGFloat = 820
    }

    public static let accent = Color.accentColor
}

public extension View {
    func panelStyle() -> some View {
        self
            .padding(Theme.Spacing.lg)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: Theme.Corner.panel, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Corner.panel, style: .continuous)
                    .strokeBorder(.separator.opacity(0.5))
            )
    }
}
