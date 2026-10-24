import Foundation

@main
enum PendulumVerification {
    static func main() {
        expect(PendulumModel.period(length: 1), equals: 2.006, tolerance: 5e-4, "one-metre pendulum")
        expect(PendulumModel.period(length: 0.25), equals: 1.003, tolerance: 5e-4, "quarter-metre pendulum")
        expect(PendulumModel.period(length: 1) / PendulumModel.period(length: 0.25), equals: 2, tolerance: 1e-12, "four times the length doubles the period")
        expect(PendulumModel.period(length: 2) / PendulumModel.period(length: 0.5), equals: 2, tolerance: 1e-12, "the ratio holds at any length")
        expect(PendulumModel.period(length: 1, mass: 0.1), equals: PendulumModel.period(length: 1, mass: 2), tolerance: 0, "mass does not change the period")
        expect(PendulumModel.frequency(length: 1) * PendulumModel.period(length: 1), equals: 1, tolerance: 1e-12, "f = 1/T")
        expect(PendulumModel.period(length: 10), equals: PendulumModel.period(length: 2), tolerance: 0, "length is clamped to the lab range")

        let start = PendulumModel.angle(atSeconds: 0, length: 1)
        let half = PendulumModel.angle(atSeconds: PendulumModel.period(length: 1) / 2, length: 1)
        let full = PendulumModel.angle(atSeconds: PendulumModel.period(length: 1), length: 1)
        expect(start, equals: 10 * Double.pi / 180, tolerance: 1e-12, "the animation starts at the amplitude")
        expect(half, equals: -start, tolerance: 1e-12, "half a period later it is on the other side")
        expect(full, equals: start, tolerance: 1e-12, "one full period returns to the start")
        precondition(PendulumModel.amplitudeDegrees < 15, "the small-angle formula needs amplitudes below about 15 degrees")
        print("Pendulum model checks passed.")
    }

    private static func expect(_ actual: Double, equals expected: Double, tolerance: Double, _ name: String) {
        precondition(actual.isFinite && abs(actual - expected) <= tolerance, "\(name): expected \(expected), got \(actual)")
    }
}
