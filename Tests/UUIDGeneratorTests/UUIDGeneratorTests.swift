//
//  UUIDGeneratorTests.swift
//  SwiftUUIDGenerator
//
//  Created by David Sherlock on 27/07/2025.
//


//
//  UUIDGeneratorTests.swift
//  SwiftUUIDGenerator
//
//  Comprehensive test suite for UUID generation
//  Created on 27/07/2025.
//

import XCTest
@testable import UUIDGenerator

final class UUIDGeneratorTests: XCTestCase {
    
    // MARK: - Basic Generation Tests
    
    func testDefaultGeneration() {
        let uuid = UUIDGenerator.generate()
        
        // Should be a valid UUID format
        XCTAssertTrue(UUIDGenerator.isValid(uuid), "Generated UUID should be valid")
        
        // Should be standard format (uppercase with dashes)
        XCTAssertTrue(uuid.contains("-"), "Default UUID should contain dashes")
        XCTAssertEqual(uuid, uuid.uppercased(), "Default UUID should be uppercase")
        XCTAssertEqual(uuid.count, 36, "Standard UUID should be 36 characters")
    }
    
    func testUUIDValidation() {
        // Valid UUIDs
        let validUUIDs = [
            "550E8400-E29B-41D4-A716-446655440000",
            "550e8400-e29b-41d4-a716-446655440000",
            "00000000-0000-0000-0000-000000000000",
            "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"
        ]
        
        for uuid in validUUIDs {
            XCTAssertTrue(UUIDGenerator.isValid(uuid), "Should recognize '\(uuid)' as valid")
        }
        
        // Invalid UUIDs
        let invalidUUIDs = [
            "not-a-uuid",
            "550E8400-E29B-41D4-A716",
            "550E8400-E29B-41D4-A716-446655440000-EXTRA",
            "",
            "550G8400-E29B-41D4-A716-446655440000", // Invalid hex character
            "550E8400E29B41D4A716446655440000" // No dashes (Foundation is strict)
        ]
        
        for uuid in invalidUUIDs {
            XCTAssertFalse(UUIDGenerator.isValid(uuid), "Should recognize '\(uuid)' as invalid")
        }
    }
    
    func testVersionsGeneration() {
        // Test v4 generation
        let v4UUID = UUIDGenerator.generate(version: .v4)
        XCTAssertTrue(UUIDGenerator.isValid(v4UUID), "v4 UUID should be valid")
        
        // v7 is a real version 7, not a v4 wearing a label.
        let v7UUID = UUIDGenerator.generate(version: .v7)
        XCTAssertTrue(UUIDGenerator.isValid(v7UUID), "v7 UUID should be valid")
        XCTAssertNotNil(UUIDGenerator.creationDate(of: v7UUID), "a v7 carries the time it was made")
    }
    
    // MARK: - Format Tests
    
    func testStandardFormat() {
        let uuid = UUIDGenerator.generate(format: .standard)
        
        XCTAssertTrue(uuid.contains("-"), "Standard format should contain dashes")
        XCTAssertEqual(uuid, uuid.uppercased(), "Standard format should be uppercase")
        XCTAssertEqual(uuid.count, 36, "Standard format should be 36 characters")
        XCTAssertTrue(UUIDGenerator.isValid(uuid), "Standard format should be valid")
    }
    
    func testLowercaseFormat() {
        let uuid = UUIDGenerator.generate(format: .lowercase)
        
        XCTAssertTrue(uuid.contains("-"), "Lowercase format should contain dashes")
        XCTAssertEqual(uuid, uuid.lowercased(), "Lowercase format should be lowercase")
        XCTAssertEqual(uuid.count, 36, "Lowercase format should be 36 characters")
        XCTAssertTrue(UUIDGenerator.isValid(uuid), "Lowercase format should be valid")
    }
    
    func testUppercaseFormat() {
        let uuid = UUIDGenerator.generate(format: .uppercase)
        
        XCTAssertTrue(uuid.contains("-"), "Uppercase format should contain dashes")
        XCTAssertEqual(uuid, uuid.uppercased(), "Uppercase format should be uppercase")
        XCTAssertEqual(uuid.count, 36, "Uppercase format should be 36 characters")
        XCTAssertTrue(UUIDGenerator.isValid(uuid), "Uppercase format should be valid")
    }
    
    func testNoDashesFormat() {
        let uuid = UUIDGenerator.generate(format: .noDashes)
        
        XCTAssertFalse(uuid.contains("-"), "No dashes format should not contain dashes")
        XCTAssertEqual(uuid, uuid.uppercased(), "No dashes format should be uppercase")
        XCTAssertEqual(uuid.count, 32, "No dashes format should be 32 characters")
    }
    
