import Foundation

/// A two-dimensional vector whose angle is measured counterclockwise from +x.
struct VectorKinematics {
    let magnitude: Double
    let angleDegrees: Double

    init(magnitude: Double, angleDegrees: Double) {
        precondition(magnitude.isFinite && magnitude >= 0 && angleDegrees.isFinite)
        self.magnitude = magnitude
        self.angleDegrees = angleDegrees
    }

    private var angleRadians: Double { angleDegrees * .pi / 180 }
    var xComponent: Double { magnitude * cos(angleRadians) }
    var yComponent: Double { magnitude * sin(angleRadians) }
    var reconstructedMagnitude: Double { hypot(xComponent, yComponent) }

    var normalizedAngleDegrees: Double {
        let degrees = angleDegrees.truncatingRemainder(dividingBy: 360)
        return degrees < 0 ? degrees + 360 : degrees
    }
}
