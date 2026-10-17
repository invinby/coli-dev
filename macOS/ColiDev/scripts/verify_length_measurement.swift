import Foundation

@main
enum LengthMeasurementVerification {
    static func main() {
        let sample = LengthMeasurement(centimetres: 12.4, uncertaintyCentimetres: 0.2)
        expect(sample.metres, 0.124)
        expect(sample.uncertaintyMetres, 0.002)
        expect(sample.lowerCentimetres, 12.2)
        expect(sample.upperCentimetres, 12.6)
        expect(sample.relativeUncertaintyPercent, 100 * 0.2 / 12.4)

        let sameRelativeUncertainty = 100 * sample.uncertaintyMetres / sample.metres
        expect(sameRelativeUncertainty, sample.relativeUncertaintyPercent)

        let exact = LengthMeasurement(centimetres: 3, uncertaintyCentimetres: 0)
        expect(exact.lowerCentimetres, 3)
        expect(exact.upperCentimetres, 3)
        expect(exact.relativeUncertaintyPercent, 0)

        let boundary = LengthMeasurement(centimetres: 2, uncertaintyCentimetres: 2)
        expect(boundary.lowerCentimetres, 0)
        print("Length measurement checks passed.")
    }

    private static func expect(_ actual: Double, _ expected: Double) {
        precondition(actual.isFinite && abs(actual - expected) < 1e-10,
                     "Expected \(expected), got \(actual)")
    }
}
