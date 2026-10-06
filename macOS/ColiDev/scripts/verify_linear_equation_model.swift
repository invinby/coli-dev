import Foundation

@main
enum LinearEquationModelVerification {
    static func main() {
        let equations = [
            LinearEquation(coefficient: 2, solution: 4, offset: 3),
            LinearEquation(coefficient: 5, solution: -3, offset: -7),
            LinearEquation(coefficient: 1, solution: 0, offset: 8),
        ]

        for equation in equations {
            precondition(equation.valueAfterDivision == equation.solution, "inverse steps should recover the solution")
            precondition(equation.isSolution(equation.solution), "substitution should verify the generated solution")

            for candidate in -8...8 {
                let isEqualBeforeOperation = equation.isSolution(candidate)
                precondition(
                    equation.preservesEqualityAfterRemovingOffset(for: candidate) == isEqualBeforeOperation,
                    "subtracting the same offset must preserve equality"
                )
                precondition(
                    equation.preservesEqualityAfterDividingCoefficient(for: candidate) == isEqualBeforeOperation,
                    "dividing both sides by a non-zero coefficient must preserve equality"
                )
            }
        }

        print("Linear equation model checks passed.")
    }
}
