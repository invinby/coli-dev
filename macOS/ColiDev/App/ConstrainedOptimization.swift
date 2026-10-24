import Foundation

enum ConstrainedExtremum: Equatable {
    case nonStationary
    case maximum
    case minimum
}

struct ConstrainedOptimizationPoint: Equatable {
    let angleRadians: Double
    let x: Double
    let y: Double
    let objective: Double
    let tangentDerivative: Double
    let lagrangeMultiplier: Double?
    let extremum: ConstrainedExtremum

    var constraintValue: Double { x * x + y * y }
    var isStationary: Bool { extremum != .nonStationary }

    init?(angleRadians: Double) {
        guard angleRadians.isFinite else { return nil }

        let fullTurn = 2 * Double.pi
        var normalizedAngle = angleRadians.truncatingRemainder(dividingBy: fullTurn)
        if normalizedAngle < 0 { normalizedAngle += fullTurn }

        let x = cos(normalizedAngle)
        let y = sin(normalizedAngle)
        let objective = x * y
        let tangentDerivative = cos(2 * normalizedAngle)
        let stationaryTolerance = 1e-8
        let isStationary = abs(tangentDerivative) <= stationaryTolerance

        self.angleRadians = normalizedAngle
        self.x = x
        self.y = y
        self.objective = objective
        self.tangentDerivative = tangentDerivative
        if isStationary {
            self.extremum = objective > 0 ? .maximum : .minimum
            self.lagrangeMultiplier = objective
        } else {
            self.extremum = .nonStationary
            self.lagrangeMultiplier = nil
        }
    }
}
