//
//  DeepLinkTests.swift
//  RaceSyncAPITests
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-26.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import XCTest
@testable import RaceSyncAPI

final class DeepLinkTests: XCTestCase {

    override func setUpWithError() throws { }

    override func tearDownWithError() throws { }

    func testDeepLinkAbsoluteString() throws {
        let expected = "racesync://race/view?id=29941"
        let result = DeepLink(domain: .race, action: .view, parameters: ["id" : "29941"])

        XCTAssertEqual(result.absoluteString, expected)
    }

    func testConvertWebURLToDeeplink() throws {
        let url = URL(string: "https://www.multigp.com/races/view/?race=30303/")!
        let expected = "racesync://races/view?id=30303"
        let result = DeepLink.create(from: url)!

        XCTAssertEqual(result.absoluteString, expected)
    }

    func testRaceViewDeeplink() throws {
        let expected = "racesync://races/view?id=29941"
        let result = DeepLink.create(from: URL(string: expected)!)!

        XCTAssertEqual(result.absoluteString, expected)
    }

    func testRaceJoinDeeplink() throws {
        let expected = "racesync://race/join?id=29941&pilotId=20676"
        let result = DeepLink.create(from: URL(string: expected)!)!

        XCTAssertEqual(result.absoluteString, expected)
    }
}
