import Foundation

public enum MachineRanges {
    public static let grinderRange: ClosedRange<Int> = 1...7
    public static let strengthRange: ClosedRange<Int> = 1...10
    public static let volumeRange: ClosedRange<Int> = 25...240
    public static let milkDurationRange: ClosedRange<Int> = 3...120

    public static func clampGrinder(_ value: Int) -> Int { clamp(value, to: grinderRange) }
    public static func clampStrength(_ value: Int) -> Int { clamp(value, to: strengthRange) }
    public static func clampVolume(_ value: Int) -> Int { clamp(value, to: volumeRange) }
    public static func clampMilkDuration(_ value: Int) -> Int { clamp(value, to: milkDurationRange) }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
