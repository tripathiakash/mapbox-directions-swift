import XCTest
import CoreLocation
import Turf
@testable import MapboxDirections

class RouteLegTests: XCTestCase {
    func testSegmentRanges() {
        let departureStep = RouteStep(transportType: .automobile, maneuverLocation: CLLocationCoordinate2D(latitude: 0, longitude: 0), maneuverType: .depart, instructions: "Depart", drivingSide: .right, distance: 10, expectedTravelTime: 10)
        departureStep.shape = LineString([
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
        ])
        let turnStep = RouteStep(transportType: .automobile, maneuverLocation: CLLocationCoordinate2D(latitude: 1, longitude: 1), maneuverType: .turn, maneuverDirection: .left, instructions: "Turn left at Albuquerque", drivingSide: .right, distance: 10, expectedTravelTime: 10)
        turnStep.shape = LineString([
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 2, longitude: 2),
            CLLocationCoordinate2D(latitude: 3, longitude: 3),
            CLLocationCoordinate2D(latitude: 4, longitude: 4),
        ])
        let typicalTravelTime = 10.0
        let arrivalStep = RouteStep(transportType: .automobile, maneuverLocation: CLLocationCoordinate2D(latitude: 4, longitude: 4), maneuverType: .arrive, instructions: "Arrive at Elmer’s House", drivingSide: .right, distance: 0, expectedTravelTime: 0)
        let leg = RouteLeg(steps: [departureStep, turnStep, arrivalStep], name: "", distance: 10, expectedTravelTime: 10, typicalTravelTime: typicalTravelTime, profileIdentifier: .automobile)
        leg.segmentDistances = [
            10,
            10, 20, 30,
        ]
        XCTAssertEqual(leg.segmentRangesByStep.count, leg.steps.count)
        XCTAssertEqual(leg.segmentRangesByStep, [0..<1, 1..<4, 4..<4])
        XCTAssertEqual(leg.segmentRangesByStep.last?.upperBound, leg.segmentDistances?.count)
        XCTAssertEqual(leg.typicalTravelTime, typicalTravelTime)
    }
}