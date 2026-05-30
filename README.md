# Cawfee / Dialed In Coffee

A fully-offline espresso companion for dialling in your coffee, built for Canberra
roasters and a Jura E8 (Smart Connect) machine. The project ships **two apps that are at
feature parity**:

- **Dialed In Coffee** — macOS / iOS app (SwiftUI + SwiftData) in `DialedInCoffee/`.
- **Cawfee** — Android app (Jetpack Compose + Room + Hilt) in `android/`.

Both run entirely on-device: no account, no network. Bluetooth control of the machine is
local-only. The default drink everywhere is **Cappuccino**.

---

## What it does

| Area | Capability |
|---|---|
| **Dashboard** | Quick links into every workflow and tool. |
| **Fix My Coffee** | Pick what's wrong with the cup; a rules engine returns a single, explained adjustment (grinder / strength / volume / milk / temperature / beans). Applying it is logged to History. |
| **Expert Mode** | Same engine with full per-rule contribution breakdown. |
| **Shot Timer** | Stopwatch with pre-infusion marker; saves shots (dose / yield / ratio / rating), which feed the maintenance counter. |
| **Machine (Bluetooth)** | Scan, connect, brew a product, barista lock, read status/alerts and statistics over the Jura BLE protocol. |
| **Beans** | Bean library (seeded with 102 local + supermarket beans), recommended settings, roast-date freshness tracking. |
| **Recipes** | Saved dial-ins with drink/milk/bean, favourite and "last good" flags. |
| **Tasting Log** | SCA-style sensory wheel, body/acidity/sweetness/bitterness intensities, star rating. |
| **History** | Every applied adjustment, before→after, with an editable outcome and a last-good banner. |
| **Ratio Converter / Style Presets** | Brew-ratio maths and Australian café benchmarks. |
| **Water** | Mineral profiles (seeded) with hardness assessment and brewing hints. |
| **Maintenance** | Backflush/descale/etc., due by calendar days or shot count. |
| **Settings / Onboarding** | User mode, appearance, default drink; first-launch coach. |

---

## Versions

### macOS / iOS — Dialed In Coffee (`DialedInCoffee/`)
- **Stack:** SwiftUI, SwiftData, CoreBluetooth, Swift Concurrency.
- **Architecture:** SwiftUI views with `@Query`/`@Bindable`; light ViewModels for Fix My
  Coffee and the Shot Timer; pure-value rules engine (`RulesEngine/`) and BLE protocol
  (`Bluetooth/Protocol/`); persistence via 9 `@Model` types
  (`Persistence/ModelContainerFactory.swift`).
- **Build/test:** Xcode (`DialedInCoffeeTests/` XCTest suite).
- **Source of truth** for feature parity.

### Android — Cawfee (`android/`)
- **Stack:** Jetpack Compose (Material 3, adaptive nav), Room (v2), Hilt, DataStore,
  kotlinx-serialization, Kotlin Coroutines/Flow.
- **Modules:**
  - `:core` — platform-independent domain + rules engine (pure JVM, unit-tested).
  - `:protocol` — shared Jura BLE protocol (cipher, commands, parsers; pure JVM, unit-tested).
  - `:app` — Compose UI, Room persistence, Hilt DI, Android BLE stack.
- **Min/target SDK:** 26 / 35.
- **Build/test:** Gradle; CI in `.github/workflows/android.yml`.

---

## Building & testing

### Android
```bash
cd android
# Pure-JVM domain + protocol (no Android SDK required):
./gradlew :core:test :protocol:test
# Full app (requires Android SDK + access to Google's Maven repo):
./gradlew :app:assembleDebug :app:testDebugUnitTest
```
> Note: building `:app` needs the Android SDK **and** network access to
> `dl.google.com`/`maven.google.com` for the Android Gradle Plugin. In locked-down
> environments only `:core`/`:protocol` build locally; the full app builds on CI.

### macOS / iOS
Open the `DialedInCoffee` target in Xcode and build/run (⌘R) or test (⌘U).

### Continuous Integration
`.github/workflows/android.yml` runs on PRs / pushes to `main` / manual dispatch:
- **jvm-tests** — `:core` + `:protocol` unit tests.
- **build-and-test** — Lint, all unit tests, debug APK (uploaded).
- **release-artifacts** — release APK + AAB (on `main` / dispatch).
- **instrumented-tests** — Compose UI tests on an emulator (manual dispatch).

---

## Persistence & seeding
First launch seeds the bean catalogue (`android/app/src/main/assets/beans.json`, 102
beans), three water profiles and six maintenance tasks — mirroring
`DialedInCoffee/Persistence/SeedLoader.swift`. Android seeding runs in
`CoffeeRepository.seedIfNeeded()` (idempotent).

---

## Documentation
- `docs/JURA_E8_BLUETOOTH_SPECIFICATION.md` — the BLE protocol spec.
- `docs/audit/` — the forensic parity audit produced for this release:
  - `FEATURE_PARITY_MATRIX.md`, `MACOS_FEATURE_INVENTORY.md`,
    `MACOS_CODE_FLOW_ANALYSIS.md`, `ANDROID_FEATURE_INVENTORY.md`,
    `BLUETOOTH_FORENSIC_REPORT.md`, `UNFINISHED_WORK_REPORT.md`,
    `DEFAULT_COFFEE_AUDIT.md`, `IMPLEMENTATION_EVIDENCE.md`, `TEST_RESULTS.md`.
- `docs/ANDROID_PORT.md`, `docs/BLUETOOTH_ARCHITECTURE.md`, `docs/GITHUB_ACTIONS.md`.

## Privacy
Everything is local to the device. No analytics, no account, no internet use; Bluetooth is
used only to talk to your machine.
