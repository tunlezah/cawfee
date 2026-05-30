import Foundation

/// Swift port of the Jura BlueFrog nibble-shuffle obfuscation (spec §6). This is a
/// byte-for-byte mirror of the Kotlin `:protocol` `JuraCipher`, so both platforms share
/// one protocol strategy. Verified against the spec's executed vectors
/// (`encrypt(00 7F 80, 0x2A) == 77 65 6D`) by `JuraProtocolTests`.
enum JuraCipher {
    private static let numb1: [Int] = [14, 4, 3, 2, 1, 13, 8, 11, 6, 15, 12, 7, 10, 5, 0, 9]
    private static let numb2: [Int] = [10, 6, 13, 12, 14, 11, 1, 9, 15, 7, 0, 5, 3, 2, 4, 8]

    /// Always-non-negative modulo, matching the reference Python `%`.
    private static func mod(_ a: Int, _ m: Int) -> Int { ((a % m) + m) % m }

    private static func shuffle(_ src: Int, _ cnt: Int, _ key1: Int, _ key2: Int) -> Int {
        let i1 = mod(cnt >> 4, 256)
        let i2 = numb1[mod(src + cnt + key1, 16)]
        let i3 = numb2[mod(i2 + key2 + i1 - cnt - key1, 16)]
        let i4 = numb1[mod(i3 + key1 + cnt - key2 - i1, 16)]
        return mod(i4 - cnt - key1, 16)
    }

    /// Symmetric (involutive) encode/decode under a single-byte key.
    static func encDec(_ src: [UInt8], key: Int) -> [UInt8] {
        let key1 = (key & 0xFF) >> 4
        let key2 = key & 0x0F
        var cnt = 0
        var out = [UInt8]()
        out.reserveCapacity(src.count)
        for b in src {
            let hi = Int(b) >> 4
            let lo = Int(b) & 0x0F
            let dHi = shuffle(hi, cnt, key1, key2); cnt += 1
            let dLo = shuffle(lo, cnt, key1, key2); cnt += 1
            out.append(UInt8((dHi << 4) | dLo))
        }
        return out
    }

    /// Encode a command: byte 0 is overwritten with the key, then run through `encDec`.
    static func encrypt(_ data: [UInt8], key: Int) -> [UInt8] {
        var copy = data
        if !copy.isEmpty { copy[0] = UInt8(key & 0xFF) }
        return encDec(copy, key: key)
    }

    /// Decode a received payload (result byte 0 == key on success).
    static func decrypt(_ data: [UInt8], key: Int) -> [UInt8] { encDec(data, key: key) }

    /// Raw codec without the byte-0=key step (Barista lock only, §8.3).
    static func encDecRaw(_ data: [UInt8], key: Int) -> [UInt8] { encDec(data, key: key) }

    static func bruteForceKey(_ ciphertext: [UInt8]) -> Int? {
        guard !ciphertext.isEmpty else { return nil }
        for k in 0...255 where Int(encDec(ciphertext, key: k)[0]) == k { return k }
        return nil
    }
}
