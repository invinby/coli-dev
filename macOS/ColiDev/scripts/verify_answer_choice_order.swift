import Foundation

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

@main
enum AnswerChoiceOrderVerification {
    static func main() {
        for optionCount in [2, 3] {
            for answerIndex in 0..<optionCount {
                var correctPositionCounts = Array(repeating: 0, count: optionCount)
                for seed in 0..<256 {
                    var generator = SeededGenerator(seed: UInt64(seed))
                    let quizOrder = QuizAnswerOrder(
                        optionCount: optionCount,
                        answerOriginalIndex: answerIndex,
                        using: &generator
                    )
                    precondition(
                        Set(quizOrder.displayedOriginalIndices) == Set(0..<optionCount),
                        "Every quiz order must be a permutation. / Порядок вариантов должен быть перестановкой."
                    )

                    let correctDisplayIndex = quizOrder.displayedOriginalIndices.firstIndex(of: answerIndex)!
                    correctPositionCounts[correctDisplayIndex] += 1
                    for displayIndex in 0..<optionCount {
                        precondition(
                            quizOrder.isCorrect(displayedIndex: displayIndex)
                                == (quizOrder.originalIndex(forDisplayedIndex: displayIndex) == answerIndex),
                            "The quiz answer mapping must stay stable. / Сопоставление ответов не должно меняться."
                        )
                    }
                }

                precondition(
                    correctPositionCounts.allSatisfy { $0 > 0 },
                    "The correct answer must reach every quiz position. / Правильный ответ должен попадать в каждую позицию."
                )
            }
        }

        for answerIndex in 0..<3 {
            var correctPositionCounts = Array(repeating: 0, count: 3)
            for seed in 0..<256 {
                var generator = SeededGenerator(seed: UInt64(seed))
                let order = AnswerChoiceOrder(optionCount: 3, using: &generator)
                precondition(
                    Set(order.displayedOriginalIndices) == Set(0..<3),
                    "The order must be a permutation. / Порядок должен быть перестановкой."
                )

                let correctDisplayedIndex = order.displayedOriginalIndices.firstIndex(of: answerIndex)!
                correctPositionCounts[correctDisplayedIndex] += 1
                for displayedIndex in 0..<3 {
                    precondition(
                        order.isCorrect(displayedIndex: displayedIndex, answerOriginalIndex: answerIndex)
                            == (order.originalIndex(forDisplayedIndex: displayedIndex) == answerIndex),
                        "Displayed answer mapping changed. / Сопоставление ответа изменилось."
                    )
                }
            }

            precondition(
                correctPositionCounts.allSatisfy { $0 > 0 },
                "The correct answer must reach every position. / Правильный ответ должен попадать в каждую позицию."
            )
        }

        var attemptGenerator = SeededGenerator(seed: 19)
        guard var attempt = CurriculumCheckAttempt(
            optionCount: 3,
            answerOriginalIndex: 2,
            using: &attemptGenerator
        ) else {
            preconditionFailure("A valid answer index must start a quiz attempt. / Допустимый индекс ответа должен создавать попытку.")
        }
        let firstOrder = attempt.choiceOrder.displayedOriginalIndices
        guard let wrongDisplayIndex = firstOrder.firstIndex(where: { $0 != 2 }) else {
            preconditionFailure("The quiz must include an incorrect choice. / В тесте должен быть неправильный вариант.")
        }
        attempt.select(displayedIndex: wrongDisplayIndex)
        precondition(attempt.selectedOriginalIndex == firstOrder[wrongDisplayIndex])
        precondition(!attempt.canComplete && attempt.canRetry)

        let firstSelection = attempt.selectedOriginalIndex
        attempt.select(displayedIndex: firstOrder.firstIndex(of: 2)!)
        precondition(
            attempt.selectedOriginalIndex == firstSelection,
            "An answered attempt must stay locked until retry. / После ответа попытка блокируется до повтора."
        )

        var retryGenerator = SeededGenerator(seed: 241)
        attempt.retry(using: &retryGenerator)
        precondition(attempt.selectedOriginalIndex == nil && !attempt.canComplete && !attempt.canRetry)
        guard let correctDisplayIndex = attempt.choiceOrder.displayedOriginalIndices.firstIndex(of: 2) else {
            preconditionFailure("Retry must preserve the correct answer mapping. / Повтор должен сохранять соответствие правильного ответа.")
        }
        attempt.select(displayedIndex: correctDisplayIndex)
        precondition(attempt.isCorrect && attempt.canComplete && !attempt.canRetry)

        print("Answer choice order checks passed. / Проверки порядка вариантов прошли.")
    }
}
