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
