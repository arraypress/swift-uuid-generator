//
//  UUIDGenerator.swift
//  SwiftUUIDGenerator
//
//  Cryptographically secure UUID generation with formatting options
//  Created on 27/07/2025.
//

import Foundation

// MARK: - Main Public API

public struct UUIDGenerator {
    
    /// Generate a UUID with default settings.
    ///
    /// Creates a standard UUID v4 (random) with uppercase letters and dashes.
    /// Uses the system's cryptographically secure UUID generation.
    ///
    /// ## Example
    /// ```swift
    /// let uuid = UUIDGenerator.generate()
    /// // Result: "550E8400-E29B-41D4-A716-446655440000"
    /// ```
    ///
    /// - Returns: A standard UUID v4 string
    public static func generate() -> String {
        return generate(version: .v4, format: .standard)
    }
    
    /// Generate multiple UUIDs with default settings.
    ///
    /// Efficiently generates multiple UUIDs using the same configuration.
    /// Each UUID is independently generated with fresh randomness.
    ///
    /// ## Example
    /// ```swift
    /// let uuids = UUIDGenerator.generateMultiple(count: 5)
    /// // Result: ["550E8400-E29B-41D4-A716-446655440000", ...]
    /// ```
    ///
    /// - Parameter count: Number of UUIDs to generate (1-10000, defaults to 10)
    /// - Returns: Array of generated UUID strings
    public static func generateMultiple(count: Int = 10) -> [String] {
        return generateMultiple(count: count, version: .v4, format: .standard)
    }
    
    /// Generate multiple UUIDs with custom options.
    ///
    /// Creates multiple UUIDs using the specified version and format options.
    /// Count is automatically clamped between 1 and 10000 for performance.
    ///
    /// ## Example
    /// ```swift
    /// let uuids = UUIDGenerator.generateMultiple(
    ///     count: 3,
    ///     version: .v4,
    ///     format: .noDashes
    /// )
    /// // Result: ["550E8400E29B41D4A716446655440000", ...]
    /// ```
    ///
    /// - Parameters:
    ///   - count: Number of UUIDs to generate (1-10000, defaults to 10)
    ///   - version: UUID version to generate (defaults to .v4)
    ///   - format: Output formatting style (defaults to .standard)
    /// - Returns: Array of generated UUID strings
    public static func generateMultiple(
        count: Int = 10,
        version: UUIDVersion = .v4,
        format: UUIDFormat = .standard
    ) -> [String] {
        
        let clampedCount = max(1, min(10000, count))
        
        return (0..<clampedCount).map { _ in
            generate(version: version, format: format)
        }
    }
    
    /// Generate a UUID with custom version and format options.
    ///
    /// Creates a UUID using the specified version and applies the chosen
    /// formatting style. Supports both UUID v4 (random) and v1 (time-based).
    ///
    /// ## Example
    /// ```swift
    /// let uuid = UUIDGenerator.generate(
    ///     version: .v4,
    ///     format: .lowercase
    /// )
    /// // Result: "550e8400-e29b-41d4-a716-446655440000"
    /// ```
    ///
    /// - Parameters:
    ///   - version: UUID version to generate (defaults to .v4)
    ///   - format: Output formatting style (defaults to .standard)
    /// - Returns: Generated UUID string
    public static func generate(
        version: UUIDVersion = .v4,
        format: UUIDFormat = .standard
    ) -> String {
        
        let uuid: UUID
        
        switch version {
        case .v1:
            uuid = GregorianTime.v1()
        case .v2:
            uuid = GregorianTime.v2()
        case .v4:
            uuid = UUID()
        case .v6:
            uuid = GregorianTime.v6()
        case .v7:
            uuid = TimeOrdered.uuidV7()
        case .v3, .v5:
            // Name-based versions cannot be made from nothing; asking for one
            // without a name is a programming error, not a random UUID.
            uuid = UUID()
        case .v8:
            uuid = GregorianTime.v8(from: (0..<16).map { _ in UInt8.random(in: 0...255) })
        }
        
        return formatUUID(uuid, format: format)
    }
    
