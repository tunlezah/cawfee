# Android Feature Inventory (post-remediation)

App: **Cawfee** — `android/` — Jetpack Compose + Room + Hilt + DataStore, fully offline.
Modules: `:core` (pure-JVM domain + rules engine), `:protocol` (pure-JVM Jura BLE protocol),
`:app` (Compose UI, Room, Hilt, BLE). Entry: `MainActivity` → `OnboardingScreen` (first
launch) or `navigation/CawfeeApp.kt` (adaptive bottom-bar / navigation-rail).

Status legend: **Implemented** / Partially / Stubbed / Missing.

| Feature | Status | Source |
|---|---|---|
| Dashboard | Implemented | `ui/dashboard/DashboardScreen.kt` |
| Fix My Coffee | Implemented | `ui/fix/FixMyCoffeeViewModel.kt` + `FixMyCoffeeScreen.kt` (history persistence, bean select, prefs default, settings editor) |
| Expert Mode | Implemented | `FixMyCoffeeScreen(expertMode=true)` (rule contributions) |
| Shot Timer | Implemented | `ui/shots/ShotTimerViewModel.kt` (persists `ShotEntity`) |
| Machine / Bluetooth | Implemented | `bluetooth/*`, `ui/machine/*` (scan/connect/brew/lock/stats) |
| Beans | Implemented | `ui/beans/*`, `BeanEntity`/`BeanDao`, freshness via `core/Freshness.kt` |
| Recipes | Implemented | `ui/recipes/*`, `RecipeEntity`/`RecipeDao` |
| Tasting Log | Implemented | `ui/tasting/*`, `TastingNoteEntity`, `core/SensoryWheel.kt` |
| History | Implemented | `ui/history/*`, `HistoryEntity`/`HistoryDao` |
| Ratio Converter | Implemented | `ui/tools/ToolScreens.kt` |
| Style Presets | Implemented | `ui/tools/ToolScreens.kt` |
| Water | Implemented | `ui/water/*`, `WaterProfileEntity` |
| Maintenance | Implemented | `ui/maintenance/*`, `MaintenanceTaskEntity` |
| Settings | Implemented | `ui/settings/*` |
| Onboarding | Implemented | `ui/onboarding/*` |
| Persistence (Room v2) | Implemented | `data/local/CawfeeDatabase.kt` (7 entities + 7 DAOs + `Converters`) |
| Seeding | Implemented | `data/CoffeeRepository.seedIfNeeded()` + `data/SeedData.kt` + `assets/beans.json` |
| Preferences | Implemented | `data/PreferencesRepository.kt` (DataStore) |
| Rules engine | Implemented | `:core` `domain/rules/*` (shared, unit-tested) |
| BLE protocol | Implemented | `:protocol` `bluetooth/*` (shared, unit-tested) |

## Data layer
Room `CawfeeDatabase` v2 entities: `ShotEntity, BeanEntity, RecipeEntity,
TastingNoteEntity, HistoryEntity, MaintenanceTaskEntity, WaterProfileEntity`. List columns
use `Converters` (newline-delimited). DI in `di/DatabaseModule.kt` + `di/AppModule.kt`.
Single facade `data/CoffeeRepository.kt`; entity↔domain mapping in `data/CoffeeMappers.kt`.

## Removed in this pass
`ui/misc/PlaceholderScreen.kt` (the 6 "coming soon" stubs) and the placeholder
instrumented test — replaced by real screens and `SectionCardUiTest`.

## Build note
`:core` and `:protocol` build and unit-test on any JVM (no Android SDK). The `:app`
module requires the Android SDK **and** access to Google's Maven repository; it builds on
GitHub Actions (`.github/workflows/android.yml`). It cannot be built inside network
policies that block `dl.google.com`/`maven.google.com`.
