import Foundation

struct PercentRepresentation: Equatable {
    let percent: Int

    init(percent: Int) {
        precondition((0...100).contains(percent), "This introductory model represents a part from 0% through 100%")
        self.percent = percent
    }

    var decimal: Double { Double(percent) / 100 }
    var numerator: Int { percent / Self.greatestCommonDivisor(percent, 100) }
    var denominator: Int { 100 / Self.greatestCommonDivisor(percent, 100) }
    var fractionDescription: String { "\(numerator)/\(denominator)" }

    func part(of whole: Int) -> Double {
        Double(whole) * decimal
    }

    private static func greatestCommonDivisor(_ lhs: Int, _ rhs: Int) -> Int {
        var a = abs(lhs)
        var b = abs(rhs)
        while b != 0 {
            (a, b) = (b, a % b)
        }
        return max(a, 1)
    }
}

struct KilometreConversion: Equatable {
    let kilometres: Double

    init(kilometres: Double) {
        precondition(kilometres >= 0, "Distance cannot be negative in this introductory conversion")
        self.kilometres = kilometres
    }

    var metres: Double { kilometres * 1_000 }
}
