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

        verifyOperationChoiceOrders()

        print("Linear equation model checks passed.")
    }

    private static func verifyOperationChoiceOrders() {
        let examples: [(equation: LinearEquation, firstStepAnswerIndex: Int, expectedChoices: [[LinearEquationOperation]])] = [
            (
                equation: LinearEquation(coefficient: 3, solution: 2, offset: 4),
                firstStepAnswerIndex: 0,
                expectedChoices: [
                    [.subtract(4), .add(4), .divide(3)],
                    [.divide(3), .multiply(3), .add(3)],
                ]
            ),
            (
                equation: LinearEquation(coefficient: 2, solution: -3, offset: -5),
                firstStepAnswerIndex: 1,
                expectedChoices: [
                    [.subtract(5), .add(5), .divide(2)],
                    [.divide(2), .multiply(2), .add(2)],
                ]
            ),
        ]

        var secondStepPositions = Set<Int>()
        for seed in 0..<64 {
            let example = examples[seed % examples.count]
            var generator = SeededGenerator(seed: UInt64(seed))
            let orders = example.equation.operationChoiceOrders(using: &generator)
            precondition(orders.count == 2, "Each equation needs one choice order per solving step")

            let answerOriginalIndices = [example.firstStepAnswerIndex, 0]
            for step in 0..<2 {
                let choices = example.equation.operationChoices(at: step)
                precondition(
                    choices == example.expectedChoices[step],
                    "Choice order must preserve the intended inverse operations at step \(step)"
                )
                let order = orders[step]
                precondition(
                    order.displayedOriginalIndices.sorted() == [0, 1, 2],
                    "Every solving step must display each operation exactly once"
                )
                precondition(
                    order.displayedOriginalIndices[order.correctDisplayedIndex] == answerOriginalIndices[step],
                    "Displayed correct operation must keep its original meaning"
                )
            }

            precondition(
                orders[0].correctDisplayedIndex != orders[1].correctDisplayedIndex,
                "Adjacent equation steps must not put the correct choice in the same position"
            )
            secondStepPositions.insert(orders[1].correctDisplayedIndex)
        }

        precondition(
            secondStepPositions == Set([0, 1, 2]),
            "Division must not occupy one predictable answer position across new examples"
        )
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}