    func testNoDashesLowercaseFormat() {
        let uuid = UUIDGenerator.generate(format: .noDashesLowercase)
        
        XCTAssertFalse(uuid.contains("-"), "No dashes lowercase should not contain dashes")
        XCTAssertEqual(uuid, uuid.lowercased(), "No dashes lowercase should be lowercase")
        XCTAssertEqual(uuid.count, 32, "No dashes lowercase should be 32 characters")
    }
    
    func testBracketedFormat() {
        let uuid = UUIDGenerator.generate(format: .bracketed)
        
        XCTAssertTrue(uuid.hasPrefix("{"), "Bracketed format should start with {")
        XCTAssertTrue(uuid.hasSuffix("}"), "Bracketed format should end with }")
        XCTAssertEqual(uuid.count, 38, "Bracketed format should be 38 characters")
        
        // Remove brackets and validate inner UUID
        let innerUUID = String(uuid.dropFirst().dropLast())
        XCTAssertTrue(UUIDGenerator.isValid(innerUUID), "Inner UUID should be valid")
    }
    
    func testURNFormat() {
        let uuid = UUIDGenerator.generate(format: .urn)
        
        XCTAssertTrue(uuid.hasPrefix("urn:uuid:"), "URN format should start with urn:uuid:")
        XCTAssertEqual(uuid.count, 45, "URN format should be 45 characters")
        
        // Remove URN prefix and validate inner UUID
        let innerUUID = String(uuid.dropFirst(9)) // Remove "urn:uuid:"
        XCTAssertTrue(UUIDGenerator.isValid(innerUUID), "Inner UUID should be valid")
        XCTAssertEqual(innerUUID, innerUUID.lowercased(), "URN inner UUID should be lowercase")
    }
    
    // MARK: - Multiple Generation Tests
    
    func testGenerateMultipleDefault() {
        let uuids = UUIDGenerator.generateMultiple(count: 5)
        
        XCTAssertEqual(uuids.count, 5, "Should generate 5 UUIDs")
        
        // All UUIDs should be valid and unique
        for uuid in uuids {
            XCTAssertTrue(UUIDGenerator.isValid(uuid), "Each UUID should be valid")
        }
        
        let uniqueUUIDs = Set(uuids)
        XCTAssertEqual(uniqueUUIDs.count, 5, "All UUIDs should be unique")
    }
    
    func testGenerateMultipleCustom() {
        let uuids = UUIDGenerator.generateMultiple(
            count: 3,
            version: .v4,
            format: .noDashes
        )
        
        XCTAssertEqual(uuids.count, 3, "Should generate 3 UUIDs")
        
        for uuid in uuids {
            XCTAssertFalse(uuid.contains("-"), "Should not contain dashes")
            XCTAssertEqual(uuid.count, 32, "Should be 32 characters")
        }
        
        // Should be unique
        let uniqueUUIDs = Set(uuids)
        XCTAssertEqual(uniqueUUIDs.count, 3, "All UUIDs should be unique")
    }
    
    func testGenerateMultipleCountBounds() {
        // Test minimum bound (should clamp to 1)
        let tooFew = UUIDGenerator.generateMultiple(count: 0)
        XCTAssertEqual(tooFew.count, 1, "Count should be clamped to minimum of 1")
        
        // Test maximum bound (should clamp to 10000)
        let tooMany = UUIDGenerator.generateMultiple(count: 15000)
        XCTAssertEqual(tooMany.count, 10000, "Count should be clamped to maximum of 10000")
        
        // Test negative count (should clamp to 1)
        let negative = UUIDGenerator.generateMultiple(count: -5)
        XCTAssertEqual(negative.count, 1, "Negative count should be clamped to 1")
    }
    
    // MARK: - Parse and Format Tests
    
    func testGenerateFromString() {
        let originalUUID = "550E8400-E29B-41D4-A716-446655440000"
        
        // Test valid conversion
        let converted = UUIDGenerator.generate(from: originalUUID, format: .noDashes)
        XCTAssertNotNil(converted, "Should successfully convert valid UUID")
        XCTAssertEqual(converted, "550E8400E29B41D4A716446655440000", "Should format correctly")
        
        // Test invalid input
        let invalid = UUIDGenerator.generate(from: "not-a-uuid", format: .standard)
        XCTAssertNil(invalid, "Should return nil for invalid UUID string")
        
        // Test roundtrip conversion
        let roundtrip = UUIDGenerator.generate(from: converted!, format: .standard)
        XCTAssertEqual(roundtrip, originalUUID, "Should convert back to original format")
    }
    
