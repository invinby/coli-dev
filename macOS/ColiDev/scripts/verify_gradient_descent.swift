import Foundation

@main
enum GradientDescentVerification {
    static func main() {
        precondition(GradientDescentPractice.learningRates == [0.01, 0.05, 0.12, 0.15])
        expect(GradientDescentPractice.optimalWeight, equals: 1.99, tolerance: 1e-12, "closed-form optimum")
        expect(GradientDescentPractice.loss(weight: 1.99), equals: 0.02425, tolerance: 1e-9, "minimum loss")
        expect(GradientDescentPractice.gradient(weight: 1.99), equals: 0, tolerance: 1e-12, "zero gradient at the optimum")

        let slow = GradientDescentPractice.trajectory(learningRate: 0.01)
        let good = GradientDescentPractice.trajectory(learningRate: 0.05)
        let bouncing = GradientDescentPractice.trajectory(learningRate: 0.12)
        let diverging = GradientDescentPractice.trajectory(learningRate: 0.15)
        for trajectory in [slow, good, bouncing, diverging] {
            precondition(trajectory.count == 21 && trajectory.first?.weight == 0 && trajectory.map(\.step) == Array(0...20))
        }

        expect(slow[20].weight, equals: 1.9129, tolerance: 5e-5, "small rate is still short of the optimum after 20 steps")
        expect(good[5].weight, equals: 1.988, tolerance: 5e-4, "good rate is near the optimum after five steps")
        expect(bouncing[5].weight, equals: 2.642, tolerance: 5e-4, "large stable rate overshoots")
        expect(bouncing[20].weight, equals: 1.9671, tolerance: 5e-5, "large stable rate still converges")
        expect(diverging[20].weight, equals: -170.615, tolerance: 5e-3, "too large a rate diverges")
        precondition(diverging[20].loss > 200_000, "the diverging loss explodes")

        precondition(GradientDescentPractice.converges(learningRate: 0.01))
        precondition(GradientDescentPractice.converges(learningRate: 0.05))
        precondition(GradientDescentPractice.converges(learningRate: 0.12))
        precondition(!GradientDescentPractice.converges(learningRate: 0.15))
        precondition(!GradientDescentPractice.oscillates(learningRate: 0.05))
        precondition(GradientDescentPractice.oscillates(learningRate: 0.12))
        precondition(zip(slow, slow.dropFirst()).allSatisfy { $0.1.loss < $0.0.loss }, "small rate lowers the loss every step")
        print("Gradient descent model checks passed.")
    }

    private static func expect(_ actual: Double, equals expected: Double, tolerance: Double, _ name: String) {
        precondition(actual.isFinite && abs(actual - expected) <= tolerance, "\(name): expected \(expected), got \(actual)")
    }
}
