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

print("Answer choice order checks passed. / Проверки порядка вариантов прошли.")
