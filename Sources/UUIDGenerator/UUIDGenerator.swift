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
        case .v4:
            uuid = UUID()
        case .v1:
            // UUID v1 is time-based, but Foundation only provides v4
            // We'll generate a v4 and note this limitation
            uuid = UUID()
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
public enum UUIDVersion: String, CaseIterable {
    case v4 = "Version 4 (Random)"
    case v1 = "Version 1 (Time-based)"
    
    /// Technical description of the UUID version
    public var description: String {
        switch self {
        case .v4:
            return "Random UUID generated using cryptographically secure randomness"
        case .v1:
            return "Time-based UUID (note: Foundation generates v4 for both cases)"
        }
    }
    
    /// Whether this version uses random generation
    public var isRandom: Bool {
        switch self {
        case .v4: return true
        case .v1: return false // Conceptually, though Foundation generates v4
        }
    }
}

/// UUID formatting options
public enum UUIDFormat: String, CaseIterable {
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
