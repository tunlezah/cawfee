import SwiftUI

/// macOS/iOS Bluetooth control panel for the connected Jura machine. Mirrors the Android
/// `MachineScreen`, driven by `JuraBluetoothManager` over the shared protocol layer.
struct MachineControlView: View {
    @StateObject private var manager = JuraBluetoothManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                switch manager.state {
                case .connected:
                    connectedPanel
                case .connecting:
                    Label("Connecting…", systemImage: "antenna.radiowaves.left.and.right")
                default:
                    scanPanel
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle("Machine")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Connect over Bluetooth")
                .font(.title2).bold()
            Text("Discover your Jura Smart Connect dongle and brew remotely.")
                .foregroundStyle(.secondary)
        }
    }

    private var scanPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Button("Scan for machines") { manager.startScan() }
                    .buttonStyle(.borderedProminent)
                if case .scanning = manager.state {
                    Button("Stop") { manager.stopScan() }
                    ProgressView()
                }
            }
            if case .failed(let message) = manager.state {
                Text("Failed: \(message)").foregroundStyle(.red)
            }
            ForEach(manager.discovered) { machine in
                panel {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(machine.name).font(.headline)
                        Text(String(format: "Model id %d · key 0x%02X · RSSI %d dBm",
                                    machine.advertisement.modelId, machine.advertisement.key, machine.rssi))
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Connect") { manager.connect(machine) }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var connectedPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            panel {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Connected").font(.headline)
                    if let status = manager.status {
                        if status.isReadyToBrew {
                            Text("Ready to brew" + (status.coffeeReady ? " · coffee ready" : ""))
                        } else {
                            Text("Not ready: " + status.alerts.filter { $0.isBlocking }.map(\.name).joined(separator: ", "))
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("Reading status…").foregroundStyle(.secondary)
                    }
                    Toggle("Barista lock", isOn: Binding(
                        get: { manager.baristaLocked },
                        set: { manager.setBaristaLock($0) }
                    ))
                }
            }

            Text("Brew").font(.headline)
            ForEach(manager.products, id: \.code) { product in
                panel {
                    HStack {
                        Text(product.name)
                        Spacer()
                        Button("Start") { manager.brew(product) }
                            .buttonStyle(.borderedProminent)
                            .disabled(manager.status?.isReadyToBrew == false)
                    }
                }
            }

            HStack {
                Button("Statistics") { manager.requestStatistics() }
                Button("Refresh") { manager.refreshStatus() }
                Button("Disconnect", role: .destructive) { manager.disconnect() }
            }
            if let stats = manager.statistics {
                Text("Total drinks: \(stats.total)").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func panel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
