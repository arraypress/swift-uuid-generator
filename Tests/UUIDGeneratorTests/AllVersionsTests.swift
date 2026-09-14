//
//  AllVersionsTests.swift
//  UUIDGenerator
//
//  Created by David Sherlock on 2026.
//
//  The name-based versions are checked against PUBLISHED vectors rather than
//  against themselves: a deterministic generator that agrees only with its own
//  output is not interoperable, which is the entire point of v3 and v5.
//

import XCTest
@testable import UUIDGenerator

final class AllVersionsTests: XCTestCase {

    // MARK: - Name-based, against known vectors

    func testV5MatchesPublishedVectors() {
        XCTAssertEqual(
            UUIDGenerator.named("www.example.com", in: .dns, version: .v5, format: .lowercase),
            "2ed6657d-e927-568b-95e1-2665a8aea6a2"
        )
        XCTAssertEqual(
            UUIDGenerator.named("python.org", in: .dns, version: .v5, format: .lowercase),
            "886313e1-3b8a-5372-9b90-0c9aee199e5d"
        )
    }

    func testV3MatchesPublishedVectors() {
        XCTAssertEqual(
            UUIDGenerator.named("www.example.com", in: .dns, version: .v3, format: .lowercase),
            "5df41881-3aed-3515-88a7-2f4a814cf09e"
        )
        XCTAssertEqual(
            UUIDGenerator.named("python.org", in: .dns, version: .v3, format: .lowercase),
            "6fa459ea-ee8a-3ca4-894e-db77e160355e"
        )
    }

    func testNameBasedIsDeterministicAndNamespaced() {
        let first = UUIDGenerator.named("hello", in: .dns)
        XCTAssertEqual(first, UUIDGenerator.named("hello", in: .dns), "same inputs, same answer, always")
        XCTAssertNotEqual(first, UUIDGenerator.named("hello", in: .url), "the namespace has to matter")
        XCTAssertNotEqual(first, UUIDGenerator.named("goodbye", in: .dns))
    }

    // MARK: - Every version carries its own number and variant

    func testVersionAndVariantBitsForEveryVersion() {
        let made: [(UUIDVersion, UUID)] = [
            (.v1, GregorianTime.v1()),
            (.v2, GregorianTime.v2()),
            (.v3, NameBased.v3(namespace: NameBased.Namespace.dns.uuid, name: "x")),
            (.v4, UUID()),
            (.v5, NameBased.v5(namespace: NameBased.Namespace.dns.uuid, name: "x")),
            (.v6, GregorianTime.v6()),
            (.v7, TimeOrdered.uuidV7()),
            (.v8, GregorianTime.v8(from: Array(repeating: 0xAB, count: 16))),
        ]
        for (expected, uuid) in made {
            let bytes = NameBased.bytes(of: uuid)
            XCTAssertEqual(Int(bytes[6] >> 4), expected.number, "\(expected) wrote the wrong version nibble")
            XCTAssertEqual(bytes[8] & 0xC0, 0x80, "\(expected) wrote the wrong variant")
        }
    }

    // MARK: - The time-based versions round-trip their clock

    func testV1AndV6RecordTheTime() throws {
        for uuid in [GregorianTime.v1(), GregorianTime.v6()] {
            let stamped = try XCTUnwrap(UUIDGenerator.creationDate(of: uuid))
            XCTAssertEqual(stamped.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 2.0)
        }
    }

    func testV6Sorts() {
        let sixes = (0..<2_000).map { _ in GregorianTime.v6().uuidString }
        XCTAssertEqual(sixes, sixes.sorted(), "v6 must be time-ordered")
    }

    // NOT TESTED, deliberately: "v1 does not sort".
    //
    // It is true — v1 puts the fast-moving end of the clock in the first
    // bytes — but it cannot be shown in a unit test. A burst of v1s looks
    // perfectly sorted, because over microseconds only the lowest bits move
    // and they climb. The order only breaks at a field rollover, which is
    // seconds to minutes away. Asserting it over a burst would pass for
    // entirely the wrong reason, so the positive claim (v6 sorts, above) and
    // the round-trip below are what is checked instead.

    func testV1DoesNotLeakAMACAddress() {
        // The multicast bit must be set, which no real network card sets.
        let bytes = NameBased.bytes(of: GregorianTime.v1())
        XCTAssertEqual(bytes[10] & 0x01, 0x01, "the node must be marked random, not a real MAC")
    }

    // MARK: - v2 and v8

    func testV2CarriesDomainAndIdentifier() {
        let uuid = GregorianTime.v2(domain: .group, identifier: 20)
        let bytes = NameBased.bytes(of: uuid)
        XCTAssertEqual(bytes[9], GregorianTime.LocalDomain.group.rawValue)
        XCTAssertEqual(UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16
                       | UInt32(bytes[2]) << 8 | UInt32(bytes[3]), 20)
    }

    func testV8KeepsYourBytesExceptTheMarks() {
        let payload = (0..<16).map { UInt8($0) }
        let bytes = NameBased.bytes(of: GregorianTime.v8(from: payload))
        for index in 0..<16 where index != 6 && index != 8 {
            XCTAssertEqual(bytes[index], payload[index], "byte \(index) should be untouched")
        }
    }

    // MARK: - Special values

    func testNilAndMax() {
        XCTAssertEqual(UUIDGenerator.nilUUID.uuidString, "00000000-0000-0000-0000-000000000000")
        XCTAssertEqual(UUIDGenerator.maxUUID.uuidString, "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")
        XCTAssertEqual(UUIDGenerator.inspect(UUIDGenerator.nilUUID).special, "nil UUID")
        XCTAssertEqual(UUIDGenerator.inspect(UUIDGenerator.maxUUID).special, "max UUID")
    }

    // MARK: - Inspection

    func testInspectionReadsVersionAndVariant() {
        let seven = UUIDGenerator.inspect(TimeOrdered.uuidV7())
        XCTAssertEqual(seven.version, .v7)
        XCTAssertEqual(seven.variant, "RFC 9562")
        XCTAssertNotNil(seven.created)

        let four = UUIDGenerator.inspect(UUID())
        XCTAssertEqual(four.version, .v4)
        XCTAssertNil(four.created, "a v4 has no time in it to read")
    }

    func testVersionFlags() {
        XCTAssertTrue(UUIDVersion.v5.isNameBased)
        XCTAssertTrue(UUIDVersion.v7.isSortable)
        XCTAssertTrue(UUIDVersion.v6.isSortable)
        XCTAssertFalse(UUIDVersion.v1.isSortable)
        XCTAssertTrue(UUIDVersion.v4.isRandom)
        XCTAssertEqual(UUIDVersion(number: 5), .v5)
        XCTAssertNil(UUIDVersion(number: 9))
    }

    // MARK: - Formats

    func testEveryFormatIsReachable() {
        for format in UUIDFormat.allCases {
            let text = UUIDGenerator.generate(version: .v4, format: format)
            XCTAssertFalse(text.isEmpty, "\(format) produced nothing")
        }
        XCTAssertTrue(UUIDGenerator.generate(version: .v4, format: .urn).hasPrefix("urn:uuid:"))
        XCTAssertTrue(UUIDGenerator.generate(version: .v4, format: .bracketed).hasPrefix("{"))
    }
}
