import Foundation

struct TrigonometricUnitCircle: Equatable {
    static let periodRadians = 2 * Double.pi

    let angleRadians: Double

    init?(angleRadians: Double) {
        guard angleRadians.isFinite else { return nil }
        self.angleRadians = angleRadians
    }

    var xCoordinate: Double { cos(angleRadians) }
    var yCoordinate: Double { sin(angleRadians) }
    var angleDegrees: Double { angleRadians * 180 / Double.pi }
    var radiusSquared: Double { xCoordinate * xCoordinate + yCoordinate * yCoordinate }

    func sine(at radians: Double) -> Double { sin(radians) }
    func cosine(at radians: Double) -> Double { cos(radians) }
}
