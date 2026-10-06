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
            let firstOperation: LinearEquationOperation = equation.offset < 0
                ? .add(abs(equation.offset))
                : .subtract(equation.offset)
            precondition(firstOperation.isCorrect(for: equation, at: 0), "the inverse constant operation should be accepted")
            precondition(!LinearEquationOperation.divide(equation.coefficient).isCorrect(for: equation, at: 0), "the coefficient operation should not remove the constant first")
            precondition(LinearEquationOperation.divide(equation.coefficient).isCorrect(for: equation, at: 1), "division by the variable coefficient should be accepted second")
            precondition(!LinearEquationOperation.multiply(equation.coefficient).isCorrect(for: equation, at: 1), "multiplication should not isolate the variable")

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
