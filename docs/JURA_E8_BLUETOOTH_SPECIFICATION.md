# Jura E8 — Unofficial Bluetooth Protocol Specification & Reverse-Engineering Report

**Document type:** Implementation-grade protocol specification
**Subject:** Jura E8 (and the wider Jura *Smart Connect* / J.O.E. ecosystem) Bluetooth Low Energy interface
**Status:** Unofficial. Compiled from reverse engineering of open-source implementations, decompiled app artifacts, packet-capture write-ups, and vendor documentation.
**Audience:** Engineers building a cross-platform (Windows / macOS / Linux / iOS / Android) Jura BLE integration library.
**Last updated:** 2026-05-29

---

## 0. How to read this document

### 0.1 Confidence labels
Every non-trivial claim carries one of:

- **[C] Confirmed** — verbatim from source code that was fetched and read, *or* cross-confirmed across ≥2 independent implementations, *or* directly executed/round-tripped against a known test vector.
- **[I] Inferred** — strongly implied by confirmed code/data, logically derived, but not directly observed on a wire.
- **[S] Speculative** — plausible community claim or single-source assertion not independently verified here.

### 0.2 Primary sources used (full URLs in §22)
1. **AlexxIT/Jura** — Home Assistant component (Python, BLE). Source files fetched directly: `core/encryption.py`, `core/client.py`, `core/device.py`, `tests/test_misc.py`. **Cipher executed and verified** against its own test vectors.
2. **Jutta-Proto/protocol-bt-cpp** — C++ BLE library; the most complete protocol write-up. `ByteEncDecoder.cpp` read verbatim.
3. **Jutta-Proto/protocol-cpp** — C++ legacy serial library.
4. **franfrancisco9/Jura-Python-BT** — Python BLE port with `uuids_handles.json`, `products.json`, `alerts.json`.
5. **COM8/esp32-jura**, **hn/jura-coffee-machine**, **Q42/coffeehack**, **PromyLOPh/juramote**, **oliverk71 wiki** — serial-layer references.
6. **lunarius.fe80.eu "Joe the friendly coffee maker"** — APK (`ch.toptronic.joe`) JADX + btsnoop/Wireshark write-up.
7. **Pen Test Partners**, **McAfee Labs** — security analyses.

> **Triangulation note.** The BLE obfuscation routine is byte-identical across three independent codebases (AlexxIT Python, Jutta C++, franfrancisco9 Python) and was independently extracted from the official APK. The legacy 4-byte UART encoding is identical across four codebases (Q42, hn, COM8, franfrancisco9). These are the two highest-confidence findings in the document.

---

## 1. Executive summary

The Jura E8 has **no native Bluetooth**. Connectivity is provided by an optional plug-in dongle, the **JURA Smart Connect** (article no. 72167), internally branded **"BlueFrog"**, which bridges the machine's internal **5 V TTL UART service port** to **Bluetooth Low Energy**. The dongle advertises under the BLE name **`TT214H BlueFrog`**.

The official app is **J.O.E. (Jura Operating Experience)** — Android package `ch.toptronic.joe`, iOS App Store id `1364370646`, published by JURA Elektroapparate AG, built on the "TopTronic" platform. Every third-party client (Home Assistant, ESP32, Python) speaks the same protocol.

Key technical facts:

- **Custom GATT.** Two vendor services under base UUID `5a40XXXX-ab2e-2548-c435-08c300000710`: a **default/control service** (`…1523…`) and a **UART pass-through service** (`…1623…`). **[C]**
- **"Encryption" is actually obfuscation.** Payloads on most characteristics are scrambled with a **key-seeded 4-bit nibble-substitution cipher** using two fixed 16-entry S-boxes. The **key is a single byte broadcast in cleartext** in the BLE advertisement. The cipher is involutive (same function encrypts and decrypts). **[C]**
- **No BLE pairing, no bonding, no link-layer security.** Any device in range (~3 m) can connect when no other client is connected. The only access control is an **optional, default-off application-level PIN**. **[C]**
- **Heartbeat required.** The machine drops the link after **~20 s** of inactivity; clients must write an encoded `00 7F 80` keepalive to the *P-Mode* characteristic at least every **~9 s**. **[C]**
- **Per-model definition files.** Product codes, setting byte-offsets, alert-bit meanings, and statistics indices are described by **per-machine XML** bundled in the J.O.E. APK and refreshed from Jura's cloud. **The Jura E8 maps to machine type `EF533`** (`documents/xml/EF533/1.0.xml`); its model id (advertisement bytes 4–5) is `15057` (`0x3AD1`). **[C]**
- **Security posture.** Trivially forgeable/replayable; researchers demonstrated brewing, strength changes, aborting brews, and bean/water waste by any nearby attacker. Physical-hazard exploitation is blocked by the machine's own hardware-ready interlocks. **[C]**

A correct E8 BLE client therefore needs: (1) active scanning + manufacturer-data parsing to get the key and model, (2) the nibble-shuffle codec, (3) the GATT characteristic map, (4) a heartbeat loop, (5) the per-model XML to build commands and decode status/stats.

---

## 2. Architecture overview

```
 ┌──────────────────────────────────────────────────────────────────────┐
 │                         Client application                             │
 │  (Win/WinRT · macOS/iOS CoreBluetooth · Android BLE · Linux BlueZ)     │
 │                                                                        │
 │   ┌───────────────┐  ┌──────────────┐  ┌───────────────────────────┐  │
 │   │ Scan / advert │  │ Nibble-shuffle│ │ Machine XML (EF533 for E8) │  │
 │   │ parser (key,  │  │ codec (encdec)│ │ products/alerts/stats map  │  │
 │   │ model id)     │  └──────────────┘  └───────────────────────────┘  │
 │   └───────────────┘  ┌──────────────┐  ┌───────────────────────────┐  │
 │                      │ GATT client  │  │ Heartbeat loop (≤9 s)      │  │
 │                      └──────┬───────┘  └───────────────────────────┘  │
 └─────────────────────────────┼─────────────────────────────────────────┘
                               │  BLE (GATT, ATT MTU 23+; obfuscated payloads)
                               ▼
 ┌──────────────────────────────────────────────────────────────────────┐
 │              JURA Smart Connect "BlueFrog" (TT214H), art. 72167        │
 │   BLE peripheral  ◀───────────────▶  5 V TTL UART bridge               │
 │   advertises key + model in manufacturer data (company id 0x00AB)      │
 └─────────────────────────────┬─────────────────────────────────────────┘
                               │  9600 8N1, 4-bytes-per-logical-byte encoding, CRLF
                               ▼
 ┌──────────────────────────────────────────────────────────────────────┐
 │                  Jura E8 mainboard (TopTronic / "EF533")               │
 │     EEPROM (counters, config) · sensors · brew unit · interlocks       │
 └──────────────────────────────────────────────────────────────────────┘
```

