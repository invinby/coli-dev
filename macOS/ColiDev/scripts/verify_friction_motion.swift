import Foundation

@main
enum FrictionMotionVerification {
    static func main() {
        let tolerance = 1e-10

        let resting = FrictionMotion(
            mass: 5,
            appliedForce: 15,
            staticCoefficient: 0.4,
            kineticCoefficient: 0.3,
            time: 2
        )
        expect(resting.normalForce, equals: 49.05, tolerance: tolerance, "normal force on a level surface")
        expect(resting.maximumStaticFriction, equals: 19.62, tolerance: tolerance, "maximum static friction")
        precondition(!resting.isSliding, "push below the static threshold must not start motion")
        expect(resting.frictionForce, equals: 15, tolerance: tolerance, "static friction matches sub-threshold push")
        expect(resting.acceleration, equals: 0, tolerance: tolerance, "resting acceleration")
        expect(resting.displacement, equals: 0, tolerance: tolerance, "resting displacement")

        let threshold = FrictionMotion(
            mass: 5,
            appliedForce: 19.62,
            staticCoefficient: 0.4,
            kineticCoefficient: 0.3,
            time: 1
        )
        precondition(!threshold.isSliding, "force equal to the static limit remains within the static model")
        expect(threshold.frictionForce, equals: 19.62, tolerance: tolerance, "static friction at its limit")

        let sliding = FrictionMotion(
            mass: 5,
            appliedForce: 25,
            staticCoefficient: 0.4,
            kineticCoefficient: 0.3,
            time: 2
        )
        precondition(sliding.isSliding, "push above the static threshold must start motion")
        expect(sliding.frictionForce, equals: 14.715, tolerance: tolerance, "kinetic friction")
        expect(sliding.netForce, equals: 10.285, tolerance: tolerance, "net force while sliding")
        expect(sliding.acceleration, equals: 2.057, tolerance: tolerance, "sliding acceleration")
        expect(sliding.velocity, equals: 4.114, tolerance: tolerance, "speed after two seconds")
        expect(sliding.displacement, equals: 4.114, tolerance: tolerance, "distance after two seconds")

        let zeroTime = FrictionMotion(
            mass: 5,
            appliedForce: 25,
            staticCoefficient: 0.4,
            kineticCoefficient: 0.3,
            time: 0
        )
        expect(zeroTime.velocity, equals: 0, tolerance: tolerance, "zero-time speed")
        expect(zeroTime.displacement, equals: 0, tolerance: tolerance, "zero-time displacement")

        let clampedTime = FrictionMotion(
            mass: 5,
            appliedForce: 25,
            staticCoefficient: 0.4,
            kineticCoefficient: 0.3,
            time: 20
        )
        expect(clampedTime.time, equals: FrictionMotion.duration, tolerance: tolerance, "maximum experiment duration")
        expect(clampedTime.displacement, equals: sliding.displacement, tolerance: tolerance, "displacement uses clamped time")

        print("Friction motion checks passed.")
    }

    private static func expect(
        _ actual: Double,
        equals expected: Double,
        tolerance: Double,
        _ name: String
    ) {
        precondition(actual.isFinite && abs(actual - expected) <= tolerance, "\(name): expected \(expected), got \(actual)")
    }
}
