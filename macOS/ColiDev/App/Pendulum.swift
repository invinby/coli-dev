import Foundation

/// Small-angle simple pendulum from OpenStax College Physics 2e, section 16.4: T = 2π√(L/g),
/// independent of the bob's mass and nearly independent of amplitude below about 15°.
enum PendulumModel {
    static let gravity = 9.81
    static let lengthRange: ClosedRange<Double> = 0.25...2.0
    static let massRange: ClosedRange<Double> = 0.1...2.0
    static let amplitudeDegrees = 10.0

    static func period(length: Double) -> Double {
        let clamped = min(max(length, lengthRange.lowerBound), lengthRange.upperBound)
        return 2 * Double.pi * (clamped / gravity).squareRoot()
    }

    /// Mass is accepted only to show that it does not enter the small-angle period.
    static func period(length: Double, mass: Double) -> Double {
        period(length: length)
    }

    static func frequency(length: Double) -> Double {
        1 / period(length: length)
    }

    /// Angular displacement in radians for an animation started at the maximum amplitude.
    static func angle(atSeconds time: Double, length: Double) -> Double {
        amplitudeDegrees * Double.pi / 180 * cos(2 * Double.pi * time / period(length: length))
    }
}
