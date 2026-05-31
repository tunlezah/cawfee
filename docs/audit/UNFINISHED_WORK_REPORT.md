# Unfinished Work Report (Phase 6)

Search for: `TODO, FIXME, XXX, HACK, TEMP, COMING SOON, PLACEHOLDER, NOT IMPLEMENTED,
STUB, MOCK, FAKE, DUMMY`, plus disabled buttons, unreachable navigation, empty screens,
hardcoded data, fake BLE responses, fake/mock repositories used in production.

## Found BEFORE remediation

| Item | Location | Type |
|---|---|---|
| `PlaceholderScreen("… — coming soon")` | `android/.../ui/misc/PlaceholderScreen.kt` | Coming-soon stub |
| Beans / Recipes / Tasting / History / Water / Maintenance routed to `PlaceholderScreen` | `navigation/CawfeeApp.kt` | Empty screens / unreachable real features |
| Room DB with only `ShotEntity` (other models "extend the pattern" per docs) | `data/local/CawfeeDatabase.kt` | Missing persistence |
| Fix My Coffee never persisted history, ignored bean + recent history | `ui/fix/FixMyCoffeeViewModel.kt` | Partial implementation |
| Shot Timer never saved shots | `ui/shots/ShotTimerViewModel.kt` | Partial implementation |
| No onboarding screen (pref existed, UI did not) | — | Missing screen |
| macOS catalogue missing `0x11/0x12/0x13` double drinks | `Bluetooth/Protocol/JuraCommands.swift` | Incomplete BLE table |
| Default drink = Flat White (not Cappuccino) | many (see DEFAULT_COFFEE_AUDIT.md) | Wrong default |
| `PlaceholderScreenTest` only tested the stub | `androidTest/.../PlaceholderScreenTest.kt` | Test of placeholder |

## Resolution
- All 6 placeholder routes now point to real, Room-backed Compose screens; `PlaceholderScreen.kt` deleted.
- Room DB expanded to 7 entities + DAOs + type converters + first-launch seeding.
- Fix My Coffee persists `HistoryEntity`, feeds the selected bean snapshot and recent
  history into the rules engine, loads the saved default drink, and edits live settings.
- Shot Timer persists `ShotEntity` (drives the Maintenance shot counter).
- Android onboarding added and wired into `MainActivity`.
- macOS BLE catalogue completed (double drinks added).
- Cappuccino is the default everywhere.
- Placeholder test replaced with `SectionCardUiTest` (a real component).

## Found AFTER remediation
`grep -rniE "TODO|FIXME|XXX|HACK|TEMP|COMING SOON|PLACEHOLDER|NOT IMPLEMENTED|STUB|MOCK|FAKE|DUMMY"`
over `DialedInCoffee/` and `android/{app,core,protocol}/src`:

- **Zero** genuine markers remain.
- The only literal "placeholder" string is a protocol comment in
  `protocol/.../commands/JuraCommands.kt` ("byte 0 is left as the key **placeholder**")
  describing a real BLE byte offset — not incomplete work.
- `mockk` appears only in test source (`testImplementation`), never in production.
- No disabled buttons, no unreachable destinations, no empty screens, no fake repositories
  or fabricated BLE responses in production code.
