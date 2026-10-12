import Foundation

/// A block released from rest on a level surface under a constant rightward push.
/// Static friction follows the applied force up to its limiting value; once sliding
/// starts, the model uses a constant kinetic-friction coefficient.
struct FrictionMotion {
    static let gravity = 9.81
    static let duration = 2.0

    let mass: Double
    let appliedForce: Double
    let staticCoefficient: Double
    let kineticCoefficient: Double
    let time: Double

    init(
        mass: Double,
        appliedForce: Double,
        staticCoefficient: Double,
        kineticCoefficient: Double,
        time: Double
    ) {
        precondition(
            mass.isFinite && mass > 0
                && appliedForce.isFinite && appliedForce >= 0
                && staticCoefficient.isFinite && staticCoefficient >= 0
                && kineticCoefficient.isFinite && kineticCoefficient >= 0
                && kineticCoefficient <= staticCoefficient
                && time.isFinite
        )
        self.mass = mass
        self.appliedForce = appliedForce
        self.staticCoefficient = staticCoefficient
        self.kineticCoefficient = kineticCoefficient
        self.time = min(max(time, 0), Self.duration)
    }

    var normalForce: Double { mass * Self.gravity }
    var maximumStaticFriction: Double { staticCoefficient * normalForce }
    var isSliding: Bool { appliedForce > maximumStaticFriction }
    var frictionForce: Double {
        isSliding ? kineticCoefficient * normalForce : appliedForce
    }
    var netForce: Double { max(0, appliedForce - frictionForce) }
    var acceleration: Double { netForce / mass }
    var velocity: Double { acceleration * time }
    var displacement: Double { 0.5 * acceleration * time * time }
}

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

/// Ideal two-dimensional projectile launched from ground level with no air resistance.
struct ProjectileMotion {
    let launchSpeed: Double
    let angleDegrees: Double
    let gravity: Double

    init(launchSpeed: Double, angleDegrees: Double, gravity: Double = 9.81) {
        precondition(
            launchSpeed.isFinite && launchSpeed >= 0
                && angleDegrees.isFinite && angleDegrees >= 0 && angleDegrees <= 90
                && gravity.isFinite && gravity > 0
        )
        self.launchSpeed = launchSpeed
        self.angleDegrees = angleDegrees
        self.gravity = gravity
    }

    private var angleRadians: Double { angleDegrees * .pi / 180 }
    var horizontalVelocity: Double { launchSpeed * cos(angleRadians) }
    var verticalVelocity: Double { launchSpeed * sin(angleRadians) }
    var flightTime: Double { 2 * verticalVelocity / gravity }
    var horizontalRange: Double { horizontalVelocity * flightTime }
    var maximumHeight: Double { verticalVelocity * verticalVelocity / (2 * gravity) }

    func position(at time: Double) -> (x: Double, y: Double) {
        precondition(time.isFinite)
        let t = min(max(time, 0), flightTime)
        return (
            horizontalVelocity * t,
            max(0, verticalVelocity * t - 0.5 * gravity * t * t)
        )
    }
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

enum CollisionOutcomeMode: String, CaseIterable, Identifiable {
    case perfectlyInelastic
    case elastic

    var id: String { rawValue }
}

/// One-dimensional ideal elastic collision. Signed velocities are measured on one shared axis.
struct ElasticCollision {
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

    private var totalMass: Double { firstMass + secondMass }
    var firstFinalVelocity: Double {
        ((firstMass - secondMass) * firstVelocity + 2 * secondMass * secondVelocity) / totalMass
    }
    var secondFinalVelocity: Double {
        (2 * firstMass * firstVelocity + (secondMass - firstMass) * secondVelocity) / totalMass
    }
    var momentumBefore: Double { firstMass * firstVelocity + secondMass * secondVelocity }
    var momentumAfter: Double { firstMass * firstFinalVelocity + secondMass * secondFinalVelocity }
    var kineticEnergyBefore: Double {
        0.5 * firstMass * firstVelocity * firstVelocity
            + 0.5 * secondMass * secondVelocity * secondVelocity
    }
    var kineticEnergyAfter: Double {
        0.5 * firstMass * firstFinalVelocity * firstFinalVelocity
            + 0.5 * secondMass * secondFinalVelocity * secondFinalVelocity
    }
}