**Two protocol layers, two ciphers — do not confuse them:**

| Layer | Transport | Obfuscation | When used |
|-------|-----------|-------------|-----------|
| BLE control/UART services | GATT read/write | nibble-shuffle `encdec` (§7) | What a BLE client uses |
| Legacy service UART | 9600 8N1 serial | 1-byte→4-byte bit-distribution (§13) | Inside the dongle ↔ mainboard; also direct-wire DIY |

The BLE payloads are *logically* the same family of commands the serial port historically used, but BLE does **not** apply the 4-byte serial encoding — the dongle translates. **[I]**

> **Cloud:** The J.O.E. app uses the internet only for (a) machine-definition XML updates, (b) OTA dongle firmware, and (c) account-tied recipe/favourite sync. **No cloud is required for local BLE control** — third-party clients operate fully offline once they have the model XML. **[C]**

---

## 3. The Smart Connect / BlueFrog dongle

| Property | Value | Conf. |
|---|---|---|
| Marketing name | JURA Smart Connect | C |
| Article number | 72167 | C |
| Internal brand | BlueFrog | C |
| Module / advertised name | `TT214H BlueFrog` | C |
| Transport | BLE (4.0+) ↔ machine UART service port | C |
| Range | ~3 m | C |
| Concurrency | One client at a time | C |
| Pairing | None (no PIN at BLE layer, no bonding) | C |
| Firmware | OTA-updatable via J.O.E. (needs internet); machine powers off to apply | C |
| Versioning | major/minor bytes in advert; ASCII version via *About Machine* | C |

**Single-connection limit** is the de-facto access control: while one client holds the GATT link, others cannot connect. **[C]** This also means a stuck/abandoned connection blocks everyone until it times out (~20 s idle, §10).

---

## 4. BLE advertising & manufacturer data

### 4.1 Discovery
- Scan **actively** (active scan required — passive-only proxies miss the manufacturer data). **[C]**
- Match on advertised name `TT214H BlueFrog` **and/or** presence of manufacturer data under **company identifier `0x00AB` (171 decimal)**. **[C]**
- Do **not** rely on a fixed MAC: iOS/macOS never expose it; identify by service UUID / name / manufacturer data instead. **[C]**

### 4.2 Manufacturer-data layout (company id `0x00AB`)
Little-endian. Total observed ~27 bytes (+ optional ASCII tail). **[C for 0–15; I/S for tail offsets]**

| Offset | Size | Field | Notes |
|---|---|---|---|
| 0 | 1 | **`key`** | **Obfuscation key** for the nibble-shuffle codec. Often `0x2A`. **[C]** |
| 1 | 1 | `bfMajVer` | BlueFrog firmware major |
| 2 | 1 | `bfMinVer` | BlueFrog firmware minor |
| 3 | 1 | — | unused |
| 4–5 | 2 | **`articleNumber` / model id (LE16)** | Machine type lookup. **E8 = `15057` (0x3AD1)**. `0` ⇒ invalid/empty. **[C]** |
| 6–7 | 2 | `machineNumber` (LE16) | |
| 8–9 | 2 | `serialNumber` (LE16) | |
| 10–11 | 2 | `machineProdDate` | packed: `year=((v&0xFE00)>>9)+1990`, `month=(v&0x01E0)>>5`, `day=v&0x1F` |
| 12–13 | 2 | `machineProdDateUCHI` | same packing (steam unit) |
| 14 | 1 | — | unused |
| 15 | 1 | `statusBits` | feature flags: bit4 incasso, bit6 master-PIN present, bit7 reset |
| 27–34 | 8 | `bfVerStr` (ASCII) | optional |
| 35–51 | 17 | `coffeeMachineVerStr` (ASCII) | optional |
| 51–54 | 4 | `lastConnectedTabletID` (LE32) | optional |

```python
# Extract key + model (AlexxIT-equivalent)
adv = manufacturer_data[0x00AB]            # raw bytes
key = adv[0]
model_id = int.from_bytes(adv[4:6], "little")
if model_id == 0:
    raise EmptyModel()
```

> **Security implication:** the decryption key is in the advertisement, before any connection — see §16.

---

## 5. GATT services & characteristics

**Base UUID:** `5a40XXXX-ab2e-2548-c435-08c300000710`
**Default/control service:** `5a401523-ab2e-2548-c435-08c300000710` **[C]**
**UART pass-through service:** `5a401623-ab2e-2548-c435-08c300000710` **[C]**

| Name | UUID (`…-ab2e-2548-c435-08c300000710`) | Svc | ATT handle¹ | Obfusc.² | Props | Conf. |
|---|---|---|---|---|---|---|
| About Machine | `5a401531` | Default | — | **No (plaintext)** | Read | C |
| Machine Status | `5a401524` | Default | 0x000b | Yes | Read | C |
| Start Product | `5a401525` | Default | 0x000e | Yes | Write | C |
| Product Progress | `5a401527` | Default | 0x001a | Yes | Read/Notify | C |
| Update Product Statistics | `5a401528` | Default | — | ? | ? | I |
| P-Mode (heartbeat write) | `5a401529` | Default | 0x0011 | Yes | Write | C |
| Barista Mode (lock) | `5a401530` | Default | 0x0017 | Yes³ | Write | C |
| Statistics Command | `5a401533` | Default | 0x0026 | Yes | Write/Read | C |
| Statistics Data | `5a401534` | Default | 0x0029 | Yes | Read | C |
| P-Mode Read | `5a401538` | Default | 0x0032 | ? | Read | I |
| UART RX | `5a401624` | UART | 0x0036 | Yes | Write/Notify | I⁴ |
| UART TX | `5a401625` | UART | 0x0039 | Yes | Read/Notify | I⁴ |

