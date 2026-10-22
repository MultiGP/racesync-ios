//
//  RaceRulesTests.swift
//  RaceSyncAPITests
//

import XCTest
@testable import RaceSyncAPI

final class RaceRulesTests: XCTestCase {

    func testQualifierAlwaysUsesFastestThreeLaps() {
        let race = Race()
        race.raceType = .qualifier

        for format in [ScoringFormat.aggregateLap, .fastestLap, .fastest2Laps, .fastest3Laps] {
            race.scoringFormat = format
            XCTAssertTrue(race.isGQ)
            XCTAssertEqual(race.trueScoringFormat, .fastest3Laps)
        }
    }

    func testOtherRaceTypesUseConfiguredScoringFormat() {
        let race = Race()

        for type in [RaceType.normal, .final] {
            race.raceType = type
            for format in [ScoringFormat.aggregateLap, .fastestLap, .fastest2Laps, .fastest3Laps] {
                race.scoringFormat = format
                XCTAssertFalse(race.isGQ)
                XCTAssertEqual(race.trueScoringFormat, format)
            }
        }
    }

    func testZippyQIsEnabledForOpenQualifyingOnly() {
        let race = Race()
        race.disableSlotAutoPopulation = .controlled
        XCTAssertFalse(race.isZippyQEnabled)

        race.disableSlotAutoPopulation = .open
        XCTAssertTrue(race.isZippyQEnabled)
    }

    func testFreeRaceDoesNotRequirePayment() {
        let race = Race()
        race.fee = 0
        race.isPaymentRequiredToJoin = true

        XCTAssertFalse(race.isPayable)
        XCTAssertFalse(race.isPaid)
        XCTAssertFalse(race.requiresPayment)
    }

    func testUnpaidRaceCanHaveOptionalOrRequiredPayment() {
        let race = Race()
        race.fee = 20

        XCTAssertTrue(race.isPayable)
        XCTAssertFalse(race.isPaid)
        XCTAssertFalse(race.requiresPayment)

        race.isPaymentRequiredToJoin = true
        XCTAssertTrue(race.isPayable)
        XCTAssertFalse(race.isPaid)
        XCTAssertTrue(race.requiresPayment)
    }

    func testAnyPositivePaymentMarksRaceAsPaid() {
        let race = Race()
        race.fee = 20
        race.amountPaid = 1
        race.isPaymentRequiredToJoin = true

        XCTAssertFalse(race.isPayable)
        XCTAssertTrue(race.isPaid)
        XCTAssertFalse(race.requiresPayment)
    }
}
