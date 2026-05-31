# macOS Feature Inventory (source of truth)

App: **Dialed In Coffee** — `DialedInCoffee/` — SwiftUI + SwiftData, macOS, fully offline.
Entry: `App/DialedInCoffeeApp.swift` → `App/AppRoot.swift` (NavigationSplitView). Sidebar
sections defined in `App/AppSection.swift` (14 sections). First launch shows
`Presentation/Onboarding/OnboardingView.swift` as a sheet; `Persistence/SeedLoader.swift`
seeds beans/water/maintenance.

Navigation groups (sidebar): **Workflow** (Dashboard, Fix My Coffee, Shot Timer, Machine),
**Library** (Beans, Recipes, Tasting Log, History), **Tools** (Ratio Converter, Style
Presets, Water, Maintenance), **Advanced** (Expert Mode, Settings).

| Screen | Purpose | Nav path | Key actions / controls | Sheets / dialogs | Storage | Networking | Bluetooth |
|---|---|---|---|---|---|---|---|
| Dashboard | At-a-glance cards | Workflow | navigate to cards | — | reads SwiftData | none | none |
| Fix My Coffee | Symptom → single adjustment via rules engine | Workflow | drink/milk/bean pickers, settings editor, symptom chips, evaluate, apply&log | — | writes `AdjustmentHistoryEntry` | none | none |
| Expert Mode | Fix My Coffee + rule contributions | Advanced | same + `RuleContributionsView` | — | same | none | none |
| Shot Timer | Stopwatch + pre-infusion + save shot | Workflow | start/stop, pre-infusion, dose/yield, rating, save | — | writes `Shot` | none | none |
| Machine | BLE control of Jura | Workflow | scan, connect, brew product, barista lock, statistics, refresh, disconnect | — | none | **CoreBluetooth** (`JuraBluetoothManager`) |
| Beans | Bean library | Library | list grouped by roaster, search, new/edit | `BeanEditorView` | `BeanProfile` | none | none |
| Recipes | Saved dial-ins | Library | list, new/edit, delete, favourite/last-good | `RecipeEditorView` | `Recipe` | none | none |
| Tasting Log | Sensory notes | Library | list, new/edit, delete, sensory wheel, intensity, rating | `TastingNoteEditorView` | `TastingNote` | none | none |
| History | Adjustment history | Library | list, set outcome, delete, last-good banner | — | `AdjustmentHistoryEntry`, `Recipe` | none | none |
| Ratio Converter | Brew-ratio calculator | Tools | solve yield/dose, presets | — | none (pure tool) | none | none |
| Style Presets | Aussie café reference | Tools | read-only | — | none | none | none |
| Water | Mineral profiles | Tools | list, new/edit, delete, make default | `WaterProfileEditor` | `WaterProfile` | none | none |
| Maintenance | Cleaning/descale tracker | Tools | list, mark done, new, delete; due by days/shots | `MaintenanceEditor` | `MaintenanceTask`, counts `Shot` | none | none |
| Settings | Mode/appearance/default drink | Advanced | segmented + chips | — | `UserPreferences` | none | none |
| Onboarding | First-launch coach | sheet | 4 steps: welcome, machine, default drink, ready | sheet | `UserPreferences` | none | none |

## Persistence (SwiftData)
`Persistence/ModelContainerFactory.swift` registers 9 `@Model` types:
`BeanProfile, Recipe, AdjustmentHistoryEntry, SymptomLog, UserPreferences, Shot,
MaintenanceTask, WaterProfile, TastingNote`.
Seed data: `Resources/Seed/beans.json` (102 beans), `SeedLoader.defaultWaterProfiles()` (3),
`SeedLoader.defaultMaintenanceTasks()` (6).

## Rules engine (`RulesEngine/`)
`RulesEngine.evaluate(symptoms, current, milk, drink, bean, recentHistory, novice)` →
`Recommendation` (primary/secondary `Adjustment`, top `Cause`, confidence, contributions,
suggestRevertToLastGood). Supporting: `RuleSet`, `Rule`, `Condition`, `CauseAggregator`,
`AdjustmentPlanner`, `LearningHeuristics`, `ExplanationBuilder`.

## Bluetooth (`Bluetooth/`)
`CoreBluetooth/JuraBluetoothManager.swift` + protocol layer
(`JuraGatt`, `JuraCipher`, `JuraCommands`, `JuraParsers`). See `BLUETOOTH_FORENSIC_REPORT.md`.

No screen performs any networking. Everything is on-device.
