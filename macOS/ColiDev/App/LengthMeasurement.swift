import Foundation

/// A stated length and absolute uncertainty, both expressed in centimetres.
/// This is an arithmetic teaching model, not an instrument or confidence interval.
struct LengthMeasurement {
    let centimetres: Double
    let uncertaintyCentimetres: Double

    init(centimetres: Double, uncertaintyCentimetres: Double) {
        precondition(
            centimetres.isFinite && centimetres > 0
                && uncertaintyCentimetres.isFinite && uncertaintyCentimetres >= 0
                && uncertaintyCentimetres <= centimetres
        )
        self.centimetres = centimetres
        self.uncertaintyCentimetres = uncertaintyCentimetres
    }

    var metres: Double { centimetres / 100 }
    var uncertaintyMetres: Double { uncertaintyCentimetres / 100 }
    var lowerCentimetres: Double { centimetres - uncertaintyCentimetres }
    var upperCentimetres: Double { centimetres + uncertaintyCentimetres }
    var relativeUncertaintyPercent: Double { 100 * uncertaintyCentimetres / centimetres }
}
