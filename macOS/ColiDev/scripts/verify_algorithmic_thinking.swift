import Foundation

struct AlgorithmicThinkingSeededGenerator: RandomNumberGenerator {
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
enum AlgorithmicThinkingVerification {
    static func main() {
        let questions = AlgorithmicThinkingPractice.questions
        let expectedIDs = [
            "programming.computational_thinking.step.input",
            "programming.computational_thinking.step.compare",
            "programming.computational_thinking.step.otherwise",
            "programming.computational_thinking.step.display",
            "programming.computational_thinking.average.check_nonempty",
            "programming.computational_thinking.average.initialize_total",
            "programming.computational_thinking.average.accumulate_values",
            "programming.computational_thinking.average.divide_by_count",
            "programming.computational_thinking.average.return_average",
            "programming.computational_thinking.tests.average.typical",
            "programming.computational_thinking.tests.average.single_value",
            "programming.computational_thinking.tests.average.empty_list"
        ]
        precondition(questions.map(\.id) == expectedIDs, "Practice must cover two algorithm types and three test-case classes with stable identities.")
        precondition(Set(questions.map(\.id)).count == questions.count, "Every pseudocode step needs a unique ID.")
        precondition(questions.map { $0.choiceKeys[$0.correctOptionIndex] } == [
            "input", "compare", "otherwise", "display",
            "checkNonempty", "initializeTotal", "accumulateValues", "divideByCount", "returnAverage",
            "typical", "boundary", "invalid"
        ])
        precondition(questions.allSatisfy { $0.choiceKeys.count == 3 && $0.choiceKeys.indices.contains($0.correctOptionIndex) })
        precondition(
            AlgorithmicThinkingPractice.averageTestCases.map(\.id) == ["typical", "single_value", "empty_list"]
                && AlgorithmicThinkingPractice.averageTestCases.map(\.correctCategory) == [.typical, .boundary, .invalid],
            "Average exercises must include a typical, one-item boundary, and invalid empty-list case."
        )
        precondition(AlgorithmicThinkingPractice.average(of: [2, 4, 6]) == 4)
        precondition(AlgorithmicThinkingPractice.average(of: [7]) == 7)
        precondition(AlgorithmicThinkingPractice.average(of: [-2, 2]) == 0)
        precondition(AlgorithmicThinkingPractice.average(of: []) == nil, "The empty-list contract must be explicit.")

        for seed in 0..<256 {
            var generator = AlgorithmicThinkingSeededGenerator(seed: UInt64(seed))
            let orders = AlgorithmicThinkingPractice.answerOrders(using: &generator)
            precondition(orders.count == questions.count, "Each step needs a displayed answer order.")
            let correctSlots = zip(questions, orders).map { pair in pair.1.correctDisplayedIndex }
            precondition(
                zip(correctSlots, correctSlots.dropFirst()).allSatisfy { pair in pair.0 != pair.1 },
                "Correct choices must not occupy the same slot on adjacent steps."
            )
            let counts = (0..<3).map { slot in correctSlots.filter { $0 == slot }.count }
            precondition((counts.max()! - counts.min()!) <= 1, "Correct answer slots must remain balanced across the full sequence.")

            for (question, order) in zip(questions, orders) {
                precondition(order.displayedOriginalIndices.sorted() == Array(question.choiceKeys.indices), "Every choice must appear exactly once.")
                precondition(order.displayedOriginalIndices[order.correctDisplayedIndex] == question.correctOptionIndex, "The displayed correct choice must map to the expected action.")
            }
        }

        var generator = AlgorithmicThinkingSeededGenerator(seed: 42)
        let orders = AlgorithmicThinkingPractice.answerOrders(using: &generator)
        var session = AlgorithmicThinkingPracticeSession(answerOrders: orders)
        let firstQuestion = questions[0]
        let firstOrder = orders[0]
        let wrongDisplayedIndex = firstOrder.displayedOriginalIndices.firstIndex { $0 != firstQuestion.correctOptionIndex }!
        let wrong = session.submit(displayedIndex: wrongDisplayedIndex)
        precondition(
            wrong?.evidence?.itemID == firstQuestion.id
                && wrong?.evidence?.attempts == 1
                && wrong?.evidence?.firstTryCorrect == false
                && wrong?.isCorrect == false,
            "A wrong displayed choice must produce evidence for the matching stable step ID."
        )
        precondition(
            session.submit(displayedIndex: wrongDisplayedIndex)?.evidence == nil,
            "Submitting the same choice again must not inflate saved attempts."
        )
        let correctDisplayedIndex = firstOrder.correctDisplayedIndex
        let retry = session.submit(displayedIndex: correctDisplayedIndex)
        precondition(
            retry?.stepKey == "input"
                && retry?.isCorrect == true
                && retry?.evidence?.itemID == firstQuestion.id
                && retry?.evidence?.attempts == 2
                && retry?.evidence?.firstTryCorrect == false,
            "A correct retry must retain the failed first attempt and complete the expected step."
        )

        for stepIndex in 1..<questions.count {
            let question = questions[stepIndex]
            let order = orders[stepIndex]
            let result = session.submit(displayedIndex: order.correctDisplayedIndex)
            precondition(
                result?.isCorrect == true
                    && result?.stepKey == question.choiceKeys[question.correctOptionIndex]
                    && result?.evidence?.itemID == question.id
                    && result?.evidence?.attempts == 1
                    && result?.evidence?.firstTryCorrect == true,
                "Each completed step must save its own first-try evidence."
            )
        }
        precondition(session.isComplete && session.completedStepKeys == [
            "input", "compare", "otherwise", "display",
            "checkNonempty", "initializeTotal", "accumulateValues", "divideByCount", "returnAverage",
            "typical", "boundary", "invalid"
        ])
        precondition(session.displayedChoiceKeys.isEmpty && session.submit(displayedIndex: 0) == nil)

        var caseSession = AlgorithmicThinkingPracticeSession(answerOrders: orders)
        for index in 0..<9 {
            precondition(caseSession.submit(displayedIndex: orders[index].correctDisplayedIndex)?.isCorrect == true)
        }
        let caseQuestion = questions[9]
        let caseOrder = orders[9]
        let wrongCategoryIndex = caseOrder.displayedOriginalIndices.firstIndex { $0 != caseQuestion.correctOptionIndex }!
        let wrongCategory = caseSession.submit(displayedIndex: wrongCategoryIndex)
        precondition(
            wrongCategory?.questionID == caseQuestion.id
                && wrongCategory?.evidence?.itemID == caseQuestion.id
                && wrongCategory?.evidence?.attempts == 1
                && wrongCategory?.evidence?.firstTryCorrect == false,
            "A wrong test-case category must save evidence against that stable case ID."
        )
        let correctCategory = caseSession.submit(displayedIndex: caseOrder.correctDisplayedIndex)
        precondition(
            correctCategory?.stepKey == "typical"
                && correctCategory?.isCorrect == true
                && correctCategory?.evidence?.itemID == caseQuestion.id
                && correctCategory?.evidence?.attempts == 2
                && correctCategory?.evidence?.firstTryCorrect == false,
            "Retrying a test-case classification must preserve the first incorrect attempt."
        )
        print("Algorithmic-thinking model checks passed")
    }
}
