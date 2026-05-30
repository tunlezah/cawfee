# Cawfee — GitHub Actions

The workflow lives at [`.github/workflows/android.yml`](../.github/workflows/android.yml).

## Triggers

- **Pull request** — fast feedback (lint, tests, debug build).
- **Push to `main`** — everything above **plus** release APK + AAB artifacts.
- **Manual** (`workflow_dispatch`) — also runs the emulator-based instrumented tests.

All Gradle steps use `working-directory: android`.

## Jobs

### 1. `jvm-tests` — Pure-JVM tests (`:core`, `:protocol`)
Runs `./gradlew :core:test :protocol:test`. No Android SDK is required (the `:app` module
is auto-excluded when no SDK is present), so this is the fastest signal and covers the BLE
protocol (cipher/commands/parsers vectors) and the ported coffee RulesEngine. Test reports
are uploaded as the `jvm-test-reports` artifact.

### 2. `build-and-test` — Lint, unit tests & debug APK
Sets up JDK 17 + the Android SDK, then runs:
- `:app:lintDebug` (Android Lint),
- `testDebugUnitTest` (all module unit tests),
- `:app:assembleDebug`.

Uploads:
- **`cawfee-debug-apk`** — the signed-with-debug-key APK, directly **sideloadable** via
  `adb install -r`.
- **`lint-results`** — the HTML lint report.

### 3. `release-artifacts` — Release APK + AAB (main / manual only)
Depends on the two jobs above. Runs `:app:assembleRelease :app:bundleRelease` and uploads:
- **`cawfee-release-apk`** — release APK,
- **`cawfee-release-aab`** — Android App Bundle for Play distribution.

> The release build is unsigned (no signing keys are committed). For a Play upload, add a
> keystore via repository secrets and a `signingConfig`. For sideload testing, prefer the
> debug APK from job 2.

### 4. `instrumented-tests` — Emulator (manual only)
Uses `reactivecircus/android-emulator-runner` (API 34, x86_64, KVM-accelerated) to run
`:app:connectedDebugAndroidTest` (the Compose UI tests). Gated behind `workflow_dispatch`
because emulator boots are slow/flaky in CI.

## Caching

`gradle/actions/setup-gradle@v4` caches the Gradle user home and build cache keyed on the
Gradle files, so incremental runs are fast.

## Getting the APK

After a run: **Actions → the run → Artifacts → `cawfee-debug-apk`**. Unzip and:

```bash
adb install -r app-debug.apk
```
