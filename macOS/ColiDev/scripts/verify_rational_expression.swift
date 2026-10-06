import Foundation

@main
enum RationalExpressionVerification {
    static func main() {
        for input in [-5.0, -3.0, 0.0, 2.0, 2.75, 3.25, 5.0] {
            guard let original = RationalExpressionPractice.originalValue(at: input) else {
                preconditionFailure("valid input should have an original value: \(input)")
            }
            let simplified = RationalExpressionPractice.simplifiedValue(at: input)
            precondition(abs(original - simplified) < 1e-9, "forms should match on the original domain: \(input)")
        }

        precondition(RationalExpressionPractice.originalValue(at: 3.0) == nil, "the original denominator excludes x = 3")
        precondition(RationalExpressionPractice.simplifiedValue(at: 3.0) == 6.0, "the reduced formula still evaluates to 6 at the excluded input")
        print("Rational expression domain checks passed.")
    }
}
