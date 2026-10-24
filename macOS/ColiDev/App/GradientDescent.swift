import Foundation

struct GradientDescentStep: Equatable {
    let step: Int
    let weight: Double
    let loss: Double
}

/// One-parameter linear regression `y = w·x` fitted by gradient descent on mean squared error.
/// The four points are invented for the lesson so that every learning rate shows a different behaviour.
enum GradientDescentPractice {
    static let inputs: [Double] = [1, 2, 3, 4]
    static let targets: [Double] = [2.1, 3.9, 6.2, 7.8]
    static let learningRates: [Double] = [0.01, 0.05, 0.12, 0.15]
    static let maximumSteps = 20
    static let initialWeight = 0.0

    static func loss(weight: Double) -> Double {
        zip(inputs, targets).reduce(0) { $0 + pow(weight * $1.0 - $1.1, 2) } / Double(inputs.count)
    }

    static func gradient(weight: Double) -> Double {
        2 * zip(inputs, targets).reduce(0) { $0 + (weight * $1.0 - $1.1) * $1.0 } / Double(inputs.count)
    }

    /// The closed-form minimum of the mean squared error for `y = w·x`.
    static var optimalWeight: Double {
        zip(inputs, targets).reduce(0) { $0 + $1.0 * $1.1 } / inputs.reduce(0) { $0 + $1 * $1 }
    }

    static func trajectory(learningRate: Double, steps: Int = maximumSteps) -> [GradientDescentStep] {
        var weight = initialWeight
        var result = [GradientDescentStep(step: 0, weight: weight, loss: loss(weight: weight))]
        for step in stride(from: 1, through: max(0, steps), by: 1) {
            weight -= learningRate * gradient(weight: weight)
            result.append(GradientDescentStep(step: step, weight: weight, loss: loss(weight: weight)))
        }
        return result
    }

    /// For this data the update is `w ← w(1 − 15η) + 29.85η`, so it converges only when |1 − 15η| < 1.
    static func converges(learningRate: Double) -> Bool {
        let factor = 1 - learningRate * 2 * inputs.reduce(0) { $0 + $1 * $1 } / Double(inputs.count)
        return abs(factor) < 1
    }

    static func oscillates(learningRate: Double) -> Bool {
        1 - learningRate * 2 * inputs.reduce(0) { $0 + $1 * $1 } / Double(inputs.count) < 0
    }
}
