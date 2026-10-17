import Foundation

enum LinearEquationOperation: Equatable {
    case add(Int)
    case subtract(Int)
    case divide(Int)
    case multiply(Int)

    func isCorrect(for equation: LinearEquation, at step: Int) -> Bool {
        switch (step, self) {
        case (0, .add(let value)):
            return equation.offset < 0 && value == abs(equation.offset)
        case (0, .subtract(let value)):
            return equation.offset > 0 && value == equation.offset
        case (1, .divide(let value)):
            return value == equation.coefficient
        default:
            return false
        }
    }
}

struct LinearEquation: Equatable {
    let coefficient: Int
    let solution: Int
    let offset: Int

    init(coefficient: Int, solution: Int, offset: Int) {
        precondition(coefficient > 0, "The balance exercise requires a positive, non-zero coefficient")
        self.coefficient = coefficient
        self.solution = solution
        self.offset = offset
    }

    var rightSide: Int { coefficient * solution + offset }
    var isolatedVariableRightSide: Int { rightSide - offset }
    var valueAfterDivision: Int { isolatedVariableRightSide / coefficient }

    func operationChoices(at step: Int) -> [LinearEquationOperation] {
        switch step {
        case 0:
            return [
                .subtract(abs(offset)),
                .add(abs(offset)),
                .divide(coefficient),
            ]
        case 1:
            return [
                .divide(coefficient),
                .multiply(coefficient),
                .add(coefficient),
            ]
        default:
            return []
        }
    }

    func operationChoiceOrders() -> [QuizAnswerOrder] {
        var generator = SystemRandomNumberGenerator()
        return operationChoiceOrders(using: &generator)
    }

    func operationChoiceOrders<Generator: RandomNumberGenerator>(
        using generator: inout Generator
    ) -> [QuizAnswerOrder] {
        let answerOriginalIndices = (0..<2).compactMap { step in
            operationChoices(at: step).firstIndex { $0.isCorrect(for: self, at: step) }
        }
        precondition(
            answerOriginalIndices.count == 2,
            "Each equation step must have one correct operation before choices are shuffled."
        )
        return QuizAnswerOrder.balancedSequence(
            optionCount: 3,
            answerOriginalIndices: answerOriginalIndices,
            using: &generator
        )
    }

    func leftSide(at value: Int) -> Int {
        coefficient * value + offset
    }

    func isSolution(_ value: Int) -> Bool {
        leftSide(at: value) == rightSide
    }

    func preservesEqualityAfterRemovingOffset(for value: Int) -> Bool {
        leftSide(at: value) - offset == rightSide - offset
    }

    func preservesEqualityAfterDividingCoefficient(for value: Int) -> Bool {
        (coefficient * value) / coefficient == isolatedVariableRightSide / coefficient
    }

    static func random() -> LinearEquation {
        let randomOffset = Int.random(in: -8...8)
        return LinearEquation(
            coefficient: Int.random(in: 1...5),
            solution: Int.random(in: -8...8),
            offset: randomOffset == 0 ? 3 : randomOffset
        )
    }
}
