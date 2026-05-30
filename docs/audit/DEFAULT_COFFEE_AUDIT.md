# Default Coffee Audit (Phase 9) — Cappuccino everywhere

Business rule: the default coffee selection SHALL be **Cappuccino** on every platform and
every layer (settings, startup, onboarding, preference defaults, DB defaults, ViewModel
defaults, state defaults, decode fallbacks).

## Findings (before)
The default was **Flat White** in many places. All defaults audited; the ones that drive a
user-visible default selection or a decode fallback were changed to Cappuccino. Enum
*definitions*, rule conditions, the `defaults(for:)` mapping, `isMilkBased`/`symbolName`
switches, and preview sample data were left intact (they are not "the default selection").

## macOS changes

| File | Location | Before → After |
|---|---|---|
| `Models/UserPreferences.swift` | init param | `defaultDrink = .flatWhite` → `.cappuccino` |
| `Models/UserPreferences.swift` | getter fallback | `?? .flatWhite` → `?? .cappuccino` |
| `Presentation/FixMyCoffee/FixMyCoffeeViewModel.swift` | initial state | `drink = .flatWhite`, `settings = .defaultFlatWhite` → `.cappuccino`, `.defaultCappuccino` |
| `Presentation/Onboarding/OnboardingView.swift` | initial state | `drink = .flatWhite` → `.cappuccino` |
| `Presentation/Shots/ShotTimerView.swift` | initial state | `drink = .flatWhite` → `.cappuccino` |
| `Presentation/Recipes/RecipeEditorView.swift` | new-recipe defaults | `?? .flatWhite`, `?? .defaultFlatWhite` → cappuccino variants |
| `Presentation/Tasting/TastingNoteEditorView.swift` | new-note default | `?? .flatWhite` → `?? .cappuccino` |
| `Models/Shot.swift` | init default + getter fallback | `.flatWhite` → `.cappuccino` |
| `Models/TastingNote.swift` | init default + getter fallback | `.flatWhite` → `.cappuccino` |
| `Models/Recipe.swift` | getter fallback | `?? .flatWhite` → `?? .cappuccino` |
| `Models/AdjustmentHistoryEntry.swift` | getter fallback | `?? .flatWhite` → `?? .cappuccino` |
| `Models/SymptomLog.swift` | getter fallback | `?? .flatWhite` → `?? .cappuccino` |

## Android changes

| File | Location | Before → After |
|---|---|---|
| `data/PreferencesRepository.kt` | `UserPrefs.defaultDrink` default | `FLAT_WHITE` → `CAPPUCCINO` |
| `data/PreferencesRepository.kt` | decode fallback in `prefs` flow | `?: FLAT_WHITE` → `?: CAPPUCCINO` |
| `ui/fix/FixMyCoffeeViewModel.kt` | `FixUiState` defaults | `FLAT_WHITE` / `defaultFlatWhite` → `CAPPUCCINO` / `defaultCappuccino`; also loads the user's saved default drink on init |
| `data/CoffeeMappers.kt` | `drinkOf()` decode fallback | `?: CAPPUCCINO` |
| `ui/recipes/RecipesScreen.kt` | new-recipe defaults | `CAPPUCCINO` / `defaultCappuccino` |
| `ui/tasting/TastingScreen.kt` | new-note default | `CAPPUCCINO` |
| `ui/shots/ShotTimerScreen.kt` | initial drink | `CAPPUCCINO` |
| `ui/onboarding/OnboardingScreen.kt` | initial drink | `CAPPUCCINO` |

## Intentionally NOT changed (not "the default selection")
- `DrinkType` enum case order / definitions (both platforms).
- `MachineSettings.defaults(for:)` mapping — each drink maps to its own preset; Cappuccino
  maps to `defaultCappuccino`.
- `isMilkBased` / `symbolName` switches and `AustralianStyleBias.appliesTo` rule logic.
- `RuleSet` condition `.drinkIs(.flatWhite)` (a rule, not a default).
- `PreviewData` sample recipes (design-time only, not a runtime default).

## Verification
`android/core` unit test `FreshnessTest.cappuccino is the default drink and uses the
cappuccino settings` asserts `MachineSettings.defaults(CAPPUCCINO) == defaultCappuccino`
(milkSeconds = 22). `grep -rn "flatWhite" DialedInCoffee` and
`grep -rn "FLAT_WHITE" android/app android/core` confirm no remaining *default* uses.
