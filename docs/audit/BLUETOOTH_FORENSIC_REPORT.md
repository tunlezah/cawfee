# Bluetooth Forensic Report

Scope: full teardown of the Jura BLE implementation on both platforms, traced against
`docs/JURA_E8_BLUETOOTH_SPECIFICATION.md`. macOS source of truth =
`DialedInCoffee/Bluetooth/`; Android = `android/protocol/` (pure-JVM, unit-tested) +
`android/app/.../bluetooth/` (Android BLE stack).

## Classes / files

| Concern | macOS | Android |
|---|---|---|
| GATT UUIDs + timing | `Protocol/JuraGatt.swift` | `protocol/.../protocol/JuraGatt.kt` |
| Obfuscation cipher | `Protocol/JuraCipher.swift` | `protocol/.../encryption/JuraCipher.kt` (+ `Hex.kt`) |
| Command builder | `Protocol/JuraCommands.swift` | `protocol/.../commands/JuraCommands.kt` |
| Parsers (adv/status/stats) | `Protocol/JuraParsers.swift` | `protocol/.../parser/*` |
| Machine catalogue | `JuraMachineCatalog` (in JuraCommands.swift) | `protocol/.../protocol/JuraMachineCatalog.kt` |
| Connection / scan / heartbeat | `CoreBluetooth/JuraBluetoothManager.swift` (CoreBluetooth) | `app/.../bluetooth/{JuraScanner,JuraGattConnection,JuraBleClient,JuraConnectionService}.kt` |

## Command inventory (trace: button → command → transmit → response → UI)

| Command | Spec § | Payload (plaintext → codec) | macOS | Android |
|---|---|---|---|---|
| Start Product | §8.1 | 18-byte frame, byte1=product code, settings at offsets, byte17=key, `encrypt` | `JuraCommands.startProduct` | `JuraCommands.startProduct` |
| Heartbeat / P-Mode | §8.2 | `00 7F 80`, `encrypt`, ≤9 s | `JuraCommands.heartbeat` | `JuraCommands.heartbeat` |
| Barista lock/unlock | §8.3 | `00 01` / `00 00`, **`encDecRaw`** (no key byte) | `JuraCommands.baristaLock` | `JuraCommands.baristaLock` |
| Statistics request | §8.4 | `<key> 00 <01|10> FF FF`, `encrypt` | `JuraCommands.statisticsRequest` | `JuraCommands.statisticsRequest` |

## Response inventory

| Response | Spec § | Parser | macOS | Android |
|---|---|---|---|---|
| Advertisement (key, modelId, serial, status) | §4.2 | `parseAdvertisement` | ✓ | ✓ |
| Machine status (MSB-first alert bitfield) | §9 | `parseStatus` | ✓ | ✓ |
| Statistics (3-byte counts) | §10 | `parseStatistics` + readiness check §8.4 | ✓ | ✓ |
| Product progress | — | progress parser | (via manager) | `ProgressParser` |

## E8 machine catalogue (model id 15057 / EF533)

Products (code → name): `0x01 Ristretto, 0x02 Espresso, 0x03 Coffee, 0x04 Cappuccino,
0x07 Latte Macchiato, 0x0A Milk Portion, 0x0D Hot Water, 0x11 2 Ristretti,
0x12 2 Espressi, 0x13 2 Coffees, 0x2E Flat White`. Setting offsets: strength=F3,
water=F4 (÷5), milk=F5 (÷5), temperature=F7, milk-break=F11. Alert bit map per §9.

### Discrepancy found and fixed (macOS Bluetooth completion, Phase 3)
The macOS catalogue was **missing** the three double drinks (`0x11/0x12/0x13`) that the
Android catalogue already defined. Fixed in
`DialedInCoffee/Bluetooth/Protocol/JuraCommands.swift` so the two catalogues are now
identical → full command parity.

## Specification coverage (Phase 8)

| Spec command/section | Specified | macOS | Android |
|---|---|---|---|
| §8.1 Start Product | yes | yes | yes |
| §8.2 Heartbeat | yes | yes | yes |
| §8.3 Barista lock | yes | yes | yes |
| §8.4 Statistics | yes | yes | yes |
| §9 Status bitfield | yes | yes | yes |
| §10 Statistics counts | yes | yes | yes |
| §4.2 Advertisement | yes | yes | yes |

## Unsupported / partial / dead / unreachable code
- **Unsupported commands:** none relative to the bundled E8 table.
- **Partially implemented:** none. Both platforms build, transmit and parse all four
  command families and three response families.
- **Dead / unreachable code:** none found. All `JuraCommands`/parser functions are
  reachable from `JuraBluetoothManager` (macOS) and `JuraBleClient`/`MachineViewModel`
  (Android). The Android stack additionally implements reconnect + runtime permission
  handling (`BluetoothPermissions`) that macOS does not need.

## Verification
The protocol is exercised by pure-JVM unit tests
(`android/protocol/src/test/.../JuraCipherTest`, `JuraCommandsTest`, `ParserTest`) and the
Swift `DialedInCoffeeTests/JuraProtocolTests.swift`. Both pass.
