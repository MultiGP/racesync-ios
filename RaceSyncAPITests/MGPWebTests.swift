//
//  MGPWebTests.swift
//  RaceSyncAPITests
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-26.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import XCTest
@testable import RaceSyncAPI

final class MGPWebTests: XCTestCase {

    override func setUpWithError() throws { }

    override func tearDownWithError() throws { }

    func testBaseURL() throws {
        let expected = URL(string: "https://www.multigp.com/")!
        let result = MGPWeb.baseURL()

        XCTAssertEqual(result, expected)
    }

    func testAPIURL() throws {
        let expected = URL(string: "https://www.multigp.com/mgp/multigpwebservice/")!
        let result = MGPWeb.getURL(for: .apiBase)

        XCTAssertEqual(result, expected)
    }

    func testRaceURL() throws {
        let expected = URL(string: "https://www.multigp.com/races/view/?race=30578")!
        let result = MGPWeb.getURL(for: .raceView, value: "30578")

        XCTAssertEqual(result, expected)
    }

    func testChapterURL() throws {
        let expected = URL(string: "https://www.multigp.com/chapters/view/?chapter=VanWhoop")!
        let result = MGPWeb.getURL(for: .chapterView, value: "VanWhoop")

        XCTAssertEqual(result, expected)
    }

    func testUserURL() throws {
        let expected = URL(string: "https://www.multigp.com/pilots/view/?pilot=Zenith")!
        let result = MGPWeb.getURL(for: .userView, value: "Zenith")

        XCTAssertEqual(result, expected)
    }

    func testZippyQURL() throws {
        let expected = URL(string: "https://www.multigp.com/MultiGP/views/zippyq.php?raceId=6666")!
        let result = MGPWeb.getURL(for: .zippyqView, value: "6666")

        XCTAssertEqual(result, expected)
    }

    func testZipperSeasonResults() throws {
        let expected = URL(string: "https://www.multigp.com/MultiGP/views/viewZipperSeasonResults.php?season1=2025Summer&season2=2025Spring&exportcsv=true")!
        let result = StandingApi.getStandingsUrl(for: .y2025)!

        XCTAssertEqual(result, expected)
    }

    func testPaymentURL() throws {
        let expected = URL(string: "https://www.multigp.com/MultiGP/views/processPayment.php?raceId=30303&pilotId=24900&user-agent=ios")!
        let result = RaceApi.getPaymentUrl(for: "30303", user: "24900")

        XCTAssertEqual(result, expected)
    }
}
