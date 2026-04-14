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
}
