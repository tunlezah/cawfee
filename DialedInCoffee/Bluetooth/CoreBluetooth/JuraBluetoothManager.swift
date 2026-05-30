import CoreBluetooth
import Foundation
import Combine

/// A discovered Jura machine on macOS/iOS.
struct DiscoveredMachine: Identifiable {
    let peripheral: CBPeripheral
    let advertisement: JuraAdvertisement
    let rssi: Int
    var id: UUID { peripheral.identifier }
    var name: String { peripheral.name ?? "Jura machine" }
}

/// High-level connection lifecycle.
enum JuraConnectionState: Equatable {
    case idle
    case scanning
    case connecting
    case connected
    case disconnected(String?)
    case failed(String)
}

/// CoreBluetooth implementation of the Jura BLE client for macOS/iOS. Uses the shared,
/// platform-independent protocol logic (`JuraCipher`, `JuraCommands`, `JuraParsers`) so
/// the wire behaviour matches the Android client exactly.
@MainActor
final class JuraBluetoothManager: NSObject, ObservableObject {

    @Published private(set) var state: JuraConnectionState = .idle
    @Published private(set) var discovered: [DiscoveredMachine] = []
    @Published private(set) var status: JuraMachineStatus?
    @Published private(set) var statistics: JuraStatistics?
    @Published private(set) var baristaLocked = false

    var model: JuraMachineModel = JuraMachineCatalog.e8
    var products: [JuraProduct] { model.products }

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristics: [CBUUID: CBCharacteristic] = [:]
    private var key: Int = 0x2A
    private var heartbeatTimer: Timer?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil) // main-queue callbacks
    }

    // MARK: - Public API

    func startScan() {
        guard central.state == .poweredOn else { return }
        discovered = []
        state = .scanning
        // Scan broadly; filter on manufacturer data so we recover the key + model.
        central.scanForPeripherals(withServices: nil,
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() { central.stopScan() }

    func connect(_ machine: DiscoveredMachine) {
        stopScan()
        key = machine.advertisement.key
        model = JuraMachineCatalog.forModelId(machine.advertisement.modelId) ?? JuraMachineCatalog.e8
        peripheral = machine.peripheral
        machine.peripheral.delegate = self
        state = .connecting
        central.connect(machine.peripheral, options: nil)
    }

    func disconnect() {
        stopHeartbeat()
        if let p = peripheral { central.cancelPeripheralConnection(p) }
    }

    func refreshStatus() {
        guard let p = peripheral, let c = characteristics[JuraGatt.charMachineStatus] else { return }
        p.readValue(for: c)
    }

    func brew(_ product: JuraProduct, params: JuraBrewParameters = JuraBrewParameters()) {
        guard let p = peripheral, let c = characteristics[JuraGatt.charStartProduct] else { return }
        let payload = JuraCommands.startProduct(product: product, params: params, key: key)
        p.writeValue(Data(payload), for: c, type: .withResponse)
    }

    func setBaristaLock(_ locked: Bool) {
        guard let p = peripheral, let c = characteristics[JuraGatt.charBarista] else { return }
        p.writeValue(Data(JuraCommands.baristaLock(locked, key: key)), for: c, type: .withResponse)
        baristaLocked = locked
    }

    func requestStatistics(daily: Bool = false) {
        guard let p = peripheral, let c = characteristics[JuraGatt.charStatisticsCmd] else { return }
        p.writeValue(Data(JuraCommands.statisticsRequest(daily: daily, key: key)), for: c, type: .withResponse)
        // Read the data characteristic after the engine has had time to populate it.
        DispatchQueue.main.asyncAfter(deadline: .now() + JuraGatt.Timing.statsInitialWait) { [weak self] in
            guard let self, let p = self.peripheral,
                  let d = self.characteristics[JuraGatt.charStatisticsData] else { return }
            p.readValue(for: d)
        }
    }

    // MARK: - Heartbeat (spec §7)

    private func startHeartbeat() {
        stopHeartbeat()
        let timer = Timer(timeInterval: JuraGatt.Timing.heartbeatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sendHeartbeat() }
        }
        RunLoop.main.add(timer, forMode: .common)
        heartbeatTimer = timer
    }

    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    private func sendHeartbeat() {
        guard let p = peripheral, let c = characteristics[JuraGatt.charPMode] else { return }
        p.writeValue(Data(JuraCommands.heartbeat(key: key)), for: c, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate

extension JuraBluetoothManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            if central.state != .poweredOn { self.state = .disconnected("Bluetooth unavailable") }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any],
                                    rssi RSSI: NSNumber) {
        guard let mfg = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              mfg.count >= 2 else { return }
        let company = UInt16(mfg[0]) | (UInt16(mfg[1]) << 8)
        guard company == JuraGatt.companyId else { return }
        let payload = Array(mfg.dropFirst(2))
        guard let adv = JuraParsers.parseAdvertisement(payload), adv.isValid else { return }
        let machine = DiscoveredMachine(peripheral: peripheral, advertisement: adv, rssi: RSSI.intValue)
        Task { @MainActor in
            self.discovered.removeAll { $0.id == machine.id }
            self.discovered.append(machine)
            self.discovered.sort { $0.rssi > $1.rssi }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([JuraGatt.serviceControl, JuraGatt.serviceUart])
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in self.state = .failed(error?.localizedDescription ?? "Connection failed") }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.stopHeartbeat()
            self.characteristics = [:]
            self.state = .disconnected(error?.localizedDescription)
        }
    }
}

// MARK: - CBPeripheralDelegate

extension JuraBluetoothManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            for c in service.characteristics ?? [] {
                self.characteristics[c.uuid] = c
                if c.uuid == JuraGatt.charProductProgress {
                    peripheral.setNotifyValue(true, for: c)
                }
            }
            if self.characteristics[JuraGatt.charStartProduct] != nil,
               self.characteristics[JuraGatt.charMachineStatus] != nil,
               case .connecting = self.state {
                self.state = .connected
                self.startHeartbeat()
                self.refreshStatus()
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let bytes = [UInt8](data)
        let uuid = characteristic.uuid
        Task { @MainActor in
            // key + model are MainActor-isolated, so decode here.
            switch uuid {
            case JuraGatt.charMachineStatus:
                self.status = JuraParsers.parseStatus(
                    decoded: JuraCipher.decrypt(bytes, key: self.key), model: self.model)
            case JuraGatt.charStatisticsData:
                self.statistics = JuraParsers.parseStatistics(
                    decoded: JuraCipher.decrypt(bytes, key: self.key))
            default:
                break
            }
        }
    }
}