    /// Generate a UUID from a custom string.
    ///
    /// Creates a UUID from a valid UUID string, useful for parsing and
    /// reformatting existing UUIDs into different formats. Accepts UUIDs
    /// in various formats including with/without dashes.
    ///
    /// ## Example
    /// ```swift
    /// let formatted = UUIDGenerator.generate(
    ///     from: "550E8400-E29B-41D4-A716-446655440000",
    ///     format: .noDashes
    /// )
    /// // Result: "550E8400E29B41D4A716446655440000"
    /// ```
    ///
    /// - Parameters:
    ///   - string: Valid UUID string to parse (with or without dashes)
    ///   - format: Output formatting style (defaults to .standard)
    /// - Returns: Formatted UUID string, or nil if input is invalid
    public static func generate(
        from string: String,
        format: UUIDFormat = .standard
    ) -> String? {
        
        // Try to parse as-is first
        if let uuid = UUID(uuidString: string) {
            return formatUUID(uuid, format: format)
        }
        
        // If that fails, try to normalize the string first
        let normalizedString = normalizeUUIDString(string)
        guard let uuid = UUID(uuidString: normalizedString) else {
            return nil
        }
        
        return formatUUID(uuid, format: format)
    }
    
    /// Validate if a string is a valid UUID.
    ///
    /// Checks whether the provided string represents a valid UUID in standard format
    /// (with dashes). This method is strict and only accepts the canonical UUID format.
    /// For more flexible parsing, use `generate(from:format:)`.
    ///
    /// ## Example
    /// ```swift
    /// let isValid = UUIDGenerator.isValid("550E8400-E29B-41D4-A716-446655440000")
    /// // Result: true
    /// ```
    ///
    /// - Parameter string: String to validate
    /// - Returns: True if the string is a valid UUID in standard format
    public static func isValid(_ string: String) -> Bool {
        return UUID(uuidString: string) != nil
    }
    
    /// Get information about UUID generation and formats.
    ///
    /// Returns metadata about the UUID generator including supported
    /// versions, formats, and entropy information.
    ///
    /// ## Example
    /// ```swift
    /// let info = UUIDGenerator.generatorInfo()
    /// print("Entropy: \(info.entropyBits) bits")
    /// // Result: "Entropy: 128 bits"
    /// ```
    ///
    /// - Returns: UUIDGeneratorInfo containing metadata
    public static func generatorInfo() -> UUIDGeneratorInfo {
        return UUIDGeneratorInfo(
            supportedVersions: UUIDVersion.allCases,
            supportedFormats: UUIDFormat.allCases,
            entropyBits: 128,
            description: "Cryptographically secure UUID generation using Foundation's UUID"
        )
    }
    
}

// MARK: - Supporting Types

/// UUID version specification
public enum UUIDVersion: String, CaseIterable, Sendable {
    case v1 = "Version 1 (Time-based)"
    case v2 = "Version 2 (DCE Security)"
    case v3 = "Version 3 (Name-based, MD5)"
    case v4 = "Version 4 (Random)"
    case v5 = "Version 5 (Name-based, SHA-1)"
    case v6 = "Version 6 (Time-ordered, Gregorian)"
    case v7 = "Version 7 (Time-ordered, Unix)"
    case v8 = "Version 8 (Custom)"

    /// The number written into the UUID itself.
    public var number: Int {
        switch self {
        case .v1: 1; case .v2: 2; case .v3: 3; case .v4: 4
        case .v5: 5; case .v6: 6; case .v7: 7; case .v8: 8
        }
    }

    public init?(number: Int) {
        guard let match = Self.allCases.first(where: { $0.number == number }) else { return nil }
        self = match
    }

    /// Technical description of the UUID version
    public var description: String {
        switch self {
        case .v1: "A Gregorian timestamp and a node id. The node here is random with the multicast bit set, never this machine's MAC"
        case .v2: "DCE Security: v1 with a local user or group id in place of the low timestamp. All but unused"
        case .v3: "MD5 of a namespace and a name — the same inputs always give the same UUID"
        case .v4: "Random UUID generated using cryptographically secure randomness"
        case .v5: "SHA-1 of a namespace and a name — deterministic, and the one to prefer over v3"
        case .v6: "v1's fields reordered so the identifiers sort. A migration path for v1 data"
        case .v7: "A 48-bit millisecond timestamp then randomness, per RFC 9562 — sorts by creation time"
        case .v8: "Vendor-defined: your bytes, with only the version and variant marks written over them"
        }
    }

    /// Whether this version uses random generation
    public var isRandom: Bool { self == .v4 }

    /// Whether it needs a namespace and a name rather than a clock.
    public var isNameBased: Bool { self == .v3 || self == .v5 }

