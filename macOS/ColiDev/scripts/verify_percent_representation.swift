import Foundation

enum PercentRepresentationVerification {
    static func run() {
        let cases: [(Int, String, Double)] = [
            (0, "0/1", 0),
            (12, "3/25", 0.12),
            (25, "1/4", 0.25),
            (35, "7/20", 0.35),
            (50, "1/2", 0.5),
            (75, "3/4", 0.75),
            (100, "1/1", 1),
        ]
        for (percent, expectedFraction, expectedDecimal) in cases {
            let value = PercentRepresentation(percent: percent)
            precondition(value.fractionDescription == expectedFraction, "incorrect reduced fraction for \(percent)%")
            precondition(abs(value.decimal - expectedDecimal) < 0.000_001, "incorrect decimal for \(percent)%")
            precondition(abs(value.part(of: 240) - 240 * expectedDecimal) < 0.000_001, "incorrect part of whole for \(percent)%")
        }
        for (kilometres, metres) in [(0.0, 0.0), (0.5, 500.0), (1.5, 1_500.0), (12.25, 12_250.0)] {
            precondition(KilometreConversion(kilometres: kilometres).metres == metres, "incorrect kilometre conversion for \(kilometres) km")
        }
        print("Percent representation model checks passed")
    }
}

PercentRepresentationVerification.run()
