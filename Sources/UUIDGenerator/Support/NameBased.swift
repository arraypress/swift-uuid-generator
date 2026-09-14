//
//  NameBased.swift
//  UUIDGenerator
//
//  Created by David Sherlock on 2026.
//

import CryptoKit
import Foundation

/// Deterministic identifiers: the same namespace and name always give the
/// same UUID, on any machine, in any year.
///
/// This is the one thing a random UUID cannot do. Deriving an id for a URL,
/// a DNS name or a file path means never storing a mapping — the id IS the
/// name, hashed.
public enum NameBased {

    /// The namespaces RFC 9562 defines.
    public enum Namespace: String, CaseIterable, Sendable {
        case dns, url, oid, x500

        public var uuid: UUID {
            switch self {
            case .dns: UUID(uuidString: "6BA7B810-9DAD-11D1-80B4-00C04FD430C8")!
            case .url: UUID(uuidString: "6BA7B811-9DAD-11D1-80B4-00C04FD430C8")!
            case .oid: UUID(uuidString: "6BA7B812-9DAD-11D1-80B4-00C04FD430C8")!
            case .x500: UUID(uuidString: "6BA7B814-9DAD-11D1-80B4-00C04FD430C8")!
            }
        }
    }

    /// Version 5 — SHA-1. The one to use unless something existing needs v3.
    public static func v5(namespace: UUID, name: String) -> UUID {
        var hasher = Insecure.SHA1()
        hasher.update(data: Data(bytes(of: namespace)))
        hasher.update(data: Data(name.utf8))
        return stamp(Array(hasher.finalize()), version: 5)
    }

    /// Version 3 — MD5. Here for compatibility with data that already uses it.
    public static func v3(namespace: UUID, name: String) -> UUID {
        var hasher = Insecure.MD5()
        hasher.update(data: Data(bytes(of: namespace)))
        hasher.update(data: Data(name.utf8))
        return stamp(Array(hasher.finalize()), version: 3)
    }

    /// The 16 bytes of a UUID, in order.
    static func bytes(of uuid: UUID) -> [UInt8] {
        let raw = uuid.uuid
        return [raw.0, raw.1, raw.2, raw.3, raw.4, raw.5, raw.6, raw.7,
                raw.8, raw.9, raw.10, raw.11, raw.12, raw.13, raw.14, raw.15]
    }

    /// Takes the first 16 bytes of a digest and writes the version and variant
    /// marks into them.
    static func stamp(_ digest: [UInt8], version: UInt8) -> UUID {
        var b = Array(digest.prefix(16))
        while b.count < 16 { b.append(0) }
        b[6] = (b[6] & 0x0F) | (version << 4)
        b[8] = (b[8] & 0x3F) | 0x80
        return UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
                           b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))
    }
}