¹ Handles from franfrancisco9 `uuids_handles.json`; useful for `gatttool`/`btgatt-client`. **Handles are not guaranteed stable across firmware — always discover by UUID.**
² "Obfusc." = payload runs through the nibble-shuffle codec (§7).
³ **Exception:** Barista lock/unlock writes do **not** overwrite byte 0 with the key (Jutta). **[C]**
⁴ franfrancisco9 swaps the TX/RX labels vs Jutta (`5a401624` vs `5a401625`). Treat the two UART UUIDs as a write/notify pair and verify direction on-target. **[C conflict]**

Minimal viable client uses five: `5a401524` (status), `5a401525` (start), `5a401529` (heartbeat), `5a401533`/`5a401534` (stats). **[C]**

---

## 6. The obfuscation codec ("encryption")

### 6.1 What it is
A deterministic, **key-seeded per-nibble substitution** over two fixed 16-entry S-boxes, with a running nibble counter mixing in position dependence. **It is not cryptography** — no nonce, no session key, no integrity tag. It is **involutive for a fixed key** (the same function both encodes and decodes), which is why key recovery works by checking that decoded byte 0 equals the key. **[C]**

### 6.2 Constants — identical across all implementations **[C]**
```python
NUMB1 = [14, 4, 3, 2, 1, 13, 8, 11, 6, 15, 12, 7, 10, 5, 0, 9]
NUMB2 = [10, 6, 13, 12, 14, 11, 1,  9, 15, 7,  0, 5,  3, 2, 4, 8]
```

### 6.3 Reference algorithm (verbatim, AlexxIT `encryption.py`) **[C]**
```python
def mod256(i: int):
    return i % 256

def shuffle(src: int, cnt: int, key1: int, key2: int) -> int:
    i1 = mod256(cnt >> 4)
    i2 = NUMB1[mod256(src + cnt + key1) % 16]
    i3 = NUMB2[mod256(i2 + key2 + i1 - cnt - key1) % 16]
    i4 = NUMB1[mod256(i3 + key1 + cnt - key2 - i1) % 16]
    return mod256(i4 - cnt - key1) % 16

def encdec(src, key) -> bytes:        # symmetric: same fn encodes & decodes
    dst = b""
    key1 = key >> 4                   # high nibble of key
    key2 = key & 0xF                  # low nibble of key
    cnt = 0                           # running NIBBLE counter, not reset per byte
    for b in src:
        src1 = b >> 4
        src2 = b & 0xF
        dst1 = shuffle(src1, cnt, key1, key2); cnt += 1
        dst2 = shuffle(src2, cnt, key1, key2); cnt += 1
        dst += bytes([(dst1 << 4) | dst2])
    return dst
```

C++ equivalent (Jutta `ByteEncDecoder.cpp`) is identical math (`i1` named `i5`):
```cpp
uint8_t shuffle(int dataNibble, int nibbleCount, int keyLeft, int keyRight) {
    uint8_t i5   = mod256(nibbleCount >> 4);
    uint8_t t1 = numbers1[mod256(dataNibble + nibbleCount + keyLeft) % 16];
    uint8_t t2 = numbers2[mod256(t1 + keyRight + i5 - nibbleCount - keyLeft) % 16];
    uint8_t t3 = numbers1[mod256(t2 + keyLeft + nibbleCount - keyRight - i5) % 16];
    return mod256(t3 - nibbleCount - keyLeft) % 16;
}
```

### 6.4 Encode wrapper — **byte 0 is always set to the key first** **[C]**
```python
def encrypt(data, key):
    data = bytearray(data)
    data[0] = key            # overwrite byte 0 with key BEFORE encoding
    return encdec(data, key)
```
On **decode**, the result's byte 0 **must equal the key** — use this as the validity check (and as the brute-force oracle if the advert key is unknown):
```python
def bruteforce_key(ciphertext):
    for k in range(256):
        if encdec(ciphertext, k)[0] == k:
            return k
```
**Exception:** Barista lock/unlock (`5a401530`) is written without the byte-0=key step. **[C]**

### 6.5 Verified test vectors **[C — executed]**
```
key=0x2A:  encdec(00 7F 80 →set b0=2A→ 2A 7F 80)               = 77 65 6D        # heartbeat
key=0x2A:  encdec(77c23dd05e81d3dba32bf898a4a3faab45fd)        = 2a280006120000010001090000000000062a   # brew
key=0x2A:  encdec(77ea3dd38981dadba32bfa98a4a3faab45fd)        = 2a0400080c000e010001000000000000062a   # cappuccino
key=0x00:  encdec(14444CC623152D9ABFE772ED1B3F65136B888DDC)    = 00…04           # idle machine status
```
In every case decoded byte 0 == key.

---

## 7. Connection lifecycle, heartbeat & timeouts

### 7.1 Timing constants **[C]**
| Parameter | Value | Source/Notes |
|---|---|---|
| Idle disconnect | ~20 s | machine drops link without traffic |
| Heartbeat interval | **≤ 9 s** | AlexxIT comment "10 is too late, 9 is ok"; franfrancisco9 uses 15 s + 1 s polling (riskier) |
| Heartbeat payload | `00 7F 80` → encoded | written to P-Mode `5a401529` |
| Stats ready wait | ~1200 ms then poll | up to 30 retries × 0.8 s |
| Keep-alive window | 120 s after a command (AlexxIT `ACTIVE_TIME`) | then allow drop |
| Command validity | 15 s (AlexxIT `COMMAND_TIME`) | queued send TTL |

