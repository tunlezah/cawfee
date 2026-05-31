# Test Results (Phase 12)

## Locally executed (this environment — pure-JVM, no Android SDK / Google Maven)

Command: `./gradlew :core:test :protocol:test --rerun-tasks`

| Module | Tests | Passed | Failed | Errors |
|---|---|---|---|---|
| `:core` (domain + rules engine + freshness + cappuccino default) | 30 | 30 | 0 | 0 |
| `:protocol` (Jura cipher, commands, parsers) | 23 | 23 | 0 | 0 |
| **Total** | **53** | **53** | **0** | **0** |

`:core` includes the new `FreshnessTest` (freshness windows + Cappuccino-default
invariant). All green.

## Requires CI (GitHub Actions `android.yml`) or a host with the Android SDK + Google Maven

These cannot run in the current sandbox because the network policy blocks
`dl.google.com` / `maven.google.com` (HTTP 403), so the Android Gradle Plugin cannot be
resolved and the `:app` module cannot be configured locally. They run on CI:

| Suite | Where | Notes |
|---|---|---|
| `:app` unit tests (`testDebugUnitTest`) | `build-and-test` job | incl. `FixMyCoffeeViewModelTest` (rewritten for the injected VM with a test dispatcher + mockk) |
| Android Lint (`:app:lintDebug`) | `build-and-test` job | advisory (abortOnError=false) |
| Debug APK (`:app:assembleDebug`) | `build-and-test` job | uploaded artifact |
| Release APK + AAB | `release-artifacts` job | on main / manual dispatch |
| Instrumented Compose UI tests (`connectedDebugAndroidTest`) | `instrumented-tests` job (manual dispatch) | incl. `SectionCardUiTest` |

## macOS (Xcode) — not runnable in this Linux sandbox
`DialedInCoffeeTests/*` (XCTest) — domain, rules, protocol, SwiftData model tests. The
Swift edits in this pass are value substitutions (Flat White → Cappuccino) and three added
BLE products; no test assertions depend on product counts
(`JuraProtocolTests.swift` asserts specific statistics indices only).

## Honesty note
The `:core`/`:protocol` results above were executed and verified here. The `:app` and
macOS results depend on CI / Xcode, which this sandbox cannot reach. The `:app` Kotlin was
written to compile but has not been compiled locally for the reason above.
