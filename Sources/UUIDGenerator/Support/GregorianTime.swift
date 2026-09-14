//
//  GregorianTime.swift
//  UUIDGenerator
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The versions built on the Gregorian clock, plus the two special values.
///
/// v1 and v6 count 100-nanosecond intervals since **15 October 1582** — the
/// day the Gregorian calendar began — which is why they need their own epoch
/// rather than sharing v7's Unix milliseconds.
public enum GregorianTime {

    /// 100-nanosecond intervals between 1582-10-15 and 1970-01-01.
    static let epochOffset: UInt64 = 122_192_928_000_000_000

    private static let lock = NSLock()
    nonisolated(unsafe) private static var lastTimestamp: UInt64 = 0
    nonisolated(unsafe) private static var clockSequence: UInt16 = UInt16.random(in: 0...0x3FFF)

    /// A node identifier that is deliberately NOT this machine's MAC address.
    ///
    /// v1's original design put the real MAC in every identifier, which is
    /// exactly why v1 fell out of favour. RFC 9562 permits a random node
    /// instead, provided the multicast bit is set so it can never collide
    /// with a real card. That is what this does — the shape of a v1 without
    /// the tracking.
    nonisolated(unsafe) private static let node: [UInt8] = {
        var bytes = (0..<6).map { _ in UInt8.random(in: 0...255) }
        bytes[0] |= 0x01
        return bytes
    }()

    /// The current timestamp, and a clock sequence that advances if the clock
    /// did not — so two identifiers made in the same tick still differ.
    static func tick() -> (timestamp: UInt64, clockSequence: UInt16) {
        lock.lock()
        defer { lock.unlock() }
        let now = UInt64((Date().timeIntervalSince1970 * 10_000_000).rounded(.down)) + epochOffset
        if now <= lastTimestamp {
            clockSequence = (clockSequence &+ 1) & 0x3FFF
            lastTimestamp = lastTimestamp &+ 1
        } else {
            lastTimestamp = now
        }
        return (lastTimestamp, clockSequence)
    }

    private static func assemble(_ bytes: [UInt8]) -> UUID {
        UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                    bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }

    /// Version 1 — the original time-based layout.
    public static func v1() -> UUID {
        let (timestamp, sequence) = tick()
        var b = [UInt8](repeating: 0, count: 16)

        // time_low, time_mid, then the high 12 bits beside the version.
        b[0] = UInt8((timestamp >> 24) & 0xFF); b[1] = UInt8((timestamp >> 16) & 0xFF)
        b[2] = UInt8((timestamp >> 8) & 0xFF);  b[3] = UInt8(timestamp & 0xFF)
        b[4] = UInt8((timestamp >> 40) & 0xFF); b[5] = UInt8((timestamp >> 32) & 0xFF)
        b[6] = UInt8(((timestamp >> 56) & 0x0F) | 0x10)
        b[7] = UInt8((timestamp >> 48) & 0xFF)
        b[8] = UInt8(((sequence >> 8) & 0x3F) | 0x80)
        b[9] = UInt8(sequence & 0xFF)
        for index in 0..<6 { b[10 + index] = node[index] }
        return assemble(b)
    }

    /// Version 6 — v1's fields with the timestamp put back in order, so the
    /// identifiers sort. A migration path for systems already holding v1;
    /// anything new should use v7.
    public static func v6() -> UUID {
        let (timestamp, sequence) = tick()
        var b = [UInt8](repeating: 0, count: 16)

        // The whole point: most-significant timestamp bits first.
        b[0] = UInt8((timestamp >> 52) & 0xFF); b[1] = UInt8((timestamp >> 44) & 0xFF)
        b[2] = UInt8((timestamp >> 36) & 0xFF); b[3] = UInt8((timestamp >> 28) & 0xFF)
        b[4] = UInt8((timestamp >> 20) & 0xFF); b[5] = UInt8((timestamp >> 12) & 0xFF)
        b[6] = UInt8(0x60 | UInt8((timestamp >> 8) & 0x0F))
        b[7] = UInt8(timestamp & 0xFF)
        b[8] = UInt8(((sequence >> 8) & 0x3F) | 0x80)
        b[9] = UInt8(sequence & 0xFF)
        for index in 0..<6 { b[10 + index] = node[index] }
        return assemble(b)
    }

    /// The local domains DCE Security identifies.
    public enum LocalDomain: UInt8, Sendable, CaseIterable {
        case person = 0, group = 1, organization = 2
    }

    /// Version 2 — DCE Security.
    ///
    /// v1 with the low timestamp replaced by a local identifier and the low
    /// clock sequence by a domain. It is all but unused, and its 32-bit
    /// identifier plus coarse clock make collisions far likelier than any
    /// other version. Here for completeness; do not pick it for new work.
    public static func v2(domain: LocalDomain = .person, identifier: UInt32? = nil) -> UUID {
        let localID = identifier ?? UInt32(getuid())
        var b = NameBased.bytes(of: v1())
        b[0] = UInt8((localID >> 24) & 0xFF); b[1] = UInt8((localID >> 16) & 0xFF)
        b[2] = UInt8((localID >> 8) & 0xFF);  b[3] = UInt8(localID & 0xFF)
        b[6] = (b[6] & 0x0F) | 0x20
        b[9] = domain.rawValue
        return assemble(b)
    }

    /// Version 8 — free-form.
    ///
    /// RFC 9562 leaves every bit except the version and variant marks to the
    /// implementer, so this takes your 16 bytes and stamps those two fields.
    /// There is no "generate a v8": without your data it would just be a v4
    /// wearing a different number.
    public static func v8(from data: [UInt8]) -> UUID {
        var b = Array(data.prefix(16))
        while b.count < 16 { b.append(0) }
        b[6] = (b[6] & 0x0F) | 0x80
        b[8] = (b[8] & 0x3F) | 0x80
        return assemble(b)
    }

    /// All zeros — the absence of a UUID, spelled as one.
    public static let nilUUID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

    /// All ones. RFC 9562's upper bound, useful as a sort sentinel.
    public static let maxUUID = UUID(uuid: (0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                                            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF))
}