### 7.2 Connection state machine
```
        ┌────────────┐  scan (active)        ┌─────────────┐
        │  IDLE      │ ────────────────────▶ │  SCANNING   │
        └────────────┘                       └─────┬───────┘
              ▲                       found TT214H BlueFrog
              │ disconnect/timeout          (parse key,model)
              │                                   ▼
        ┌─────┴──────┐   GATT connect      ┌─────────────┐
        │ DISCONNECT │ ◀────────────────── │ CONNECTING  │
        └────────────┘     error           └─────┬───────┘
              ▲                              services discovered
              │ no heartbeat >20s                 ▼
              │                            ┌─────────────┐  every ≤9s
              └──────────────────────────  │   ACTIVE    │ ──┐ write encoded 007F80
                                           │ (heartbeat) │ ◀─┘ to P-Mode
                                           └─────┬───────┘
                            command (start/stats/status)
                                                 ▼
                                           ┌─────────────┐
                                           │  COMMAND    │ → back to ACTIVE
                                           └─────────────┘
```

### 7.3 Sequence: connect → brew → keep alive
```
Client                         BlueFrog/E8
  │  active scan                 │
  │ ◀── adv(key=0x2A, model=15057)
  │  GATT connect                │
  │ ──▶                          │
  │  discover services           │
  │ ◀──▶ (5a401523.., 5a401623..)│
  │  [optional] read About Machine (plaintext) ─▶ version
  │  read 5a401524 (status), decode, check ready
  │  write 5a401525 = encdec(brew18, key) ──────▶ start product
  │  (loop) write 5a401529 = encdec(007F80,key) ─▶ heartbeat ≤9s
  │  read 5a401527 (progress, notify) ◀────────── brew progress
  │  ...idle >20s without heartbeat ⇒ peripheral disconnects
```

