//
//  TimeOrderedTests.swift
//  UUIDGenerator
//
//  Created by David Sherlock on 2026.
//
//  The claim these types make is that sorting them sorts the events. That is
//  only true if identifiers made inside one millisecond are monotonic, so
//  that is what most of this checks.
//

import XCTest
@testable import UUIDGenerator

final class TimeOrderedTests: XCTestCase {

    // MARK: - UUID v7 layout

    func testVersionAndVariantBitsAreCorrect() {
        for _ in 0..<200 {
            let bytes = TimeOrdered.uuidV7().uuid
            XCTAssertEqual(bytes.6 & 0xF0, 0x70, "version nibble must be 7")
            XCTAssertEqual(bytes.8 & 0xC0, 0x80, "variant must be RFC 4122 (10)")
        }
    }

    func testV7CarriesTheCurrentTime() throws {
        let uuid = TimeOrdered.uuidV7()
        let stamped = try XCTUnwrap(TimeOrdered.date(ofUUIDV7: uuid))
        XCTAssertEqual(stamped.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 2.0)
    }

    func testV4HasNoTimestampToRead() {
        // A v4 is random; reporting a date for one would be inventing it.
        XCTAssertNil(TimeOrdered.date(ofUUIDV7: UUID()))
    }

    // MARK: - Sortability, which is the entire point

    func testV7sMadeInTheSameMillisecondStillSort() {
        // Generated as fast as possible, so most land in one millisecond.
        let ids = (0..<5_000).map { _ in TimeOrdered.uuidV7().uuidString }
        XCTAssertEqual(ids, ids.sorted(), "v7 must be monotonic within a millisecond")
        XCTAssertEqual(Set(ids).count, ids.count, "and must not repeat")
    }

    func testULIDsMadeInTheSameMillisecondStillSort() {
        let ids = (0..<5_000).map { _ in TimeOrdered.ulid() }
        XCTAssertEqual(ids, ids.sorted(), "ULIDs must be monotonic within a millisecond")
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testV4DoesNotSort() {
        // The control. If this ever passes, the test above proves nothing.
        let ids = (0..<500).map { _ in UUID().uuidString }
        XCTAssertNotEqual(ids, ids.sorted(), "a v4 is random — that is the problem v7 solves")
    }

    // MARK: - ULID shape

    func testULIDIsTwentySixCrockfordCharacters() {
        let allowed = Set("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
        for _ in 0..<200 {
            let id = TimeOrdered.ulid()
            XCTAssertEqual(id.count, 26)
            XCTAssertTrue(id.allSatisfy { allowed.contains($0) }, "\(id) left the alphabet")
            // I, L, O and U are excluded so a written id cannot be misread.
            XCTAssertFalse(id.contains("I") || id.contains("L") || id.contains("O") || id.contains("U"))
        }
    }

    func testULIDRoundTripsItsTimestamp() throws {
        let id = TimeOrdered.ulid()
        let stamped = try XCTUnwrap(TimeOrdered.date(ofULID: id))
        XCTAssertEqual(stamped.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 2.0)
    }

    func testMalformedULIDReadsAsNothing() {
        XCTAssertNil(TimeOrdered.date(ofULID: "too-short"))
        XCTAssertNil(TimeOrdered.date(ofULID: String(repeating: "U", count: 26)), "U is not in the alphabet")
    }

    // MARK: - Public surface

    func testPublicGeneratorsAgree() throws {
        let v7 = UUIDGenerator.generate(version: .v7, format: .lowercase)
        XCTAssertNotNil(UUIDGenerator.creationDate(of: v7))

        let ulids = UUIDGenerator.ulids(count: 50)
        XCTAssertEqual(ulids.count, 50)
        XCTAssertEqual(ulids, ulids.sorted())

        XCTAssertNil(UUIDGenerator.creationDate(of: UUIDGenerator.generate()), "a v4 has no time in it")
    }
}
