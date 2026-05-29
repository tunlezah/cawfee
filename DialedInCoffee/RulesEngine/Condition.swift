import Foundation

public enum Condition: Hashable, Sendable {
    case grinderAtLeast(Int)
    case grinderAtMost(Int)
    case strengthAtLeast(Int)
    case strengthAtMost(Int)
    case volumeAtLeast(Int)
    case volumeAtMost(Int)
    case milkSecondsAtLeast(Int)
    case milkSecondsAtMost(Int)
    case tempEquals(TemperatureLevel)
    case drinkIs(DrinkType)
    case drinkIsMilkBased
    case milkKindIs(MilkKind)
    case beanRoastAtLeast(RoastLevel)
    case beanRoastAtMost(RoastLevel)

    public func isSatisfied(
        current: MachineSettings,
        drink: DrinkType,
        milk: Milk,
        bean: BeanSnapshot?
    ) -> Bool {
        switch self {
        case .grinderAtLeast(let n): return current.grinder >= n
        case .grinderAtMost(let n): return current.grinder <= n
        case .strengthAtLeast(let n): return current.strength >= n
        case .strengthAtMost(let n): return current.strength <= n
        case .volumeAtLeast(let n): return current.volumeML >= n
        case .volumeAtMost(let n): return current.volumeML <= n
        case .milkSecondsAtLeast(let n): return current.milkSeconds >= n
        case .milkSecondsAtMost(let n): return current.milkSeconds <= n
        case .tempEquals(let t): return current.temperature == t
        case .drinkIs(let d): return drink == d
        case .drinkIsMilkBased: return drink.isMilkBased
        case .milkKindIs(let k): return milk.kind == k
        case .beanRoastAtLeast(let r):
            guard let bean else { return false }
            return Self.roastOrder(bean.roastLevel) >= Self.roastOrder(r)
        case .beanRoastAtMost(let r):
            guard let bean else { return false }
            return Self.roastOrder(bean.roastLevel) <= Self.roastOrder(r)
        }
    }

    private static func roastOrder(_ r: RoastLevel) -> Int {
        switch r {
        case .light: return 0
        case .mediumLight: return 1
        case .medium: return 2
        case .mediumDark: return 3
        case .dark: return 4
        }
    }
}
