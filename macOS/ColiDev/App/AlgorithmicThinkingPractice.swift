import Foundation

struct AlgorithmicThinkingQuestion: Equatable, Identifiable {
    let id: String
    let choiceKeys: [String]
    let correctOptionIndex: Int
}

enum AlgorithmicThinkingPractice {
    static let questions = [
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.step.input",
            choiceKeys: ["compare", "input", "display"],
            correctOptionIndex: 1
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.step.compare",
            choiceKeys: ["otherwise", "compare", "display"],
            correctOptionIndex: 1
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.step.otherwise",
            choiceKeys: ["display", "otherwise", "input"],
            correctOptionIndex: 1
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.step.display",
            choiceKeys: ["display", "compare", "input"],
            correctOptionIndex: 0
        )
    ]

    static func answerOrders<Generator: RandomNumberGenerator>(using generator: inout Generator) -> [QuizAnswerOrder] {
        QuizAnswerOrder.balancedSequence(
            optionCount: 3,
            answerOriginalIndices: questions.map(\.correctOptionIndex),
            using: &generator
        )
    }

    static func makeAnswerOrders() -> [QuizAnswerOrder] {
        var generator = SystemRandomNumberGenerator()
        return answerOrders(using: &generator)
    }
}

struct AlgorithmicThinkingSubmission: Equatable {
    let stepKey: String
    let isCorrect: Bool
    let evidence: StudyAssessmentEvidence?
}

struct AlgorithmicThinkingPracticeSession {
    private(set) var completedStepKeys: [String] = []
    private(set) var answerOrders: [QuizAnswerOrder]
    private var assessmentTracker: InteractiveChoiceAssessmentTracker

    var isComplete: Bool { completedStepKeys.count == AlgorithmicThinkingPractice.questions.count }

    var displayedChoiceKeys: [String] {
        let index = completedStepKeys.count
        guard !isComplete, answerOrders.indices.contains(index) else { return [] }
        let question = AlgorithmicThinkingPractice.questions[index]
        return answerOrders[index].displayedOriginalIndices.map { question.choiceKeys[$0] }
    }

    init(answerOrders: [QuizAnswerOrder] = AlgorithmicThinkingPractice.makeAnswerOrders()) {
        precondition(answerOrders.count == AlgorithmicThinkingPractice.questions.count)
        self.answerOrders = answerOrders
        assessmentTracker = InteractiveChoiceAssessmentTracker(
            itemIDs: AlgorithmicThinkingPractice.questions.map(\.id)
        )
    }

    mutating func submit(displayedIndex: Int) -> AlgorithmicThinkingSubmission? {
        let stepIndex = completedStepKeys.count
        guard !isComplete,
              AlgorithmicThinkingPractice.questions.indices.contains(stepIndex),
              answerOrders.indices.contains(stepIndex),
              answerOrders[stepIndex].displayedOriginalIndices.indices.contains(displayedIndex) else { return nil }

        let question = AlgorithmicThinkingPractice.questions[stepIndex]
        let selectedOriginalIndex = answerOrders[stepIndex].displayedOriginalIndices[displayedIndex]
        let isCorrect = selectedOriginalIndex == question.correctOptionIndex
        let evidence = assessmentTracker.recordSubmission(
            selectedAnswerIndex: selectedOriginalIndex,
            correctAnswerIndex: question.correctOptionIndex,
            optionCount: question.choiceKeys.count,
            itemID: question.id
        )
        let stepKey = question.choiceKeys[selectedOriginalIndex]
        if isCorrect { completedStepKeys.append(stepKey) }
        return AlgorithmicThinkingSubmission(stepKey: stepKey, isCorrect: isCorrect, evidence: evidence)
    }

    mutating func restart() {
        completedStepKeys = []
        answerOrders = AlgorithmicThinkingPractice.makeAnswerOrders()
        assessmentTracker.reset()
    }
}
