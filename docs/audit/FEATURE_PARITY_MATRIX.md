# Feature Parity Matrix — macOS (source of truth) vs Android

Status legend: **COMPLETE** / **PARTIAL** / **MISSING**.
macOS = `DialedInCoffee/` (SwiftUI + SwiftData). Android = `android/` (Compose + Room + Hilt).
Every row below was verified from executable source, not documentation.

| Feature | macOS Status | Android Status | Parity | Evidence (Android) |
|---|---|---|---|---|
| Dashboard / shortcuts | COMPLETE | COMPLETE | **COMPLETE** | `ui/dashboard/DashboardScreen.kt` |
| Fix My Coffee (rules engine) | COMPLETE | COMPLETE | **COMPLETE** | `ui/fix/FixMyCoffeeViewModel.kt` — now persists history, bean selection, history-fed learning, prefs default, settings editor |
| Expert Mode (rule contributions) | COMPLETE | COMPLETE | **COMPLETE** | `FixMyCoffeeScreen(expertMode=true)` |
| Shot Timer | COMPLETE | COMPLETE | **COMPLETE** | `ui/shots/ShotTimerViewModel.kt` — now saves shots to Room (feeds maintenance count) |
| Machine / Bluetooth control | COMPLETE | COMPLETE | **COMPLETE** | `bluetooth/JuraBleClient.kt`, `ui/machine/MachineScreen.kt` |
| Beans (list + detail + editor + freshness) | COMPLETE | COMPLETE | **COMPLETE** | `ui/beans/BeansScreen.kt`, `data/local` `BeanEntity`/`BeanDao` |
| Recipes (list + editor + favourite/last-good) | COMPLETE | COMPLETE | **COMPLETE** | `ui/recipes/RecipesScreen.kt`, `RecipeEntity`/`RecipeDao` |
| Tasting Log (sensory wheel + intensities) | COMPLETE | COMPLETE | **COMPLETE** | `ui/tasting/TastingScreen.kt`, `TastingNoteEntity` + `core/SensoryWheel.kt` |
| History (adjustment log + outcome + last-good) | COMPLETE | COMPLETE | **COMPLETE** | `ui/history/HistoryScreen.kt`, `HistoryEntity`/`HistoryDao` |
| Ratio Converter | COMPLETE | COMPLETE | **COMPLETE** | `ui/tools/ToolScreens.kt` |
| Style Presets | COMPLETE | COMPLETE | **COMPLETE** | `ui/tools/ToolScreens.kt` + `core/AustralianStyle.kt` |
| Water (mineral profiles + assessment) | COMPLETE | COMPLETE | **COMPLETE** | `ui/water/WaterScreen.kt`, `WaterProfileEntity` + `data/SeedData.kt` |
| Maintenance (due-by-days/shots) | COMPLETE | COMPLETE | **COMPLETE** | `ui/maintenance/MaintenanceScreen.kt`, `MaintenanceTaskEntity` |
| Settings (mode/appearance/default drink) | COMPLETE | COMPLETE | **COMPLETE** | `ui/settings/SettingsScreen.kt` |
| Onboarding (first-launch coach) | COMPLETE | COMPLETE | **COMPLETE** | `ui/onboarding/OnboardingScreen.kt` (wired in `MainActivity`) |
| Bean catalogue seed (102 beans) | COMPLETE | COMPLETE | **COMPLETE** | `app/src/main/assets/beans.json` + `CoffeeRepository.seedIfNeeded()` |
| Water + maintenance seed | COMPLETE | COMPLETE | **COMPLETE** | `data/SeedData.kt` |
| Local persistence | COMPLETE (SwiftData) | COMPLETE (Room v2) | **COMPLETE** | `data/local/CawfeeDatabase.kt` — 7 entities |
| Preferences | COMPLETE (SwiftData singleton) | COMPLETE (DataStore) | **COMPLETE** | `data/PreferencesRepository.kt` |
| Appearance (system/light/dark) | COMPLETE | COMPLETE | **COMPLETE** | `MainActivity.kt` |
| **Default coffee = Cappuccino** | COMPLETE | COMPLETE | **COMPLETE** | see `DEFAULT_COFFEE_AUDIT.md` |

## Bluetooth command parity (see BLUETOOTH_FORENSIC_REPORT.md)

| Capability | macOS | Android | Parity |
|---|---|---|---|
| Advertisement parse / key extraction | ✓ | ✓ | COMPLETE |
| Cipher (encrypt / encDecRaw) | ✓ | ✓ | COMPLETE |
| Start Product frame | ✓ | ✓ | COMPLETE |
| Heartbeat / keep-alive | ✓ | ✓ | COMPLETE |
| Barista lock/unlock | ✓ | ✓ | COMPLETE |
| Statistics request + parse | ✓ | ✓ | COMPLETE |
| Status / alert bitfield parse | ✓ | ✓ | COMPLETE |
| Machine catalogue (E8 products) | ✓ (now incl. 2 Ristretti/2 Espressi/2 Coffees) | ✓ | COMPLETE |

## Pre-remediation state (for the record)

Before this pass, Android shipped **6 `PlaceholderScreen("… — coming soon")` stubs**
(Beans, Recipes, Tasting Log, History, Water, Maintenance), a Room DB with **only**
`ShotEntity`, a Fix-My-Coffee screen that never persisted history or used beans/history,
a Shot Timer that never saved shots, no onboarding, and a Flat White default. All are
now resolved — every row above is COMPLETE.