    func testFormatExamples() {
        // Test that format examples are consistent
        for format in UUIDFormat.allCases {
            let example = format.example
            
            switch format {
            case .standard, .lowercase, .uppercase:
                XCTAssertEqual(example.count, 36, "\(format) example should be 36 characters")
                XCTAssertTrue(example.contains("-"), "\(format) example should contain dashes")
                
            case .noDashes, .noDashesLowercase:
                XCTAssertEqual(example.count, 32, "\(format) example should be 32 characters")
                XCTAssertFalse(example.contains("-"), "\(format) example should not contain dashes")
                
            case .bracketed:
                XCTAssertEqual(example.count, 38, "\(format) example should be 38 characters")
                XCTAssertTrue(example.hasPrefix("{") && example.hasSuffix("}"), "\(format) example should have brackets")
                
            case .urn:
                XCTAssertEqual(example.count, 45, "\(format) example should be 45 characters")
                XCTAssertTrue(example.hasPrefix("urn:uuid:"), "\(format) example should have URN prefix")
            }
        }
    }
    
    // MARK: - Generator Info Tests
    
    func testGeneratorInfo() {
        let info = UUIDGenerator.generatorInfo()
        
        XCTAssertFalse(info.supportedVersions.isEmpty, "Should support at least one version")
        XCTAssertTrue(info.supportedVersions.contains(.v4), "Should support v4")
        XCTAssertFalse(info.supportedFormats.isEmpty, "Should support at least one format")
        XCTAssertEqual(info.entropyBits, 128, "UUIDs should have 128 bits of entropy")
        XCTAssertFalse(info.description.isEmpty, "Should have a description")
    }
    
    func testVersionDescriptions() {
        for version in UUIDVersion.allCases {
            XCTAssertFalse(version.description.isEmpty, "Version \(version) should have description")
            
            switch version {
            case .v4:
                XCTAssertTrue(version.isRandom, "v4 should be random")
            default:
                XCTAssertFalse(version.isRandom, "\(version) is not purely random")
            }
        }
    }
    
    // MARK: - Uniqueness and Randomness Tests
    
    func testUniqueness() {
        let count = 1000
        let uuids = UUIDGenerator.generateMultiple(count: count)
        let uniqueUUIDs = Set(uuids)
        
        XCTAssertEqual(uniqueUUIDs.count, count, "All \(count) UUIDs should be unique")
    }
    
    func testRandomnessDistribution() {
        // Generate many UUIDs and check that different characters appear
        let uuids = UUIDGenerator.generateMultiple(count: 100, format: .noDashes)
        let allCharacters = uuids.joined()
        
        // Should contain a variety of hex characters
        let hexChars = Set("0123456789ABCDEF")
        let foundChars = Set(allCharacters)
        
        // Should find most hex characters (allowing for some randomness)
        let intersection = hexChars.intersection(foundChars)
        XCTAssertGreaterThan(intersection.count, 10, "Should use most hex characters")
    }
    
    // MARK: - Performance Tests
    
    func testSingleGenerationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = UUIDGenerator.generate()
            }
        }
    }
    
    func testBulkGenerationPerformance() {
        measure {
            _ = UUIDGenerator.generateMultiple(count: 1000)
        }
    }
    
    func testFormattingPerformance() {
        let baseUUID = "550E8400-E29B-41D4-A716-446655440000"
        
        measure {
            for format in UUIDFormat.allCases {
                for _ in 0..<100 {
                    _ = UUIDGenerator.generate(from: baseUUID, format: format)
                }
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyStringValidation() {
        XCTAssertFalse(UUIDGenerator.isValid(""), "Empty string should not be valid UUID")
    }
    
    func testWhitespaceValidation() {
        XCTAssertFalse(UUIDGenerator.isValid("  "), "Whitespace should not be valid UUID")
        XCTAssertFalse(UUIDGenerator.isValid(" 550E8400-E29B-41D4-A716-446655440000 "), "UUID with whitespace should not be valid")
    }
    
    func testCaseInsensitiveValidation() {
        let mixedCase = "550e8400-E29B-41d4-A716-446655440000"
        XCTAssertTrue(UUIDGenerator.isValid(mixedCase), "Mixed case UUID should be valid")
    }
    
    func testAllZerosUUID() {
        let allZeros = "00000000-0000-0000-0000-000000000000"
        XCTAssertTrue(UUIDGenerator.isValid(allZeros), "All zeros UUID should be valid")
        
        let formatted = UUIDGenerator.generate(from: allZeros, format: .noDashes)
        XCTAssertEqual(formatted, "00000000000000000000000000000000", "Should format all zeros correctly")
    }
    
    func testAllFsUUID() {
        let allFs = "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"
        XCTAssertTrue(UUIDGenerator.isValid(allFs), "All Fs UUID should be valid")
        
        let formatted = UUIDGenerator.generate(from: allFs, format: .lowercase)
        XCTAssertEqual(formatted, "ffffffff-ffff-ffff-ffff-ffffffffffff", "Should format all Fs correctly")
    }
}
