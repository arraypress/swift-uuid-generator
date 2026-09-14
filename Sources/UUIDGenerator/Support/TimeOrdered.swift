//
//  TimeOrdered.swift
//  UUIDGenerator
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Identifiers that sort by the moment they were made.
///
/// A v4 UUID is random, so a table keyed on one has its index rewritten at a
/// random place on every insert. A time-ordered identifier appends, which is
/// why UUID v7 (RFC 9562) and ULID exist and why they are what a database
/// actually wants.
///
/// Both are generated **monotonically**: identifiers made inside the same
/// millisecond still sort in the order they were made, because the random
/// part is incremented rather than redrawn. Without that, a thousand ids
/// generated in one millisecond would sort arbitrarily, and "sortable" would
/// be a claim the type does not keep.
public enum TimeOrdered {

    /// Guards the counter shared by monotonic generation.
    private static let lock = NSLock()
    // Guarded by `lock` on every read and write, which is what
    // `nonisolated(unsafe)` is asking us to promise.
    nonisolated(unsafe) private static var lastMilliseconds: UInt64 = 0
    nonisolated(unsafe) private static var lastRandom: [UInt8] = []

    /// Milliseconds since the Unix epoch.
    static func now() -> UInt64 {
        UInt64((Date().timeIntervalSince1970 * 1000).rounded(.down))
    }

    /// Cryptographically secure random bytes.
    static func randomBytes(_ count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        for index in 0..<count { bytes[index] = UInt8.random(in: 0...255) }
        return bytes
    }

    /// The timestamp and randomness for the next identifier, monotonic within
    /// a millisecond.
    ///
    /// - Parameter randomCount: How many random bytes the format carries —
    ///   10 for a ULID, 10 for the bytes a v7 fills after its timestamp.
    static func next(randomCount: Int) -> (milliseconds: UInt64, random: [UInt8]) {
        lock.lock()
        defer { lock.unlock() }

        let milliseconds = now()
        if milliseconds == lastMilliseconds, lastRandom.count == randomCount {
            // Same millisecond: increment the random field as a big-endian
            // integer so the next identifier still sorts after this one.
            var bytes = lastRandom
            var index = bytes.count - 1
            while index >= 0 {
                if bytes[index] == 0xFF {
                    bytes[index] = 0
                    index -= 1
                } else {
                    bytes[index] += 1
                    break
                }
            }
            // Overflowing every byte inside one millisecond is not reachable
            // in practice; redrawing is the only honest thing left to do.
            if index < 0 { bytes = randomBytes(randomCount) }
            lastRandom = bytes
            return (milliseconds, bytes)
        }

        let bytes = randomBytes(randomCount)
        lastMilliseconds = milliseconds
        lastRandom = bytes
        return (milliseconds, bytes)
    }

    // MARK: - UUID v7

    /// A UUID version 7: a 48-bit millisecond timestamp, then randomness,
    /// laid out as RFC 9562 specifies.
    public static func uuidV7() -> UUID {
        let (milliseconds, random) = next(randomCount: 10)
        var bytes = [UInt8](repeating: 0, count: 16)

        bytes[0] = UInt8((milliseconds >> 40) & 0xFF)
        bytes[1] = UInt8((milliseconds >> 32) & 0xFF)
        bytes[2] = UInt8((milliseconds >> 24) & 0xFF)
        bytes[3] = UInt8((milliseconds >> 16) & 0xFF)
        bytes[4] = UInt8((milliseconds >> 8) & 0xFF)
        bytes[5] = UInt8(milliseconds & 0xFF)
        for index in 0..<10 { bytes[6 + index] = random[index] }

        // Version 7 in the high nibble of byte 6, variant 10 in byte 8.
        bytes[6] = (bytes[6] & 0x0F) | 0x70
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    // MARK: - ULID

    /// Crockford's base32: no I, L, O or U, so a written-down identifier
    /// cannot be misread as a different one.
    static let crockford = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

    /// A ULID: 26 characters, the first 10 encoding the millisecond.
    ///
    /// Lexicographic order is chronological order, which is the whole point —
    /// sorting the strings sorts the events.
    public static func ulid() -> String {
        let (milliseconds, random) = next(randomCount: 10)

        var out = ""
        // 48 bits of time into 10 characters of 5 bits, most significant first.
        for position in stride(from: 45, through: 0, by: -5) {
            out.append(crockford[Int((milliseconds >> UInt64(position)) & 0x1F)])
        }
        // 80 bits of randomness into 16 characters, read as one bit stream.
        var accumulator: UInt32 = 0
        var bitsHeld = 0
        for byte in random {
            accumulator = (accumulator << 8) | UInt32(byte)
            bitsHeld += 8
            while bitsHeld >= 5 {
                let shift = UInt32(bitsHeld - 5)
                out.append(crockford[Int((accumulator >> shift) & 0x1F)])
                accumulator &= (1 << shift) - 1
                bitsHeld -= 5
            }
        }
        return out
    }

    /// The moment a ULID records, or nothing if it is not one.
    public static func date(ofULID ulid: String) -> Date? {
        let characters = Array(ulid.uppercased())
        guard characters.count == 26 else { return nil }
        var milliseconds: UInt64 = 0
        for character in characters.prefix(10) {
            guard let value = crockford.firstIndex(of: character) else { return nil }
            milliseconds = (milliseconds << 5) | UInt64(value)
        }
        return Date(timeIntervalSince1970: Double(milliseconds) / 1000)
    }

    /// The moment a UUID v7 records, or nothing if it is not one.
    public static func date(ofUUIDV7 uuid: UUID) -> Date? {
        let bytes = uuid.uuid
        guard (bytes.6 & 0xF0) == 0x70 else { return nil }
        var milliseconds: UInt64 = 0
        for byte in [bytes.0, bytes.1, bytes.2, bytes.3, bytes.4, bytes.5] {
            milliseconds = (milliseconds << 8) | UInt64(byte)
        }
        return Date(timeIntervalSince1970: Double(milliseconds) / 1000)
    }
}
