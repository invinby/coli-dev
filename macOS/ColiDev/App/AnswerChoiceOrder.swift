import Foundation

struct AnswerChoiceOrder: Equatable {
    let displayedOriginalIndices: [Int]

    init(optionCount: Int) {
        var generator = SystemRandomNumberGenerator()
        self.init(optionCount: optionCount, using: &generator)
    }

    init<Generator: RandomNumberGenerator>(optionCount: Int, using generator: inout Generator) {
        precondition(optionCount > 0, "A multiple-choice question needs at least one option.")
        displayedOriginalIndices = Array(0..<optionCount).shuffled(using: &generator)
    }

    func originalIndex(forDisplayedIndex index: Int) -> Int? {
        guard displayedOriginalIndices.indices.contains(index) else { return nil }
        return displayedOriginalIndices[index]
    }

    func isCorrect(displayedIndex: Int, answerOriginalIndex: Int) -> Bool {
        originalIndex(forDisplayedIndex: displayedIndex) == answerOriginalIndex
    }
}
