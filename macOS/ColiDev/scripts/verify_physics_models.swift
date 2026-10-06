import Foundation

@main
enum PhysicsModelVerification {
    static func main() {
        let tolerance = 1e-10

        let motion = ForceMotion(force: 12, mass: 3, time: 2)
        expect(motion.acceleration, equals: 4, tolerance: tolerance, "constant-force acceleration")
        expect(motion.velocity, equals: 8, tolerance: tolerance, "velocity after two seconds")
        expect(motion.displacement, equals: 8, tolerance: tolerance, "displacement from rest")
        precondition(motion.hasFinished, "two-second motion should finish at its duration")

        let projectile = ProjectileMotion(launchSpeed: 20, angleDegrees: 30)
        expect(projectile.horizontalVelocity, equals: 10 * sqrt(3), tolerance: tolerance, "projectile horizontal velocity")
        expect(projectile.verticalVelocity, equals: 10, tolerance: tolerance, "projectile vertical velocity")
        expect(projectile.flightTime, equals: 20 / 9.81, tolerance: tolerance, "projectile flight time")
        expect(projectile.maximumHeight, equals: 100 / (2 * 9.81), tolerance: tolerance, "projectile maximum height")
        expect(projectile.position(at: projectile.flightTime).x, equals: projectile.horizontalRange, tolerance: tolerance, "projectile landing range")
        expect(projectile.position(at: projectile.flightTime).y, equals: 0, tolerance: tolerance, "projectile landing height")
        let complementary = ProjectileMotion(launchSpeed: 20, angleDegrees: 60)
        expect(complementary.horizontalRange, equals: projectile.horizontalRange, tolerance: tolerance, "complementary-angle equal range")
        precondition(complementary.maximumHeight > projectile.maximumHeight, "higher complementary angle should reach a higher peak")

        let collision = MomentumCollision(
            firstMass: 2,
            firstVelocity: 4,
            secondMass: 2,
            secondVelocity: -2
        )
        expect(collision.momentumBefore, equals: 4, tolerance: tolerance, "momentum before collision")
        expect(collision.finalVelocity, equals: 1, tolerance: tolerance, "signed final velocity")
        expect(collision.momentumAfter, equals: collision.momentumBefore, tolerance: tolerance, "momentum conservation")
        expect(collision.kineticEnergyBefore, equals: 20, tolerance: tolerance, "initial kinetic energy")
        expect(collision.kineticEnergyAfter, equals: 2, tolerance: tolerance, "final kinetic energy")
        expect(collision.kineticEnergyConverted, equals: 18, tolerance: tolerance, "energy converted in collision")

        let balanced = MomentumCollision(
            firstMass: 3,
            firstVelocity: 2,
            secondMass: 1,
            secondVelocity: -6
        )
        expect(balanced.finalVelocity, equals: 0, tolerance: tolerance, "balanced opposite momenta")

        let lessonPractice = MomentumCollision(
            firstMass: 3,
            firstVelocity: 2,
            secondMass: 1,
            secondVelocity: -4
        )
        expect(lessonPractice.momentumBefore, equals: 2, tolerance: tolerance, "lesson practice momentum")
        expect(lessonPractice.finalVelocity, equals: 0.5, tolerance: tolerance, "lesson practice final velocity")

        let equalMassElastic = ElasticCollision(
            firstMass: 2,
            firstVelocity: 4,
            secondMass: 2,
            secondVelocity: -2
        )
        expect(equalMassElastic.firstFinalVelocity, equals: -2, tolerance: tolerance, "equal-mass velocity exchange, first cart")
        expect(equalMassElastic.secondFinalVelocity, equals: 4, tolerance: tolerance, "equal-mass velocity exchange, second cart")
        expect(equalMassElastic.momentumAfter, equals: equalMassElastic.momentumBefore, tolerance: tolerance, "elastic momentum conservation")
        expect(equalMassElastic.kineticEnergyAfter, equals: equalMassElastic.kineticEnergyBefore, tolerance: tolerance, "elastic kinetic-energy conservation")

        let unequalElastic = ElasticCollision(
            firstMass: 1,
            firstVelocity: 4,
            secondMass: 3,
            secondVelocity: 0
        )
        expect(unequalElastic.firstFinalVelocity, equals: -2, tolerance: tolerance, "unequal-mass rebound")
        expect(unequalElastic.secondFinalVelocity, equals: 2, tolerance: tolerance, "unequal-mass forward velocity")
        expect(unequalElastic.momentumAfter, equals: 4, tolerance: tolerance, "unequal-mass momentum")
        expect(unequalElastic.kineticEnergyAfter, equals: 8, tolerance: tolerance, "unequal-mass kinetic energy")

        print("Physics model checks passed.")
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
