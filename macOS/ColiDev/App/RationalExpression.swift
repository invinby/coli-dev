import Foundation

enum RationalExpressionPractice {
    static let excludedInput = 3.0

    static func originalValue(at input: Double) -> Double? {
        let denominator = input - excludedInput
        guard denominator != 0 else { return nil }
        return (input * input - excludedInput * excludedInput) / denominator
    }

    static func simplifiedValue(at input: Double) -> Double {
        input + excludedInput
    }
}
