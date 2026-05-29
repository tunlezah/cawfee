# Cross-platform BLE notes (draft - to merge)

## Windows (WinRT / Windows.Devices.Bluetooth)
- API: `BluetoothLEDevice`, `GattDeviceService`, `GattCharacteristic`. Use the WinRT projection (C#/C++/WinRT) or `winrt-rs`/`windows-rs` for Rust, or `bleak` (Python) which wraps WinRT.
- Discovery: `BluetoothLEAdvertisementWatcher` for scanning; manufacturer data available via `Advertisement.ManufacturerData`.
- Quirk: Windows caches GATT services aggressively. After a firmware change you may need to unpair/re-pair to refresh the service cache. `GetGattServicesAsync(BluetoothCacheMode.Uncached)` forces a fresh read.
- Quirk: Windows often requires the device to be *paired* at OS level to access certain characteristics; for non-bonded peripherals like Smart Connect this is usually fine since Jura uses no link-layer encryption (Just Works / no bonding for data chars).
- MTU: WinRT does not expose MTU negotiation directly; it negotiates automatically. `GattSession.MaxPduSize` (Win10 2004+) reports the negotiated ATT MTU. Default 23, often 247 after negotiation.
- Notifications: write to CCCD via `WriteClientCharacteristicConfigurationDescriptorAsync(Notify)`. Handler on `ValueChanged`.
- Threading: callbacks arrive on threadpool; marshal to UI thread.
- Background: UWP supports background BLE triggers; Win32 desktop apps must keep process alive.

## macOS / iOS (CoreBluetooth)
- Single framework `CoreBluetooth` for both; `CBCentralManager`, `CBPeripheral`, `CBCharacteristic`.
- iOS NEVER exposes the BD_ADDR (MAC). Peripherals are identified by an opaque `CBPeripheral.identifier` (NSUUID) that is per-host-device stable but differs across phones. => cannot hardcode MAC; must scan by service UUID / advertised name.
- macOS also hides MAC since ~Big Sur; same NSUUID model.
- Scanning: `scanForPeripherals(withServices:)` — MUST pass the Jura service UUID to discover in background; background scans without service filter are dropped.
- iOS background mode: requires `bluetooth-central` UIBackgroundMode. Background scan cannot use timers, slower, no manufacturer-data-only filtering.
- iOS does NOT deliver manufacturer/advertisement data the same when app is backgrounded; service UUIDs in advert overflow area are moved to a special "overflow" area only matchable by explicit service UUID.
- MTU: not directly settable; query `maximumWriteValueLength(for: .withoutResponse)`. iOS negotiates up to 185 (legacy) / 244+. Use `.withResponse` for reliability with Jura's chunked writes.
- State restoration: `CBCentralManagerOptionRestoreIdentifierKey` to relaunch app on BLE events.
- Threading: deliver callbacks on a dedicated dispatch queue passed to CBCentralManager init.
- Permissions: `NSBluetoothAlwaysUsageDescription` (iOS 13+) Info.plist key required or app crashes.

## Android (android.bluetooth.le)
- API: `BluetoothLeScanner`, `BluetoothGatt`, `BluetoothGattCharacteristic`.
- Permissions: Android 12+ (API 31) requires `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` runtime permissions; pre-12 needs `ACCESS_FINE_LOCATION` (and location services ENABLED) to scan. `neverForLocation` flag on BLUETOOTH_SCAN avoids location on 12+.
- MTU: call `requestMtu(247)` AFTER connect, BEFORE heavy I/O; wait for `onMtuChanged`. Default 23.
- Quirk: must serialize GATT operations — only ONE outstanding op (write/read/descriptor write) at a time; queue them. This is the #1 source of Android BLE bugs.
- Quirk: enabling notifications requires BOTH `setCharacteristicNotification(true)` AND writing the CCCD descriptor (0x2902) value ENABLE_NOTIFICATION_VALUE.
- Quirk: call `gatt.discoverServices()` only after CONNECTED; on some devices delay ~600ms after bond. `refresh()` (hidden reflection API) clears service cache.
- autoConnect: `connectGatt(ctx,false,...)` direct connect is faster; autoConnect=true is slower but better for reconnection.
- Write type: Jura framing benefits from WRITE_TYPE_DEFAULT (with response) to pace the 20-byte chunks.
- Threading: callbacks on binder thread; post to main/handler.
- Background: foreground service recommended; Doze restricts scans; use `ScanSettings` low-power + `PendingIntent` scan for background.

## Linux (BlueZ via D-Bus)
- Interface: BlueZ 5.x over D-Bus (`org.bluez`). Use `bluetoothctl` for manual, `gatttool`/`btgatt-client` (deprecated), or libraries: `bleak` (Python, uses BlueZ D-Bus), `gobject`/`dbus`, `bluez` C, `btleplug` (Rust).
- Scanning: `org.bluez.Adapter1.StartDiscovery`; manufacturer data via `org.bluez.Device1.ManufacturerData`.
- GATT: `org.bluez.GattCharacteristic1` with `ReadValue`, `WriteValue` (dict options: `type` = `request`/`command`), `StartNotify`/`StopNotify` (PropertiesChanged signal on `Value`).
- MTU: BlueZ auto-negotiates; can request via `AcquireWrite`/`AcquireNotify` which return a file descriptor + MTU for high-throughput (avoids D-Bus per-packet overhead).
- Quirk: BlueZ caches GATT in `/var/lib/bluetooth/<adapter>/<device>/`; stale cache after firmware change -> remove device.
- Quirk: `WriteValue` with `type=command` = write-without-response; `type=request` = write-with-response.
- Threading: D-Bus mainloop (GLib) drives callbacks.
- Permissions: user must be in `bluetooth` group or run with caps; `StartDiscovery` may need polkit.

## Common cross-platform concerns
- No link-layer security/bonding for Jura data path => avoid OS-level pairing requirements; treat as open GATT (Smart Connect PIN handled at *application* layer, see protocol section).
- 20-byte ATT payload assumption (MTU 23) is the safe lower bound; Jura framing chunks to <=20 data bytes. Higher MTU is opportunistic.
- Notification reassembly must be platform-agnostic and key-shuffle aware.
- Reconnection: implement app-level state machine; do not rely on autoConnect/restore alone.
