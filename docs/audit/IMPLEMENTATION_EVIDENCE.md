# Implementation Evidence (Phase 10)

Every remediated feature with its source location and execution path. All paths relative to
the repo root.

## New Android source (created this pass)

| Feature | Files |
|---|---|
| Domain: sensory wheel | `android/core/.../domain/model/SensoryWheel.kt` |
| Domain: bean freshness | `android/core/.../domain/model/Freshness.kt` (+ test `core/.../FreshnessTest.kt`) |
| Room layer (7 entities + DAOs + converters) | `android/app/.../data/local/CawfeeDatabase.kt` |
| DI for all DAOs | `android/app/.../di/DatabaseModule.kt` |
| Entity↔domain mappers | `android/app/.../data/CoffeeMappers.kt` |
| Repository facade + bean-JSON seeding | `android/app/.../data/CoffeeRepository.kt` |
| Seed defaults (water + maintenance) | `android/app/.../data/SeedData.kt` |
| Bean catalogue asset (102 beans) | `android/app/src/main/assets/beans.json` |
| First-launch seeding trigger | `android/app/.../CawfeeApplication.kt` |
| Shared UI components | `android/app/.../ui/components/{Common,MachineSettingsEditor}.kt` |
| Beans | `android/app/.../ui/beans/{BeansViewModel,BeansScreen}.kt` |
| Recipes | `android/app/.../ui/recipes/{RecipesViewModel,RecipesScreen}.kt` |
| Tasting Log | `android/app/.../ui/tasting/{TastingViewModel,TastingScreen}.kt` |
| History | `android/app/.../ui/history/{HistoryViewModel,HistoryScreen}.kt` |
| Water | `android/app/.../ui/water/{WaterViewModel,WaterScreen}.kt` |
| Maintenance | `android/app/.../ui/maintenance/{MaintenanceViewModel,MaintenanceScreen}.kt` |
| Onboarding | `android/app/.../ui/onboarding/{OnboardingViewModel,OnboardingScreen}.kt` |
| Compose UI test (real component) | `android/app/src/androidTest/.../SectionCardUiTest.kt` |

## Modified Android source

| Feature | File | Change |
|---|---|---|
| Fix My Coffee | `ui/fix/FixMyCoffeeViewModel.kt` + `FixMyCoffeeScreen.kt` | persists `HistoryEntity`; feeds bean snapshot + recent history into the engine; loads saved default drink; live settings editor; drink/milk/bean pickers |
| Shot Timer | `ui/shots/ShotTimerViewModel.kt` + `ShotTimerScreen.kt` | persists `ShotEntity`; dose/yield/drink/rating inputs |
| Navigation | `navigation/CawfeeApp.kt` | 6 placeholder routes → real screens |
| First launch | `MainActivity.kt` | shows onboarding until completed |
| Preferences | `data/PreferencesRepository.kt` | default drink → Cappuccino |
| Unit test | `app/src/test/.../FixMyCoffeeViewModelTest.kt` | rewritten for injected VM (test dispatcher + mockk) |

## Modified macOS source

| Feature | File | Change |
|---|---|---|
| Default drink (Phase 9) | 12 files (see `DEFAULT_COFFEE_AUDIT.md`) | Flat White → Cappuccino in every default/fallback |
| Bluetooth completion (Phase 3) | `Bluetooth/Protocol/JuraCommands.swift` | added `0x11 2 Ristretti`, `0x12 2 Espressi`, `0x13 2 Coffees` |

## Execution path examples

**Fix My Coffee → history persistence**
`FixMyCoffeeScreen` (Apply&log) → `FixMyCoffeeViewModel.applyAndLog()` →
`Adjustment.apply()` on settings → `CoffeeRepository.upsertHistory(HistoryEntity)` →
`HistoryDao.upsert` (Room) → `HistoryScreen` observes `repo.history` → row appears.

**Bean freshness**
`BeansScreen` → `BeanEntity.freshness()` (`CoffeeMappers`) →
`FreshnessCalculator.assess(roastDateMillis, now)` (`:core`) → `Freshness.summary` rendered.

**Maintenance due-ness**
`ShotTimerViewModel.saveShot` → `ShotDao.insert` → `ShotDao.observeCount` →
`MaintenanceViewModel.shotCount` → `MaintenanceTaskEntity.isDue(shotCount)` → "due" chip.

**Seeding**
`CawfeeApplication.onCreate` → `CoffeeRepository.seedIfNeeded()` → reads
`assets/beans.json` via kotlinx-serialization + `SeedData` → DAOs `insertAll`.

## Verifiability caveat
`:core`/`:protocol` compile and their 53 unit tests pass locally (see `TEST_RESULTS.md`).
The `:app` module and macOS app compile only on CI / Xcode because this sandbox's network
policy blocks Google's Maven repository (no Android Gradle Plugin). The `:app` Kotlin was
written and statically reviewed for parity and correctness but not compiled here.