### 7.4 Reconnection guidance
- Drive reconnection at the **application layer** (re-scan → connect → discover → resume heartbeat). Do not rely solely on OS `autoConnect`/state-restoration. **[I]**
- Use a robust connector with retries (AlexxIT uses `bleak_retry_connector.establish_connection`). On error: wait ~1 s, re-establish. **[C]**
- Expect **"works only on the second press"** on first connect (handshake timing) — mitigate with a persistent ping task that keeps the link warm for ~120 s after activity. **[C, AlexxIT issue #18]**

---

## 8. Command reference & packet structures

### 8.1 Start Product — 18-byte frame → `5a401525` (then `encrypt`) **[C]**
The plaintext buffer is `bytearray(18)`; byte 0 becomes the key on encode; settings are placed at byte offsets defined by the model XML (`@Argument` with leading `F` stripped, value ÷ `@Step`); byte 17 mirrors the key.

```
offset: 0    1     2   3        4            5   6   7    ...           17
field:  key  code  ?   strength water(≈5ml)  ?   ?   temp ...(model)...  key
```

| Byte | Field | Encoding | Conf. |
|---|---|---|---|
| 0 | key | overwritten on encode | C |
| 1 | **product code** | hex `@Code` from model XML (e.g. E8 `03`=Coffee) | C |
| 2 | ? | model-dependent; often `00`/`02` | I |
| 3 | **strength** | `01`–`08` (default `04`); newer models expose 1–10 mapped to 01–08 | C |
| 4 | **water amount** | "seconds", **1 s ≈ 5 ml**; XML `@Step=5` ⇒ store `ml/5` | C |
| 5 | ? (milk on some) | model-dependent | I |
| 6/7 | **temperature** | `01`=Normal, `02`=High (offset is `F7`→byte7 on E8 per XML; Jutta shows byte6 on E6) | C* |
| 5/11 | **milk amount / milk break** | `F5`→byte5 (milk), `F11`→byte11 (milk break) | C |
| 17 | key mirror / checksum | `data[17]=key` | C |

\* The exact byte index of each setting is **defined per model by the XML `@Argument`**, not hard-coded. Always resolve offsets from the model file. **[C]** Bytes 0, 9, 16 are part of the real protocol framing and **must be present or the machine enters a "half-broken" state** (AlexxIT code comment). **[C]**

#### Generic build algorithm **[C]**
```python
data = bytearray(18)
data[1] = int(product["@Code"], 16)
for attr in (SELECTS + NUMBERS):                 # strength, water, temp, milk, ...
    a = product.get(attr.upper())
    if not a: continue
    value = chosen_value(a)
    if step := int(a.get("@Step", 0)):
        value //= step
    pos = int(a["@Argument"][1:])                # "F4" -> 4, "F11" -> 11
    data[pos] = value
data[17] = key
write(START_PRODUCT, encrypt(data, key))
```

#### Real decoded E8 examples (machine "E8 (EB)", key `0x2A`) **[C, from AlexxIT tests]**
```
Café Barista (defaults):              00 28 00 06 12 00 00 01 00 00 09 00 00 00 00 00 00 2a
Café Barista, strength 10, water 50:  00 28 00 0a 0a 00 00 01 00 00 09 00 00 00 00 00 00 2a
Cappuccino:                           00 04 00 08 0c 00 0e 01 00 00 00 00 00 00 00 00 00 2a
```
GIGA 5, Coffee: `00 03 02 03 14 00 00 01 00 00 00 00 00 00 00 00 00 2a`
(On the wire these are run through `encdec(.., 0x2A)`.)

### 8.2 Heartbeat → `5a401529` **[C]**
`encrypt(00 7F 80, key)`. With `0x2A` → `77 65 6D`. Send ≤9 s.

### 8.3 Barista lock → `5a401530` **[C]**
`0x0001` = lock, `0x0000` = unlock. **Written without the byte-0=key step.**

### 8.4 Statistics → `5a401533` (cmd) / `5a401534` (data) **[C]**
Procedure:
1. Write 5-byte command to `5a401533`: `2A 00 01 FF FF`
   (byte0→key on encode; `00 01`=overall counters / `00 10`=daily; `FF FF`=all products, or a product bitmask — see below).
2. Wait ~1200 ms, poll-read `5a401533`; **not-ready** while status byte `[1]==0xE1` (225) or value begins `0x0E`. Up to 30×0.8 s.
3. Read `5a401534`, **decode**.

Product bitmask (to request specific products) **[C]**:
```c
code /= 4; bArr[code/8] |= (1 << (code % 8));
```

### 8.5 Legacy serial product trigger (direct-wire) **[C]**
No 18-byte struct — "press a button": `FA:04`…`FA:09` (product index), `FA:08` hot water, `FA:09` steam — via the 4-byte serial encoding (§13).

---

## 9. Machine status & alerts

Read `5a401524`, decode. Byte 0 = key echo; from byte 1 onward **each bit is one alert**, walked MSB-first per byte. **[C]**
```python
alerts = {}
for i in range((len(data) - 1) * 8):
    offset_abs  = (i >> 3) + 1        # skip byte 0
    offset_byte = 7 - (i & 0b111)     # MSB first
    if (data[offset_abs] >> offset_byte) & 1:
        alerts[i] = alert_names.get(i, f"unknown alert {i}")
```
Bit→name mapping is **per model** (XML `<ALERT Bit="N" Name="…"/>`). Representative E8/E-series bits:

| Bit | Meaning | | Bit | Meaning |
|---|---|---|---|---|
| 0 | insert/empty tray missing | | 7 | milk alert |
| 1 | fill water | | 10 | no beans |
| 2 | empty grounds | | 13 | **coffee ready** |
| 3 | empty tray | | 32 | filter alert |
| 4 | insert coffee bin | | 33 | **descale alert** |
| 5 | outlet missing | | 34 | cleaning alert |
| 6 | rear cover missing | | | |

`PROGRESS_STATE_INTAKE` values (from XML) report brew-state, e.g. `0x24`=Coffee Ready, `0xFF`=P-Mode. **[C]**

---

## 10. Statistics format

Decoded `5a401534` payload = sequence of **3-byte (24-bit) big-endian counters**: **[C]**
```
00014E 000000 000027 000098 00000A 00FFFF 000003 ...
└block0┘ └blk1┘ ...
```
- **Block 0 = grand total** product count.
- **Block N = count for product whose XML `@Code` (hex) == N.** (No fixed "espresso=offset X"; it's the product code, which differs per model.)
- `0xFFFF` ⇒ treat as 0. Reject totals of 0 or > 1,000,000 as corrupt. **[C]**
- Daily vs overall selected by command word `00 10` vs `00 01`.

```python
counts = []
for i in range(0, len(decoded), 3):
    c = int.from_bytes(decoded[i:i+3], "big")
    counts.append(0 if c == 0xFFFF else c)
# counts[0] = total; counts[int(product["@Code"],16)] = that product's count
```
Generic product-code map (franfrancisco9): 0 Overall, 2 Espresso, 3 Coffee, 4 Cappuccino, 5 Milk coffee, 6 Espresso Macchiato, 7 Latte Macchiato, 8 Milk foam, 0x46 Flat White — **but always prefer the model XML.**

---

## 11. Machine definition files (E8 = `EF533`)

- **Source:** bundled in J.O.E. APK under `assets/documents/xml/<TYPE>/1.0.xml` (older builds `resources/assets/machinefiles`), refreshed from Jura cloud. AlexxIT ships them in `core/resources.zip` (588 entries). **[C]**
- **Lookup chain:** advert model id (bytes 4–5) → line in `JOE_MACHINES.TXT` (`id;name;TYPE;col`) → XML dir. **E8 → `15057;E8;EF533;5`** → `EF533/1.0.xml` (dated 07.06.2019). `EF533` also serves E80/E800; variant `EF533V2` exists. (E6→`EF532`, GIGA 5→`EF657`, GIGA 6→`EF566`.) **[C]**
- **Contents:** `<PRODUCT @Code @Name>` with setting elements (`COFFEE_STRENGTH`, `WATER_AMOUNT`, `TEMPERATURE`, `MILK_AMOUNT`, `MILK_BREAK`), each carrying `@Argument` (byte offset, `F`+n), `@Min/@Max/@Step/@Value/@Default`, and `ITEM` lists; plus `ALERTS` (bit map), `PROGRESS_STATE_INTAKE`, and `STATISTIC`/`PROCESSES` banks. **[C]**

### E8 (`EF533`) product table **[C]**
| Code | Product | Settings (offset) |
|---|---|---|
| 01 | Ristretto | strength(F3), water(F4 15–80/5), temp(F7) |
| 02 | Espresso | strength, water(def 45), temp |
| 03 | Coffee | strength, water(25–240/5), temp |
| 04 | Cappuccino | strength, water, temp, milk(F5) |
| 07 | Latte Macchiato | strength, water, temp, milk(F5), milk_break(F11) |
| 0A | Milk Portion | milk(F5) |
| 0D | Hot-water Portion | water(F4 25–450/5), temp(+"Low"=00) |
| 11 / 12 / 13 | 2 Ristretti / 2 Espressi / 2 Coffees | water, temp |
| 2E | Flat White | strength, water, temp, milk |
| 0F | Powder product | (Active="false") |

Strength `ITEM`s: UI 3–10 → values `01`–`08` (default `04`). Temperature: Normal=`01`, High=`02`. **[C]**

---

## 12. Capability matrix

| Capability | How | Char / cmd | Precondition | Conf. |
|---|---|---|---|---|
| Brew coffee/espresso/ristretto | 18-byte start, code 01/02/03 | `5a401525` | ready, beans/water | C |
| Milk drinks (cappuccino, latte, flat white) | code 04/07/2E + milk bytes | `5a401525` | milk connected | C |
| Two-cup products | code 11/12/13 | `5a401525` | — | C |
| Hot water / milk portion | code 0D / 0A | `5a401525` | — | C |
| Strength select | byte at `F3` (01–08) | `5a401525` | — | C |
| Water amount | byte at `F4` (×5 ml) | `5a401525` | — | C |
| Temperature | byte at `F7` (01/02) | `5a401525` | — | C |
| Milk amount / milk break | `F5` / `F11` | `5a401525` | — | C |
| Read machine status / alerts | decode bitfield | `5a401524` | — | C |
| Brew progress | notify/read | `5a401527` | brewing | C |
| Statistics (overall/daily/per-product) | cmd+poll+read | `5a401533/34` | — | C |
| Lock/unlock UI (Barista) | 0001/0000 | `5a401530` | — | C |
| Device identity / version | plaintext read | `5a401531` + advert | — | C |
| Bean / water / tray / grounds monitoring | alert bits | `5a401524` | — | C |
| Maintenance state (descale/clean/filter) | alert bits 32–34 | `5a401524` | — | C |
| Trigger cleaning/maintenance cycles | P-Mode / model-specific | `5a401529`/`5a401538` | — | I/S |
| Power on/off | legacy `AN:` (model-specific) / P-Mode | UART / P-Mode | — | I |
| Firmware update (dongle) | OTA via app (cloud) | proprietary | internet | S |
| User profiles / favourites | app/cloud-side; pushed as start payloads | `5a401525` | — | I |
| Component-level control (pump/grinder/valves) | legacy `FN:` | UART only | service mode | C(serial) |
| Read/write EEPROM | legacy `RE:/RT:/WE:` | UART only | — | C(serial) |

**Limits:** remote brew still needs the machine **physically ready** (beans, water, tray, outlet) — interlocks reported via status bits and not bypassable over BLE. **[C]**

---

## 13. Legacy 5 V TTL UART protocol (service-port heritage)

This is what the BlueFrog bridges to, and what direct-wire DIY projects use. **Different cipher from BLE — do not mix.**

### 13.1 Physical / framing **[C]**
- **9600 baud, 8N1, 5 V TTL.** Lines terminated with **`\r\n`**. Responses echo verb in lowercase; success = `ok:`.
- Service-port pinout varies by model (e.g. juramote Xs90: 1 TX, 2 GND, 3 RX, 4 VCC 5 V).

### 13.2 The 1-byte → 4-byte transfer encoding **[C across Q42/hn/COM8/franfrancisco9]**
Each logical byte → **4 UART bytes**; only **bit 2 (0x04)** and **bit 5 (0x20)** carry data, all other bits forced high (base `0x5B` = `0b01011011`; COM8: `constexpr uint8_t BASE = 0b01011011`).

| UART byte | bit 2 ← | bit 5 ← |
|---|---|---|
| 0 | src b0 | src b1 |
| 1 | src b2 | src b3 |
| 2 | src b4 | src b5 |
| 3 | src b6 | src b7 |

```cpp
// hn/jura-coffee-machine (ESP8266) — cleanest reference
for (int i = 0; i < outbytes.length(); i++) {
  for (int s = 0; s < 8; s += 2) {
    char raw = 255;
    bitWrite(raw, 2, bitRead(outbytes[i], s + 0));
    bitWrite(raw, 5, bitRead(outbytes[i], s + 1));
    serial.write(raw);
  }
  delay(8);                       // ~8 ms between each group of 4 bytes
}
```
**Timing:** ~**8 ms** after each 4-byte group. Receive side reassembles 4 raw bytes → 1 byte by reading bits 2 and 5; resync on 4-byte misalignment. Some impls (COM8/franfrancisco9) apply equivalent extra nibble swaps before bit distribution; machines accept both. **[C]**

### 13.3 Legacy command set **[C, consolidated]**
| Cmd | Arg | Meaning |
|---|---|---|
| `TY:` | — | type/firmware query (`ty:EF516M V01.25`) |
| `TL:` | — | loader version |
| `AN:xx` | 8-bit | analog/test functions; `AN:01/02` power (**ON/OFF labeling is model-specific — conflict**), `AN:0A` **erase EEPROM (danger)**, `AN:0D` prod date, `AN:20/21` test mode |
| `FA:id` | 8-bit | **press button / start product** (`FA:01–04` products, `FA:08` hot water, `FA:09` steam) |
| `FN:id` | 8-bit | **component control** (see below) |
| `RE:addr` | 16-bit | read one 16-bit EEPROM word |
| `RT:addr` | 16-bit | read EEPROM line (16 words / 32 bytes) |
| `RR:addr` | — | read RAM line |
| `WE:addr,val` | — | write EEPROM word |
| `IC:` | — | input board bits (wheel, tank, grounds) |
| `CS:`/`CM:`/`HZ:` | — | sensor/live status (flow meter, heater temps, brew routing) |
| `DA:`/`DT:`/`DR:` | text | display message / default text / reset |
| `GB:` | — | switch off |
| `PM:` | — | play music (easter egg) |

**`FN:` component control:** `01/02` pump on/off, `03/04` water heater, `05/06` steam heater, `07/08` grinder, `0B/0C` coffee press, `0D` brew-group reset, `22` brew-group to position, `1D/1E` drainage valve, `24/25` discharge valve, `26/27` steam valve, `28/29` cappuccino valve. **[C]**

### 13.4 Legacy EEPROM counters **[C method / S addresses]**
No universal address map — counters are found per model by **dump-diffing**: `RT:`/`RE:` dump → make one drink / run maintenance → dump again → diff to locate the changed word. Addresses are model/firmware-specific.

---

## 14. Error & failure catalogue

| Symptom | Cause | Handling | Conf. |
|---|---|---|---|
| Disconnect every ~20 s | missing heartbeat | write `007F80` to P-Mode ≤9 s | C |
| Works only on 2nd press | first-connect handshake timing | persistent ping/keepalive ~120 s; retry connector | C |
| Stats "device not ready" | stats engine busy | poll `5a401533` until `[1]!=0xE1` / not `0x0E…`; ≤30×0.8 s | C |
| Decode garbage / byte0≠key | wrong key or corrupt read | re-read advert key; brute-force; re-read char | C |
| Cannot add machine | **app-PIN set** on machine | unsupported by open clients; clear PIN in J.O.E. | C |
| Brew ignored | machine not ready (interlock) | check status bits (water/beans/tray/outlet) | C |
| "Half-broken" state after brew cmd | bytes 0/9/16 not set | always send full 18-byte frame incl. framing bytes | C |
| Unstable control | CSR8510 **clone** adapter | use genuine CSR8510A10 / vetted adapter | C |
| Passive proxy sees nothing | needs active scan | enable active scanning | C |
| Model status fields wrong/empty | per-model XML mismatch (e.g. Z6 beans, E60) | load correct model XML | C |

**Malformed packets / robustness:** there is no integrity check beyond "byte0==key"; malformed encoded writes are generally ignored or yield no state change rather than crashing the dongle (no evidence of hardening). **No rate limiting** beyond the single-connection lock was observed. **[I]**

---

## 15. Security analysis

| Property | Finding | Conf. |
|---|---|---|
| Confidentiality | **None.** Obfuscation key broadcast in cleartext (advert byte 0); transform deterministic | C |
| Authentication | **None at BLE layer.** No pairing/bonding; any device connects when slot free | C |
| Integrity / anti-replay | **None.** No nonce; `cnt` is positional not global. Captured ciphertext is replayable & forgeable | C/I |
| Access control | Optional **app-level PIN, off by default**, enforced above BLE — does not stop a direct protocol client | C |
| Demonstrated attacks (PTP) | brew on demand, change strength, abort brew, waste beans / overflow tray | C |
| Physical-hazard exploitation | **Blocked by hardware-ready interlocks**; risk is nuisance/waste/mess | C |
| Natural mitigations | single-connection limit + ~3 m range | C |
| CVEs | **None assigned** — treated as a design choice, not a patched vuln | C |

**Recommendations for an integration library:** treat all received data as untrusted; never expose remote brew without explicit user intent + local presence checks; surface the app-PIN limitation clearly; consider an app-side allow-list of bonded machine identifiers since the link itself is open.

---

## 16. Cross-platform implementation guidance

> Universal rule: assume **20-byte ATT payload (MTU 23)** as the safe floor; the 18-byte brew command and small writes fit. Higher MTU is opportunistic. The codec and framing are platform-independent. No OS-level pairing/bonding is needed (open GATT).

### 16.1 Windows (WinRT — `Windows.Devices.Bluetooth`)
- Scan: `BluetoothLEAdvertisementWatcher` (set `ScanningMode=Active`); manufacturer data via `Advertisement.ManufacturerData` (filter company `0x00AB`).
- GATT: `BluetoothLEDevice.FromBluetoothAddressAsync` → `GetGattServicesAsync(BluetoothCacheMode.Uncached)` to dodge stale service cache after firmware change.
- MTU: auto-negotiated; read `GattSession.MaxPduSize` (Win10 2004+). Notifications via `WriteClientCharacteristicConfigurationDescriptorAsync(Notify)` + `ValueChanged`.
- Quirk: callbacks on threadpool — marshal to UI. Desktop (Win32) must keep process alive (no UWP background triggers).
- Libraries: `windows-rs`, or `bleak` (Python, wraps WinRT).

### 16.2 macOS / iOS (CoreBluetooth)
- **No MAC exposed** — identify peripherals by `CBPeripheral.identifier` (per-host NSUUID) + service UUID/name. Persist the NSUUID, not a MAC.
- Scan with explicit service UUID (`scanForPeripherals(withServices: [5a401523…])`) — **required** for background and for advert "overflow" service matching. Background needs `bluetooth-central` UIBackgroundMode; manufacturer-data filtering is degraded in background.
- Info.plist: `NSBluetoothAlwaysUsageDescription` (mandatory, else crash).
- MTU: query `maximumWriteValueLength(for:)`; prefer **write-with-response** for pacing. State restoration via `CBCentralManagerOptionRestoreIdentifierKey`. Deliver callbacks on a dedicated dispatch queue.

### 16.3 Android (`android.bluetooth.le`)
- Permissions: API 31+ `BLUETOOTH_SCAN` (+`neverForLocation`) and `BLUETOOTH_CONNECT`; pre-12 needs `ACCESS_FINE_LOCATION` **and location services on** to scan.
- After connect: `requestMtu(247)` → await `onMtuChanged` before heavy I/O.
- **Serialize all GATT ops** (one outstanding op at a time) via a queue — the #1 Android BLE pitfall.
- Notifications: `setCharacteristicNotification(true)` **and** write CCCD `0x2902` ENABLE_NOTIFICATION_VALUE.
- Use `connectGatt(ctx,false,…)` (direct) for speed; `refresh()` (reflection) to clear service cache. Foreground service for background; Doze restricts scans.

### 16.4 Linux (BlueZ via D-Bus, `org.bluez`)
- Scan: `Adapter1.StartDiscovery`; manufacturer data via `Device1.ManufacturerData` (key `0x00AB`).
- GATT: `GattCharacteristic1.WriteValue(value, {type:'request'|'command'})`, `ReadValue`, `StartNotify`/`StopNotify` (PropertiesChanged on `Value`).
- High throughput: `AcquireWrite`/`AcquireNotify` return an fd + MTU (avoids per-packet D-Bus overhead).
- Clear stale cache by removing the device (`/var/lib/bluetooth/...`). Adapter: prefer genuine CSR8510A10; avoid clones. Libraries: `bleak`, `btleplug` (Rust). `gatttool` handles in §5 aid manual testing.

### 16.5 Common pitfalls
- Honor the **≤9 s heartbeat** on every platform or you'll see the ~20 s disconnect.
- Reassemble/reorder is **not** needed for the 18-byte command, but stats reads may span an ATT long-read — handle on platforms that surface it.
- Implement reconnection at app layer; expect first-attempt flakiness.

---

## 17. Reference client pseudocode

```python
async def jura_connect_and_brew(product_name, strength=None, water_ml=None):
    dev = await scan(active=True, match=lambda a: "TT214H BlueFrog" in a.name
                                            or 0x00AB in a.manufacturer_data)
    adv = dev.manufacturer_data[0x00AB]
    key = adv[0]
    model_id = int.from_bytes(adv[4:6], "little")
    model_xml = load_machine_xml(model_id)          # e.g. 15057 -> EF533/1.0.xml

    client = await establish_connection(dev, retries=3)
    asyncio.create_task(heartbeat_loop(client, key, period=9))

    status = encdec(await client.read(MACHINE_STATUS), key)
    assert_ready(status, model_xml)                 # check alert bits

    product = model_xml.product(product_name)       # has @Code, settings @Argument/@Step
    data = bytearray(18)
    data[1] = int(product["@Code"], 16)
    apply_settings(data, product, strength, water_ml)
    data[17] = key
    await client.write(START_PRODUCT, encrypt(data, key), response=True)

async def heartbeat_loop(client, key, period):
    while client.connected:
        await client.write(P_MODE, encrypt(bytes([0,0x7F,0x80]), key), response=True)
        await asyncio.sleep(period)
```

---

## 18. Known unknowns & open questions
- Exact semantics of bytes **2, 5, 9, 16** in the start frame (framing/checksum vs reserved). **[S]**
- `5a401528` (Update Product Statistics) and `5a401538` (P-Mode Read) payload formats. **[I/unknown]**
- **OTA firmware** payload format over BLE (likely UART service `5a401624/25`). **[S]**
- Cloud CDN URLs for machine XML and firmware. **[S]** (only in-APK asset paths confirmed)
- Whether cleaning/descale/rinse cycles can be **triggered** over BLE (vs only reported). **[S]**
- Manufacturer-data offsets beyond byte 15 (ASCII tail) — exact start offsets uncertain. **[I/S]**
- `AN:` power-code polarity differs by model/firmware (`AN:01` ON vs OFF). **[C conflict]**
- TX/RX UART UUID label order (`5a401624` vs `5a401625`). **[C conflict]**
- Universal legacy-EEPROM counter map does not exist (per-model dump-diff). **[C]**

## 19. Recommended future research
1. Capture E8 J.O.E. traffic (Android **HCI snoop log** → Wireshark) during: brew, each setting change, cleaning cycle, firmware check — to nail bytes 2/5/9/16 and any maintenance-trigger commands.
2. Decompile current `ch.toptronic.joe` (Flutter; `jadx` + Dart asset extraction) to extract the latest machine XML for E8 and any new characteristics.
3. Probe `5a401527` (Product Progress) **notifications** during a live brew to document progress-state values.
4. Subscribe to `5a401528`/`5a401538`; fuzz with known-good framing to map them.
5. Diff `EF533` vs `EF533V2` XML to document E8 firmware-revision differences.
6. Validate heartbeat tolerance and reconnection behavior across Smart Connect firmware versions.

---

## 20. Appendix A — Quick reference card

```
SERVICE (control):  5a401523-ab2e-2548-c435-08c300000710
SERVICE (uart):     5a401623-ab2e-2548-c435-08c300000710
STATUS    read   :  5a401524   (decode; bitfield alerts)
START     write  :  5a401525   (encode 18-byte frame)
PROGRESS  notify :  5a401527   (decode)
P-MODE    write  :  5a401529   (encode 00 7F 80 heartbeat, <=9s)
BARISTA   write  :  5a401530   (0001 lock / 0000 unlock; NO byte0=key)
STATS-CMD write  :  5a401533   (2A 00 01 FF FF; poll until [1]!=E1)
STATS-DAT read   :  5a401534   (decode; 3-byte BE counters)
ABOUT     read   :  5a401531   (plaintext)
ADVERT mfr id    :  0x00AB (171);  byte0=key; bytes4-5=model id (E8=15057)
CIPHER           :  encdec() nibble-shuffle, NUMB1/NUMB2, key=advert byte0
HEARTBEAT        :  encdec(00 7F 80, 0x2A) = 77 65 6D
E8 model/type    :  15057 -> EF533 (EF533/1.0.xml)
E8 codes         :  01 Rist 02 Esp 03 Coffee 04 Capp 07 Latte 0A Milk
                    0D HotWater 11/12/13 doubles 2E FlatWhite
TIMING           :  idle 20s; heartbeat <=9s; stats wait ~1200ms
```

## 21. Appendix B — Raw findings index
The following working notes captured during research are retained in `docs/research/`:
- `_primary_grounding.md` — directly-fetched AlexxIT source (UUIDs, cipher verbatim, advert/command/stats logic).
- `_crossplatform_notes.md` — per-OS BLE API notes feeding §16.

---

## 22. Sources

**Open-source implementations**
- AlexxIT/Jura (HA, BLE): https://github.com/AlexxIT/Jura — `core/encryption.py`, `core/client.py`, `core/device.py`, `tests/test_misc.py`, `core/resources.zip`
- AlexxIT/Jura issues: #7 (20s disconnect), #18 (second-press), #42 (S8 discovery), #48 (stats not ready), #51/#60 (model status)
- Jutta-Proto/protocol-bt-cpp: https://github.com/Jutta-Proto/protocol-bt-cpp — `README.md`, `src/bt/ByteEncDecoder.cpp`
- Jutta-Proto/protocol-cpp: https://github.com/Jutta-Proto/protocol-cpp
- franfrancisco9/Jura-Python-BT: https://github.com/franfrancisco9/Jura-Python-BT — `src/bt_encoder.py`, `data/uuids_handles.json`, `products.json`, `alerts.json`
- COM8/esp32-jura: https://github.com/COM8/esp32-jura — `JuraCommands.hpp`, `JuraConnection.cpp`
- hn/jura-coffee-machine: https://github.com/hn/jura-coffee-machine — `cmd2jura.ino`
- Q42/coffeehack: https://github.com/Q42/coffeehack — `jura.py`; https://blog.q42.nl/hacking-the-coffee-machine-5802172b17c1/
- PromyLOPh/juramote: https://github.com/PromyLOPh/juramote ; https://6xq.net/juramote/
- oliverk71 wiki (Impressa S95/S90/X70 commands): https://github.com/oliverk71/Coffeemaker-Payment-System/wiki

**App / reverse engineering write-ups**
- lunarius "Joe the friendly coffee maker" (JADX + btsnoop/Wireshark): https://lunarius.fe80.eu/blog/tag/bluetooth.html
- J.O.E. Android (`ch.toptronic.joe`): https://play.google.com/store/apps/details?id=ch.toptronic.joe
- J.O.E. iOS (id 1364370646): https://apps.apple.com/us/app/j-o-e/id1364370646

**Security**
- Pen Test Partners — "'Hacking' the Nespresso Prodigio and Jura E8 coffee machines": https://www.pentestpartners.com/security-blog/hacking-the-nespresso-prodigio-and-jura-e8-coffee-machines/
- McAfee Labs — "Your Smart Coffee Maker is Brewing Up Trouble": https://www.mcafee.com/blogs/other-blogs/mcafee-labs/your-smart-coffee-maker-is-brewing-up-trouble/

**Vendor**
- JURA Smart Connect (art. 72167): https://www.jura.com/en/homeproducts/accessories/SmartConnect-Main-72167
- JURA J.O.E. Android manual (PDF): https://us.jura.com/-/media/global/pdf/manuals-global/accessories/joe/download_manual_joe_android_us.pdf

---

*End of specification. Confidence labels [C]/[I]/[S] denote Confirmed / Inferred / Speculative as defined in §0.1.*
