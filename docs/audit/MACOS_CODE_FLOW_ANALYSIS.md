# macOS Code-Flow Analysis (Phase 2)

Execution paths for each macOS feature, UI → ViewModel → service/repo → persistence/BLE.
macOS uses SwiftUI views that read SwiftData directly via `@Query` and mutate via
`@Environment(\.modelContext)`; there is no separate repository layer except for Bluetooth.

## Layered map

- **UI:** `Presentation/**/*.swift` (SwiftUI views, `@Query`, `@Bindable`).
- **ViewModel:** only where logic warrants it —
  `FixMyCoffee/FixMyCoffeeViewModel.swift`, `Shots/ShotTimerViewModel.swift`.
- **Domain / rules:** `RulesEngine/*` + `Domain/*` (pure value types).
- **Persistence:** SwiftData `@Model` types in `Models/*`, container in
  `Persistence/ModelContainerFactory.swift`, seeding in `Persistence/SeedLoader.swift`.
- **Bluetooth:** `Bluetooth/CoreBluetooth/JuraBluetoothManager.swift` (ObservableObject) →
  `Bluetooth/Protocol/*` (UUIDs, cipher, commands, parsers).

## Feature flows

| Feature | UI entry | ViewModel | Domain/Service | Persistence | BLE |
|---|---|---|---|---|---|
| Fix My Coffee | `FixMyCoffeeView` | `FixMyCoffeeViewModel.evaluate / applyAndLog` | `RulesEngine.evaluate` → `Recommendation` | reads `BeanProfile`,`AdjustmentHistoryEntry`; writes `AdjustmentHistoryEntry` | — |
| Expert Mode | `ExpertModeView` + `RuleContributionsView` | `FixMyCoffeeViewModel` | `RulesEngine` (novice=false) | same | — |
| Shot Timer | `ShotTimerView` | `ShotTimerViewModel` | — | writes `Shot` | — |
| Machine | `MachineControlView` | `JuraBluetoothManager` (ObservableObject) | `JuraCommands`/`JuraParsers` | — | CoreBluetooth |
| Beans | `BeansListView`→`BeanDetailView`/`BeanEditorView` | — | `BeanProfile+Freshness` | `BeanProfile` | — |
| Recipes | `RecipesListView`→`RecipeDetailView`/`RecipeEditorView` | — | — | `Recipe` (+`BeanProfile` rel) | — |
| Tasting Log | `TastingLogView`→`TastingNoteEditorView` | — | `SensoryWheel` | `TastingNote` | — |
| History | `HistoryView`→`HistoryRowView` | — | `HistorySnapshot` | `AdjustmentHistoryEntry`,`Recipe` | — |
| Ratio Converter | `RatioConverterView` | local `@State` | `AustralianStylePreset` | — | — |
| Style Presets | `StylePresetsView` | — | `AustralianStylePreset` | — | — |
| Water | `WaterView`(+`WaterProfileEditor`) | — | `WaterProfile.Assessment` | `WaterProfile` | — |
| Maintenance | `MaintenanceView`(+`MaintenanceEditor`) | — | `MaintenanceTask` due logic; counts `Shot` | `MaintenanceTask`,`Shot` | — |
| Settings | `SettingsView` | — | — | `UserPreferences` | — |
| Onboarding | `OnboardingView` | — | `AustralianStylePreset` | `UserPreferences` | — |

## Android mirror
The Android architecture inserts an explicit repository layer (`data/CoffeeRepository.kt`)
and per-screen ViewModels because Compose cannot query the DB inline the way SwiftUI's
`@Query` does. Domain + rules + BLE protocol are shared, platform-independent ports in
`:core` and `:protocol`. Each Swift `@Model` maps to a Room `@Entity` (see
`ANDROID_FEATURE_INVENTORY.md` and `data/CoffeeMappers.kt`).
