import SwiftUI
import SwiftData

struct AppRoot: View {
    @Environment(\.modelContext) private var modelContext
    @SceneStorage("sidebarSelection") private var selectionRaw: String = AppSection.dashboard.rawValue
    @State private var visibility: NavigationSplitViewVisibility = .all
    @Query private var prefsList: [UserPreferences]

    private var selection: Binding<AppSection?> {
        Binding(
            get: { AppSection(rawValue: selectionRaw) ?? .dashboard },
            set: { newValue in selectionRaw = (newValue ?? .dashboard).rawValue }
        )
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: shouldShowOnboarding) {
            OnboardingView(prefs: onboardingPrefs) {}
                .interactiveDismissDisabled(true)
        }
    }

    private var shouldShowOnboarding: Binding<Bool> {
        Binding(
            get: { !(prefsList.first?.hasCompletedOnboarding ?? false) && prefsList.first != nil },
            set: { _ in }
        )
    }

    private var onboardingPrefs: UserPreferences {
        if let p = prefsList.first { return p }
        let p = UserPreferences()
        modelContext.insert(p)
        try? modelContext.save()
        return p
    }

    private var sidebar: some View {
        List(selection: selection) {
            Section("Workflow") {
                row(.dashboard)
                row(.fixMyCoffee)
                row(.shotTimer)
                row(.machine)
            }
            Section("Library") {
                row(.beans)
                row(.recipes)
                row(.tastingLog)
                row(.history)
            }
            Section("Tools") {
                row(.ratioConverter)
                row(.styles)
                row(.water)
                row(.maintenance)
            }
            Section("Advanced") {
                row(.expertMode)
                row(.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Dialed In")
        .navigationSplitViewColumnWidth(
            min: Theme.Sidebar.minWidth,
            ideal: Theme.Sidebar.idealWidth,
            max: Theme.Sidebar.maxWidth
        )
    }

    private func row(_ section: AppSection) -> some View {
        Label(section.displayName, systemImage: section.symbolName)
            .tag(section)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection.wrappedValue ?? .dashboard {
        case .dashboard: DashboardView()
        case .fixMyCoffee: FixMyCoffeeView()
        case .shotTimer: ShotTimerView()
        case .machine: MachineControlView()
        case .beans: BeansListView()
        case .recipes: RecipesListView()
        case .tastingLog: TastingLogView()
        case .ratioConverter: RatioConverterView()
        case .styles: StylePresetsView()
        case .water: WaterView()
        case .maintenance: MaintenanceView()
        case .expertMode: ExpertModeView()
        case .history: HistoryView()
        case .settings: SettingsView()
        }
    }
}

#Preview("AppRoot — Light") {
    AppRoot()
        .modelContainer(PreviewData.previewContainer())
        .preferredColorScheme(.light)
}

#Preview("AppRoot — Dark") {
    AppRoot()
        .modelContainer(PreviewData.previewContainer())
        .preferredColorScheme(.dark)
}
