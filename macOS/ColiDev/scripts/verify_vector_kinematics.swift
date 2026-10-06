import Foundation

@main
enum VectorKinematicsVerification {
    static func main() {
        let tolerance = 1e-10
        let vector = VectorKinematics(magnitude: 10, angleDegrees: 30)
        expect(vector.xComponent, equals: 5 * sqrt(3), tolerance: tolerance, "30 degree horizontal component")
        expect(vector.yComponent, equals: 5, tolerance: tolerance, "30 degree vertical component")
        expect(vector.reconstructedMagnitude, equals: 10, tolerance: tolerance, "magnitude from components")

        let quadrants = [
            (0.0, 10.0, 0.0),
            (90.0, 0.0, 10.0),
            (180.0, -10.0, 0.0),
            (270.0, 0.0, -10.0),
            (135.0, -sqrt(50), sqrt(50))
        ]
        for (angle, x, y) in quadrants {
            let sample = VectorKinematics(magnitude: 10, angleDegrees: angle)
            expect(sample.xComponent, equals: x, tolerance: tolerance, "x component at \(angle) degrees")
            expect(sample.yComponent, equals: y, tolerance: tolerance, "y component at \(angle) degrees")
            expect(sample.reconstructedMagnitude, equals: 10, tolerance: tolerance, "magnitude at \(angle) degrees")
        }

        let negativeAngle = VectorKinematics(magnitude: 2, angleDegrees: -90)
        expect(negativeAngle.normalizedAngleDegrees, equals: 270, tolerance: tolerance, "normalized negative angle")
        expect(VectorKinematics(magnitude: 0, angleDegrees: 45).reconstructedMagnitude, equals: 0, tolerance: tolerance, "zero vector")
        print("Vector kinematics checks passed.")
    }

    private static func expect(_ actual: Double, equals expected: Double, tolerance: Double, _ name: String) {
        precondition(actual.isFinite && abs(actual - expected) <= tolerance, "\(name): expected \(expected), got \(actual)")
    }
}
