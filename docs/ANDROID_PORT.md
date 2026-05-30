# Cawfee — Android Port

This document describes the Android port of the **DialedInCoffee** (Cawfee) app and how
to build, run, and test it. The Android project lives in [`/android`](../android).

## 1. Goals

- Native Android app (Kotlin + Jetpack Compose, Material 3, dark mode).
- Targets Android 13 tablets and Android 14 phones; adaptive layouts + landscape.
- Full Bluetooth control of the Jura E8 (see [BLUETOOTH_ARCHITECTURE.md](BLUETOOTH_ARCHITECTURE.md)).
- One protocol strategy shared (in spirit and structure) with the macOS app.

## 2. Module structure

The project is a Gradle multi-module build:

| Module | Type | Builds without Android SDK? | Purpose |
|---|---|---|---|
| `:core` | Kotlin/JVM | ✅ yes | Coffee domain + RulesEngine, ported 1:1 from Swift. |
| `:protocol` | Kotlin/JVM | ✅ yes | Platform-independent Jura BLE protocol (cipher, commands, parsers, machine catalog). |
| `:app` | Android application | ❌ needs SDK | Compose UI, Android BLE, Hilt, Room, DataStore. |

`settings.gradle.kts` includes `:app` **only when an Android SDK is present**
(`ANDROID_HOME`/`ANDROID_SDK_ROOT`/`local.properties`). This lets the pure-JVM logic be
compiled and unit-tested on any machine or CI runner without the SDK.

### `:app` package layout (`com.cawfee`)

```
com.cawfee
├── bluetooth            # Android BLE: scanner, connection (GATT queue), JuraBleClient, service
│   ├── scanner
│   └── connection
├── data                 # Room database + DAOs, DataStore preferences
│   └── local
├── di                   # Hilt modules (AppModule, DatabaseModule)
├── navigation           # adaptive NavigationBar/Rail + NavHost
├── repository           # MachineRepository (repository pattern over the BLE client)
└── ui                   # Compose screens + ViewModels (MVVM)
    ├── machine fix shots dashboard settings tools misc theme
```

## 3. Architecture

- **Pattern:** MVVM + Repository. ViewModels expose `StateFlow`; the UI collects with
  `collectAsStateWithLifecycle`.
- **DI:** Hilt (`@HiltAndroidApp`, `@HiltViewModel`, `@AndroidEntryPoint`).
- **Async:** Coroutines + Flow throughout; a singleton application `CoroutineScope` hosts
  the BLE heartbeat/reconnection loops.
- **Persistence:** Room (`ShotEntity` + `ShotDao` as the representative port) and Jetpack
  DataStore for preferences (replacing the SwiftData `UserPreferences` singleton).
- **Domain reuse:** the entire `RulesEngine` (46 rules, log-odds cause aggregation,
  adjustment planner, Australian-style bias, learning heuristics) is ported verbatim into
  `:core` and exercised by the Android `FixMyCoffeeViewModel`.

### Swift → Kotlin mapping (summary)

| Swift | Kotlin |
|---|---|
| `Domain/*`, value-type `Models/*` | `:core` `com.cawfee.domain.model` |
| `RulesEngine/*` | `:core` `com.cawfee.domain.rules` |
| SwiftData `@Model` types | Room `@Entity` + `@Dao` (Shot done; others tracked below) |
| `UserPreferences` singleton | DataStore `PreferencesRepository` |
| `AppRoot` `NavigationSplitView` | adaptive `NavigationBar`/`NavigationRail` + `NavHost` |
| SwiftUI views | Compose screens (Material 3) |
| XCTest suites | JUnit5 (`:core`), JUnit4 + Compose UI tests (`:app`) |

## 4. Screen status

| Screen | Status |
|---|---|
| Machine (Bluetooth control) | ✅ implemented (new) |
| Fix My Coffee / Expert Mode | ✅ implemented (uses ported RulesEngine) |
| Shot Timer | ✅ implemented |
| Dashboard | ✅ implemented (navigation hub) |
| Settings | ✅ implemented (DataStore-backed) |
| Ratio Converter, Style Presets | ✅ implemented |
| Beans, Recipes, Tasting Log, History, Water, Maintenance | 🚧 scaffolded placeholders; domain models + Room pattern in place |

The placeholder screens are intentionally simple; the Room entity/DAO pattern in
`data/local/CawfeeDatabase.kt` and the ported domain models make them mechanical to fill in.

## 5. Build

Requirements: JDK 17, Android SDK (compileSdk 35), the bundled Gradle wrapper.

```bash
cd android

# Pure-JVM logic — no Android SDK required:
./gradlew :core:test :protocol:test

# Full app (Android SDK required):
./gradlew :app:assembleDebug          # sideloadable debug APK
./gradlew :app:bundleRelease          # Play AAB
./gradlew testDebugUnitTest           # all unit tests
./gradlew :app:connectedDebugAndroidTest   # Compose UI tests (device/emulator)
```

Outputs:
- APK: `app/build/outputs/apk/debug/app-debug.apk`
- AAB: `app/build/outputs/bundle/release/app-release.aab`

CI produces both as workflow artifacts — see [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md).

## 6. Testing

- `:protocol` — 23 tests validating the cipher/commands/parsers against the spec's
  executed vectors.
- `:core` — 27 tests; the Swift XCTest suites re-expressed in JUnit5 (rules engine,
  aggregator, planner, learning heuristics, ranges) with identical expected values.
- `:app` — ViewModel unit tests + a Compose UI test.

All `:core`/`:protocol` tests run on any JVM:

```bash
cd android && ./gradlew :core:test :protocol:test   # 50 tests, green
```
