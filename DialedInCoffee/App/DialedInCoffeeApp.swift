import SwiftUI
import SwiftData

@main
struct DialedInCoffeeApp: App {
    static let sharedContainer: ModelContainer = ModelContainerFactory.makeShared()

    @State private var didBootstrap = false

    var body: some Scene {
        WindowGroup("Dialed In Coffee") {
            AppRoot()
                .frame(minWidth: 900, minHeight: 600)
                .preferredColorSchemeFromPreferences()
                .task {
                    if !didBootstrap {
                        SeedLoader.bootstrapIfNeeded(context: Self.sharedContainer.mainContext)
                        didBootstrap = true
                    }
                }
        }
        .modelContainer(Self.sharedContainer)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {} // no document-style new
            CommandGroup(after: .appInfo) {
                Button("Re-seed Bean Catalog") {
                    let ctx = Self.sharedContainer.mainContext
                    let prefs = SeedLoader.preferences(in: ctx)
                    prefs.hasSeededBeans = false
                    SeedLoader.bootstrapIfNeeded(context: ctx)
                }
            }
        }
    }
}

private struct AppearanceModifier: ViewModifier {
    @Query private var prefsList: [UserPreferences]

    func body(content: Content) -> some View {
        let appearance = prefsList.first?.appearance ?? .system
        switch appearance {
        case .system: content
        case .light: content.preferredColorScheme(.light)
        case .dark: content.preferredColorScheme(.dark)
        }
    }
}

private extension View {
    func preferredColorSchemeFromPreferences() -> some View {
        modifier(AppearanceModifier())
    }
}