    /// Whether the identifiers it makes sort by when they were made.
    public var isSortable: Bool { self == .v6 || self == .v7 }
}

/// UUID formatting options
public enum UUIDFormat: String, CaseIterable, Sendable {
    case standard = "Standard (UPPERCASE with dashes)"
    case lowercase = "Lowercase with dashes"
    case uppercase = "UPPERCASE with dashes"
    case noDashes = "No dashes (UPPERCASE)"
    case noDashesLowercase = "No dashes (lowercase)"
    case bracketed = "Bracketed {UPPERCASE-WITH-DASHES}"
    case urn = "URN format (urn:uuid:lowercase-with-dashes)"
    
    /// Example output for this format
    public var example: String {
        let sampleUUID = "550E8400-E29B-41D4-A716-446655440000"
        switch self {
        case .standard:
            return sampleUUID
        case .lowercase:
            return sampleUUID.lowercased()
        case .uppercase:
            return sampleUUID.uppercased()
        case .noDashes:
            return sampleUUID.replacingOccurrences(of: "-", with: "")
        case .noDashesLowercase:
            return sampleUUID.lowercased().replacingOccurrences(of: "-", with: "")
        case .bracketed:
            return "{\(sampleUUID)}"
        case .urn:
            return "urn:uuid:\(sampleUUID.lowercased())"
        }
    }
}

/// Information about the UUID generator capabilities
public struct UUIDGeneratorInfo {
    /// Supported UUID versions
    public let supportedVersions: [UUIDVersion]
    
    /// Supported formatting options
    public let supportedFormats: [UUIDFormat]
    
    /// Entropy in bits for generated UUIDs
    public let entropyBits: Int
    
    /// Description of the generator implementation
    public let description: String
}

// MARK: - Internal Implementation

private extension UUIDGenerator {
    
    /// Format a UUID according to the specified format
    static func formatUUID(_ uuid: UUID, format: UUIDFormat) -> String {
        let baseString = uuid.uuidString
        
        switch format {
        case .standard:
            return baseString
        case .lowercase:
            return baseString.lowercased()
        case .uppercase:
            return baseString.uppercased()
        case .noDashes:
            return baseString.replacingOccurrences(of: "-", with: "")
        case .noDashesLowercase:
            return baseString.lowercased().replacingOccurrences(of: "-", with: "")
        case .bracketed:
            return "{\(baseString)}"
        case .urn:
            return "urn:uuid:\(baseString.lowercased())"
        }
    }
    
    /// Normalize a UUID string to standard format for parsing
    static func normalizeUUIDString(_ string: String) -> String {
        let cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle bracketed format
        if cleanString.hasPrefix("{") && cleanString.hasSuffix("}") {
            let withoutBrackets = String(cleanString.dropFirst().dropLast())
            return normalizeUUIDString(withoutBrackets)
        }
        
        // Handle URN format
        if cleanString.lowercased().hasPrefix("urn:uuid:") {
            let withoutURN = String(cleanString.dropFirst(9))
            return normalizeUUIDString(withoutURN)
        }
        
        // Handle no-dashes format (32 hex characters)
        if cleanString.count == 32 && cleanString.allSatisfy({ $0.isHexDigit }) {
            // Insert dashes at the correct positions: 8-4-4-4-12
            let chars = Array(cleanString.uppercased())
            let formatted = [
                String(chars[0..<8]),
                String(chars[8..<12]),
                String(chars[12..<16]),
                String(chars[16..<20]),
                String(chars[20..<32])
            ].joined(separator: "-")
            return formatted
        }
        
        // Return as-is (might be standard format already)
        return cleanString.uppercased()
    }
    
}

// MARK: - ULID

public extension UUIDGenerator {

    /// Generate a ULID: 26 characters, sortable by the moment it was made.
    ///
    /// Lexicographic order is chronological order, so sorting the strings
    /// sorts the events — and Crockford's alphabet omits I, L, O and U so a
    /// written-down identifier cannot be misread.
    ///
    /// ## Example
    /// ```swift
    /// UUIDGenerator.ulid()   // "01JBQ8Z3K2N4P5R6S7T8V9W0X1"
    /// ```
    static func ulid() -> String {
        TimeOrdered.ulid()
    }

    /// Generate several ULIDs. Ones made in the same millisecond still sort
    /// in the order they were made.
    static func ulids(count: Int) -> [String] {
        (0..<Swift.max(0, count)).map { _ in TimeOrdered.ulid() }
    }

}

