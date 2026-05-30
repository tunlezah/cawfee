# Cawfee — Bluetooth Architecture

How Cawfee talks to a Jura E8 over Bluetooth Low Energy, on **both** Android and
macOS/iOS, from one shared protocol design. The authoritative wire spec is
[`JURA_E8_BLUETOOTH_SPECIFICATION.md`](JURA_E8_BLUETOOTH_SPECIFICATION.md); this document
explains the *implementation*.

## 1. One protocol, two platforms

The platform-independent protocol is implemented twice, line-for-line, and pinned to the
same test vectors so the two stay in lock-step:

| Concern | Android (`:protocol`, Kotlin/JVM) | macOS/iOS (Swift) |
|---|---|---|
| Obfuscation codec | `encryption/JuraCipher.kt` | `Bluetooth/Protocol/JuraCipher.swift` |
| GATT UUIDs & timing | `protocol/JuraGatt.kt` | `Bluetooth/Protocol/JuraGatt.swift` |
| Command builders | `commands/JuraCommands.kt` | `Bluetooth/Protocol/JuraCommands.swift` |
| Parsers (advert/status/stats) | `parser/*` | `Bluetooth/Protocol/JuraParsers.swift` |
| Machine catalog (E8/EF533) | `protocol/JuraMachineCatalog.kt` | `JuraMachineCatalog` (in `JuraCommands.swift`) |

The **platform-specific** layer is only the radio plumbing:

| Concern | Android | macOS/iOS |
|---|---|---|
| Scanning | `bluetooth/scanner/JuraScanner.kt` (`BluetoothLeScanner`) | `JuraBluetoothManager` (`CBCentralManager`) |
| Connection / GATT | `bluetooth/connection/JuraGattConnection.kt` (`BluetoothGatt` + serialized op queue) | `JuraBluetoothManager` (`CBPeripheral` delegate) |
| Orchestration | `bluetooth/JuraBleClient.kt` | `JuraBluetoothManager` |

## 2. The obfuscation codec ("encryption")

A key-seeded 4-bit nibble-substitution over two fixed S-boxes (`NUMB1`/`NUMB2`). It is
**involutive** (same function encodes and decodes) and is *not* cryptography — the key is
broadcast in cleartext in the advertisement. Key facts the code relies on:

- `encrypt(data, key)` overwrites **byte 0 with the key**, then runs `encDec`.
- On a valid decode, **byte 0 == key** — used as the validity check and the brute-force
  oracle.
- The **Barista lock** is the one exception: written via `encDecRaw` (no byte-0=key step).

Verified vector (executed in tests on both platforms):

```
encrypt(00 7F 80, key=0x2A) == 77 65 6D     # the heartbeat
encDec(2a280006120000010001090000000000062a, 0x2A) round-trips the brew frame
```

## 3. GATT map

Base UUID `5a40XXXX-ab2e-2548-c435-08c300000710`.

| Name | UUID prefix | Service | Props | Obfuscated |
|---|---|---|---|---|
| Machine Status | `5a401524` | control | Read | yes |
| Start Product | `5a401525` | control | Write | yes |
| Product Progress | `5a401527` | control | Read/Notify | yes |
| P-Mode (heartbeat) | `5a401529` | control | Write | yes |
| Barista lock | `5a401530` | control | Write | yes (raw) |
| Statistics cmd / data | `5a401533` / `5a401534` | control | Write / Read | yes |
| About Machine | `5a401531` | control | Read | no (plaintext) |

Services: control `5a401523…`, UART `5a401623…`. **Always discover by UUID** — ATT handles
are not stable across firmware.

## 4. Packet formats

### Advertisement (manufacturer data, company id `0x00AB`)
Little-endian. `byte0 = key`, `bytes4–5 = model id (LE16)` (E8 = `15057`), `byte15 = status
bits`. Parsed by `AdvertisementParser` / `JuraParsers.parseAdvertisement`.

### Start Product (18-byte frame → `5a401525`)
```
offset: 0    1     3        4            5     7      11        17
field:  key  code  strength water(÷5)    milk  temp   milkBreak key
```
Byte 1 = product `@Code`; settings are placed at their model-defined offsets with the
on-wire byte = `value / step` (water step = 5, i.e. ml÷5). Bytes 0/9/16 are framing and
must be present (the full 18 bytes are always sent). Byte 0 is set to the key on encode.

### Heartbeat (→ `5a401529`)
`encrypt(00 7F 80, key)`; send at least every **9 s** or the machine drops the link at ~20 s.

### Statistics (`5a401533` cmd / `5a401534` data)
Write `<key> 00 <01|10> FF FF`, wait ~1200 ms, poll the cmd characteristic until it is no
longer "busy" (`isReady`), then read + decode the data as **3-byte big-endian counters**
(`counts[0]` = total; `counts[code]` = per-product).

### Machine status (`5a401524`)
Decode, then walk bits **MSB-first from byte 1**; each set bit is an alert (per-model
names). Blocking alerts (water/beans/tray/grounds/outlet…) gate brewing; bit 13
("coffee ready"), 33 ("descale"), 34 ("cleaning"), 32 ("filter") are informational.

## 5. Connection lifecycle

```
scan(active) → match company 0x00AB → parse key+model
   → GATT connect (retry w/ backoff) → discover services → request MTU 247
   → enable Product Progress notifications
   → ACTIVE: write encrypted heartbeat ≤9s; read status; brew/lock/stats on demand
   → on drop: app-layer reconnect (re-scan/connect/discover/resume heartbeat)
```

Android-specific correctness rules honored by `JuraGattConnection`:
- **All GATT operations are serialized** (one outstanding op via a `Mutex` +
  `CompletableDeferred`) — the #1 Android BLE pitfall.
- `requestMtu(247)` after connect; enabling notifications writes the CCCD
  `ENABLE_NOTIFICATION_VALUE` **and** calls `setCharacteristicNotification(true)`.
- Both the API-33 value-carrying callbacks and the pre-33 deprecated callbacks are handled.

## 6. Permissions & security

- Android 12+: `BLUETOOTH_SCAN` (with `neverForLocation`) + `BLUETOOTH_CONNECT`, requested
  at runtime; pre-12 falls back to `BLUETOOTH`/`BLUETOOTH_ADMIN` + `ACCESS_FINE_LOCATION`.
- macOS/iOS: `NSBluetoothAlwaysUsageDescription` (mandatory) + the macOS sandbox
  `com.apple.security.device.bluetooth` entitlement.
- The link has **no pairing/bonding/encryption** and the key is public, so the app treats
  all received data as untrusted and only brews on explicit user intent. See spec §15.

## 7. Extending to new commands / machines

- New command: add a builder to `JuraCommands` (both platforms) and call it from the
  client. Pure functions → unit-testable in isolation.
- New machine model: add a `MachineModel`/`JuraMachineModel` to the catalog (product table
  + alert-bit map). No change to the BLE or UI layers.
