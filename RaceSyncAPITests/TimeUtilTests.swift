//
//  TimeUtilTests.swift
//  RaceSyncAPITests
//
//  Created by Ignacio Romero Zurbuchen on 2025-12-21.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import XCTest
@testable import RaceSyncAPI

final class TimeUtilTests: XCTestCase {

    override func setUpWithError() throws { }

    override func tearDownWithError() throws { }

    func testSecondConvertion() throws {

        let time = "9.204469"
        let expected = "9.204s"
        let result = TimeUtil.lapTimeFormat(seconds: time)

        XCTAssertEqual(result, expected)
    }

    func testSecondsConvertion() throws {

        let time = "30.400624"
        let expected = "30.400s"
        let result = TimeUtil.lapTimeFormat(seconds: time)

        XCTAssertEqual(result, expected)
    }

    func testNoUnitConvertion() throws {

        let time = "9.204469"
        let expected = "9.204"
        let result = TimeUtil.lapTimeFormat(seconds: time, showUnit: false)

        XCTAssertEqual(result, expected)
    }

    func testMinuteConvertion() throws {

        let time = "157.645896"
        let expected = "02:37.645"
        let result = TimeUtil.lapTimeFormat(seconds: time)

        XCTAssertEqual(result, expected)
    }

    func testMinutesConvertion() throws {

        let time = "1207.966584"
        let expected = "20:07.966"
        let result = TimeUtil.lapTimeFormat(seconds: time)

        XCTAssertEqual(result, expected)
    }

    func testHourConvertion() throws {

        let time = "5150.390321"
        let expected = "1:25:50.390"
        let result = TimeUtil.lapTimeFormat(seconds: time)

        XCTAssertEqual(result, expected)
    }

    func testZeroAndInvalidValues() {
        XCTAssertEqual(TimeUtil.lapTimeFormat(seconds: "0"), "0.000s")
        XCTAssertEqual(TimeUtil.lapTimeFormat(seconds: ""), "")
        XCTAssertEqual(TimeUtil.lapTimeFormat(seconds: "not a time"), "")
    }

    func testFormattingBoundaries() {
        let cases = [
            ("9.999", "9.999s"),
            ("10", "10.000s"),
            ("59.999", "59.999s"),
            ("60", "01:00.000"),
            ("3599.999", "59:59.999"),
            ("3600", "1:00:00.000")
        ]

        for (input, expected) in cases {
            XCTAssertEqual(TimeUtil.lapTimeFormat(seconds: input), expected, "Input: \(input)")
        }
    }

    func testExtraDecimalPlacesAreTruncated() {
        XCTAssertEqual(TimeUtil.lapTimeFormat(seconds: "9.9999"), "9.999s")
        XCTAssertEqual(TimeUtil.lapTimeFormat(seconds: "60.1239"), "01:00.123")
    }

    func testNoUnitAcrossFormattingRanges() {
        XCTAssertEqual(TimeUtil.lapTimeFormat(seconds: "0", showUnit: false), "0.000")
        XCTAssertEqual(TimeUtil.lapTimeFormat(seconds: "10", showUnit: false), "10.000")
        XCTAssertEqual(TimeUtil.lapTimeFormat(seconds: "60", showUnit: false), "01:00.000")
        XCTAssertEqual(TimeUtil.lapTimeFormat(seconds: "3600", showUnit: false), "1:00:00.000")
    }
}
