import Foundation

/// One-dimensional motion from rest under a constant net force, without friction.
/// The two-second experiment fits the fixed -60...60 metre scene for the UI limits.
struct ForceMotion {
    static let duration = 2.0

    let force: Double
    let mass: Double
    let time: Double

    init(force: Double, mass: Double, time: Double) {
        precondition(force.isFinite && mass.isFinite && mass > 0 && time.isFinite)
        self.force = force
        self.mass = mass
        self.time = min(max(time, 0), Self.duration)
    }

    var acceleration: Double { force / mass }
    var velocity: Double { acceleration * time }
    var displacement: Double { 0.5 * acceleration * time * time }
    var hasFinished: Bool { time >= Self.duration }
}

/// One-dimensional perfectly inelastic collision: the objects stick together.
/// Velocities are signed; momentum is conserved when external impulse is negligible.
struct MomentumCollision {
    let firstMass: Double
    let firstVelocity: Double
    let secondMass: Double
    let secondVelocity: Double

    init(firstMass: Double, firstVelocity: Double, secondMass: Double, secondVelocity: Double) {
        precondition(
            firstMass.isFinite && firstMass > 0
                && secondMass.isFinite && secondMass > 0
                && firstVelocity.isFinite && secondVelocity.isFinite
        )
        self.firstMass = firstMass
        self.firstVelocity = firstVelocity
        self.secondMass = secondMass
        self.secondVelocity = secondVelocity
    }

    var totalMass: Double { firstMass + secondMass }
    var momentumBefore: Double { firstMass * firstVelocity + secondMass * secondVelocity }
    var finalVelocity: Double { momentumBefore / totalMass }
    var momentumAfter: Double { totalMass * finalVelocity }
    var kineticEnergyBefore: Double {
        0.5 * firstMass * firstVelocity * firstVelocity
            + 0.5 * secondMass * secondVelocity * secondVelocity
    }
    var kineticEnergyAfter: Double { 0.5 * totalMass * finalVelocity * finalVelocity }
    var kineticEnergyConverted: Double { max(0, kineticEnergyBefore - kineticEnergyAfter) }
}
