# Cawfee — Android Setup

## 1. Prerequisites

- **Android Studio** Ladybug (2024.2) or newer.
- **JDK 17** (bundled with recent Android Studio).
- **Android SDK** with platform 35 (Android 15) and build-tools; the project targets
  `compileSdk = 35`, `minSdk = 26`, `targetSdk = 35`.

## 2. Open the project

1. Open Android Studio → **Open** → select the `android/` directory (not the repo root).
2. Let Gradle sync. The wrapper pins Gradle 8.14.3; AGP 8.7.3; Kotlin 2.0.21.
3. If prompted, create `android/local.properties` with your SDK path:
   ```
   sdk.dir=/Users/you/Library/Android/sdk
   ```
   (Android Studio writes this automatically. It is git-ignored.)

> The `:app` module is included only when an SDK is detected. From the command line you
> can run `:core`/`:protocol` tests with no SDK at all.

## 3. Run on a device or emulator

### Emulator
1. **Device Manager** → create a virtual device:
   - *Phone (Android 14)*: Pixel 8, API 34.
   - *Tablet (Android 13)*: Pixel Tablet, API 33 — verify the landscape / NavigationRail
     adaptive layout.
2. Select the `app` run configuration → **Run**.

> The emulator has no real Bluetooth radio, so the **Machine** screen will scan but find
> nothing. Use a physical device with a Jura Smart Connect dongle for end-to-end BLE.

### Physical device (for Bluetooth)
1. Enable **Developer options** → **USB debugging**.
2. Run from Android Studio, or sideload a CI APK:
   ```
   adb install -r cawfee-debug.apk
   ```
3. On first open of **Machine**, grant the Bluetooth permission prompt.

## 4. Permissions

| Android | Permissions | Notes |
|---|---|---|
| 12+ (API 31+) | `BLUETOOTH_SCAN` (`neverForLocation`), `BLUETOOTH_CONNECT` | Requested at runtime from the Machine screen. |
| ≤ 11 | `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_FINE_LOCATION` | Location services must be **on** to scan. |
| All | `FOREGROUND_SERVICE` (+ `…CONNECTED_DEVICE` on 14+), `POST_NOTIFICATIONS` | Keeps the ≤9s heartbeat alive in the background. |

## 5. Common commands

```bash
cd android
./gradlew :core:test :protocol:test     # fast pure-JVM tests (no SDK)
./gradlew testDebugUnitTest             # all unit tests
./gradlew :app:assembleDebug            # build sideloadable APK
./gradlew :app:installDebug             # build + install on connected device
./gradlew :app:connectedDebugAndroidTest  # Compose UI tests on device/emulator
./gradlew :app:lintDebug                # Android Lint
```

## 6. Troubleshooting

- **"SDK location not found"** — set `sdk.dir` in `android/local.properties`, or define
  `ANDROID_HOME`.
- **Scan finds nothing on a real device** — ensure Bluetooth is on, permission granted,
  and (pre-12) location services enabled. The dongle advertises as `TT214H BlueFrog`.
- **"Works only on the second connect"** — expected first-attempt flakiness; the client
  retries with backoff and keeps the link warm (spec §7.4).