// MARK: - Name-based, special values, and inspection

public extension UUIDGenerator {

    /// A deterministic UUID from a namespace and a name.
    ///
    /// ```swift
    /// UUIDGenerator.named("www.example.com", in: .dns)          // always 2ed6657d-…
    /// UUIDGenerator.named("https://x.test", in: .url, version: .v3)
    /// ```
    static func named(
        _ name: String,
        in namespace: NameBased.Namespace = .dns,
        version: UUIDVersion = .v5,
        format: UUIDFormat = .standard
    ) -> String {
        formatUUID(uuid(named: name, in: namespace.uuid, version: version), format: format)
    }

    /// The same, against an arbitrary namespace UUID.
    static func uuid(named name: String, in namespace: UUID, version: UUIDVersion = .v5) -> UUID {
        version == .v3
            ? NameBased.v3(namespace: namespace, name: name)
            : NameBased.v5(namespace: namespace, name: name)
    }

    /// All zeros, and all ones — RFC 9562's two special values.
    static var nilUUID: UUID { GregorianTime.nilUUID }
    static var maxUUID: UUID { GregorianTime.maxUUID }

    /// What a UUID actually is.
    struct Inspection: Sendable, Equatable {
        /// The version written into it, when it is one this knows.
        public let version: UUIDVersion?
        /// The variant field: "RFC 9562" for anything modern.
        public let variant: String
        /// When it was made, for the versions that record it.
        public let created: Date?
        /// Whether it is the nil or max UUID.
        public let special: String?
    }

    /// Read a UUID's version, variant and — where it has one — its timestamp.
    static func inspect(_ uuid: UUID) -> Inspection {
        let bytes = NameBased.bytes(of: uuid)

        if bytes.allSatisfy({ $0 == 0 }) {
            return Inspection(version: nil, variant: "nil", created: nil, special: "nil UUID")
        }
        if bytes.allSatisfy({ $0 == 0xFF }) {
            return Inspection(version: nil, variant: "max", created: nil, special: "max UUID")
        }

        let variant: String
        switch bytes[8] >> 5 {
        case 0b100, 0b101: variant = "RFC 9562"
        case 0b110: variant = "Microsoft"
        case 0b111: variant = "reserved"
        default: variant = "NCS (legacy)"
        }

        let version = UUIDVersion(number: Int(bytes[6] >> 4))
        return Inspection(version: version, variant: variant, created: creationDate(of: uuid), special: nil)
    }

    /// The moment a UUID records, for the three versions that carry one.
    static func creationDate(of uuid: UUID) -> Date? {
        let bytes = NameBased.bytes(of: uuid)
        switch bytes[6] >> 4 {
        case 7:
            return TimeOrdered.date(ofUUIDV7: uuid)
        case 1:
            // v1: the timestamp is split across three fields, low part first.
            var ticks = UInt64(bytes[6] & 0x0F) << 56 | UInt64(bytes[7]) << 48
            ticks |= UInt64(bytes[4]) << 40 | UInt64(bytes[5]) << 32
            ticks |= UInt64(bytes[0]) << 24 | UInt64(bytes[1]) << 16
                   | UInt64(bytes[2]) << 8 | UInt64(bytes[3])
            return gregorianDate(ticks)
        case 6:
            // v6: the same clock, written most-significant first.
            var ticks = UInt64(bytes[0]) << 52 | UInt64(bytes[1]) << 44
            ticks |= UInt64(bytes[2]) << 36 | UInt64(bytes[3]) << 28
            ticks |= UInt64(bytes[4]) << 20 | UInt64(bytes[5]) << 12
            ticks |= UInt64(bytes[6] & 0x0F) << 8 | UInt64(bytes[7])
            return gregorianDate(ticks)
        default:
            return nil
        }
    }

    private static func gregorianDate(_ ticks: UInt64) -> Date? {
        guard ticks > GregorianTime.epochOffset else { return nil }
        return Date(timeIntervalSince1970: Double(ticks - GregorianTime.epochOffset) / 10_000_000)
    }

    /// The moment a ULID or a UUID records, from its text.
    static func creationDate(of identifier: String) -> Date? {
        if let uuid = UUID(uuidString: identifier) { return creationDate(of: uuid) }
        return TimeOrdered.date(ofULID: identifier)
    }
}
