import Foundation

/// Coffee temperature levels (spec §11).
enum JuraTemperature: Int {
    case low = 0x00, normal = 0x01, high = 0x02
}

enum JuraSettingKind { case strength, water, temperature, milk, milkBreak }

/// One settable parameter and its byte offset / step in the 18-byte start frame.
struct JuraProductSetting {
    let kind: JuraSettingKind
    let argument: Int
    let step: Int
    let minValue: Int
    let maxValue: Int
    let defaultValue: Int

    func toByte(_ value: Int) -> Int {
        let clamped = Swift.min(Swift.max(value, minValue), maxValue)
        return step > 1 ? clamped / step : clamped
    }
}

struct JuraProduct {
    let code: Int
    let name: String
    let isMilkBased: Bool
    let settings: [JuraProductSetting]

    func setting(_ kind: JuraSettingKind) -> JuraProductSetting? { settings.first { $0.kind == kind } }
}

struct JuraMachineModel {
    let modelId: Int
    let name: String
    let type: String
    let products: [JuraProduct]
    let alertNames: [Int: String]

    func product(code: Int) -> JuraProduct? { products.first { $0.code == code } }
}

/// User-chosen brew parameters (natural units; nil ⇒ product default).
struct JuraBrewParameters {
    var strength: Int?
    var waterMl: Int?
    var temperature: JuraTemperature?
    var milkMl: Int?
    var milkBreak: Int?

    init(strength: Int? = nil, waterMl: Int? = nil, temperature: JuraTemperature? = nil,
         milkMl: Int? = nil, milkBreak: Int? = nil) {
        self.strength = strength
        self.waterMl = waterMl
        self.temperature = temperature
        self.milkMl = milkMl
        self.milkBreak = milkBreak
    }
}

/// Builds the obfuscated payloads written to each characteristic (spec §8). Mirrors the
/// Kotlin `JuraCommands`.
enum JuraCommands {
    static let startFrameSize = 18

    static func buildStartFrame(product: JuraProduct, params: JuraBrewParameters, key: Int) -> [UInt8] {
        var data = [UInt8](repeating: 0, count: startFrameSize)
        data[1] = UInt8(product.code)
        for setting in product.settings {
            let natural: Int
            switch setting.kind {
            case .strength: natural = params.strength ?? setting.defaultValue
            case .water: natural = params.waterMl ?? setting.defaultValue
            case .temperature: natural = params.temperature?.rawValue ?? setting.defaultValue
            case .milk: natural = params.milkMl ?? setting.defaultValue
            case .milkBreak: natural = params.milkBreak ?? setting.defaultValue
            }
            data[setting.argument] = UInt8(setting.toByte(natural))
        }
        data[17] = UInt8(key & 0xFF)
        return data
    }

    static func startProduct(product: JuraProduct, params: JuraBrewParameters, key: Int) -> [UInt8] {
        JuraCipher.encrypt(buildStartFrame(product: product, params: params, key: key), key: key)
    }

    static func heartbeat(key: Int) -> [UInt8] {
        JuraCipher.encrypt([0x00, 0x7F, 0x80], key: key)
    }

    static func baristaLock(_ locked: Bool, key: Int) -> [UInt8] {
        JuraCipher.encDecRaw(locked ? [0x00, 0x01] : [0x00, 0x00], key: key)
    }

    static func statisticsRequest(daily: Bool, key: Int) -> [UInt8] {
        JuraCipher.encrypt([0x00, 0x00, daily ? 0x10 : 0x01, 0xFF, 0xFF], key: key)
    }
}

/// Built-in machine definitions (currently the E8 / EF533 table, spec §11).
enum JuraMachineCatalog {
    private static func strength(_ def: Int = 4) -> JuraProductSetting {
        .init(kind: .strength, argument: 3, step: 1, minValue: 1, maxValue: 8, defaultValue: def)
    }
    private static func water(_ minV: Int, _ maxV: Int, _ def: Int) -> JuraProductSetting {
        .init(kind: .water, argument: 4, step: 5, minValue: minV, maxValue: maxV, defaultValue: def)
    }
    private static func temperature(_ def: Int = 1) -> JuraProductSetting {
        .init(kind: .temperature, argument: 7, step: 1, minValue: 0, maxValue: 2, defaultValue: def)
    }
    private static func milk(_ def: Int = 0) -> JuraProductSetting {
        .init(kind: .milk, argument: 5, step: 5, minValue: 0, maxValue: 120, defaultValue: def)
    }
    private static func milkBreak(_ def: Int = 0) -> JuraProductSetting {
        .init(kind: .milkBreak, argument: 11, step: 1, minValue: 0, maxValue: 60, defaultValue: def)
    }

    static let e8 = JuraMachineModel(
        modelId: JuraGatt.modelIdE8,
        name: "E8",
        type: "EF533",
        products: [
            JuraProduct(code: 0x01, name: "Ristretto", isMilkBased: false, settings: [strength(), water(15, 80, 20), temperature()]),
            JuraProduct(code: 0x02, name: "Espresso", isMilkBased: false, settings: [strength(), water(15, 80, 45), temperature()]),
            JuraProduct(code: 0x03, name: "Coffee", isMilkBased: false, settings: [strength(), water(25, 240, 110), temperature()]),
            JuraProduct(code: 0x04, name: "Cappuccino", isMilkBased: true, settings: [strength(), water(25, 240, 60), temperature(), milk(60)]),
            JuraProduct(code: 0x07, name: "Latte Macchiato", isMilkBased: true, settings: [strength(), water(25, 240, 60), temperature(), milk(100), milkBreak()]),
            JuraProduct(code: 0x0A, name: "Milk Portion", isMilkBased: true, settings: [milk(60)]),
            JuraProduct(code: 0x0D, name: "Hot Water", isMilkBased: false, settings: [water(25, 450, 150), temperature(0)]),
            JuraProduct(code: 0x11, name: "2 Ristretti", isMilkBased: false, settings: [water(15, 80, 20), temperature()]),
            JuraProduct(code: 0x12, name: "2 Espressi", isMilkBased: false, settings: [water(15, 80, 45), temperature()]),
            JuraProduct(code: 0x13, name: "2 Coffees", isMilkBased: false, settings: [water(25, 240, 110), temperature()]),
            JuraProduct(code: 0x2E, name: "Flat White", isMilkBased: true, settings: [strength(), water(25, 240, 60), temperature(), milk(40)]),
        ],
        alertNames: [
            0: "Insert/empty tray missing", 1: "Fill water", 2: "Empty grounds", 3: "Empty tray",
            4: "Insert coffee bin", 5: "Outlet missing", 6: "Rear cover missing", 7: "Milk alert",
            10: "No beans", 13: "Coffee ready", 32: "Filter alert", 33: "Descale alert", 34: "Cleaning alert",
        ]
    )

    static func forModelId(_ id: Int) -> JuraMachineModel? { id == e8.modelId ? e8 : nil }
}
