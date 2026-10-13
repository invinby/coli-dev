import Foundation

struct AlgorithmicThinkingQuestion: Equatable, Identifiable {
    let id: String
    let choiceKeys: [String]
    let correctOptionIndex: Int
    let contextKey: String
    let averageTestCaseID: String?

    init(
        id: String,
        choiceKeys: [String],
        correctOptionIndex: Int,
        contextKey: String = "lab.algorithm.context.maximum",
        averageTestCaseID: String? = nil
    ) {
        self.id = id
        self.choiceKeys = choiceKeys
        self.correctOptionIndex = correctOptionIndex
        self.contextKey = contextKey
        self.averageTestCaseID = averageTestCaseID
    }
}

enum AlgorithmicTestCaseCategory: Int, CaseIterable, Equatable {
    case typical
    case boundary
    case invalid

    var key: String {
        switch self {
        case .typical: "typical"
        case .boundary: "boundary"
        case .invalid: "invalid"
        }
    }
}

struct AlgorithmicAverageTestCase: Equatable, Identifiable {
    let id: String
    let values: [Int]
    let correctCategory: AlgorithmicTestCaseCategory
    let explanationKey: String
}

enum AlgorithmicThinkingPractice {
    static let averageTestCases = [
        AlgorithmicAverageTestCase(
            id: "typical",
            values: [2, 4, 6],
            correctCategory: .typical,
            explanationKey: "lab.algorithmTestCaseTypicalExplanation"
        ),
        AlgorithmicAverageTestCase(
            id: "single_value",
            values: [7],
            correctCategory: .boundary,
            explanationKey: "lab.algorithmTestCaseSingleExplanation"
        ),
        AlgorithmicAverageTestCase(
            id: "empty_list",
            values: [],
            correctCategory: .invalid,
            explanationKey: "lab.algorithmTestCaseEmptyExplanation"
        )
    ]

    private static let maximumQuestions = [
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

    private static let averageQuestions = [
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.average.check_nonempty",
            choiceKeys: ["initializeTotal", "checkNonempty", "returnAverage"],
            correctOptionIndex: 1,
            contextKey: "lab.algorithm.context.average"
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.average.initialize_total",
            choiceKeys: ["initializeTotal", "accumulateValues", "divideByCount"],
            correctOptionIndex: 0,
            contextKey: "lab.algorithm.context.average"
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.average.accumulate_values",
            choiceKeys: ["divideByCount", "accumulateValues", "returnAverage"],
            correctOptionIndex: 1,
            contextKey: "lab.algorithm.context.average"
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.average.divide_by_count",
            choiceKeys: ["returnAverage", "divideByCount", "initializeTotal"],
            correctOptionIndex: 1,
            contextKey: "lab.algorithm.context.average"
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.average.return_average",
            choiceKeys: ["returnAverage", "accumulateValues", "checkNonempty"],
            correctOptionIndex: 0,
            contextKey: "lab.algorithm.context.average"
        )
    ]

    private static let testCaseQuestions = averageTestCases.map { testCase in
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.tests.average.\(testCase.id)",
            choiceKeys: AlgorithmicTestCaseCategory.allCases.map(\.key),
            correctOptionIndex: testCase.correctCategory.rawValue,
            contextKey: "lab.algorithm.context.testDesign",
            averageTestCaseID: testCase.id
        )
    }

    static let maximumQuestionCount = maximumQuestions.count
    static let questions = maximumQuestions + averageQuestions + testCaseQuestions

    static func average(of values: [Int]) -> Double? {
        guard !values.isEmpty else { return nil }
        let total = values.reduce(0.0) { partial, value in partial + Double(value) }
        return total / Double(values.count)
    }

    static func averageTestCase(id: String) -> AlgorithmicAverageTestCase? {
        averageTestCases.first { $0.id == id }
    }

    static func averageTestCase(forQuestionID questionID: String) -> AlgorithmicAverageTestCase? {
        guard let testCaseID = questions.first(where: { $0.id == questionID })?.averageTestCaseID else { return nil }
        return averageTestCase(id: testCaseID)
    }

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
    let questionID: String
    let stepKey: String
    let isCorrect: Bool
    let evidence: StudyAssessmentEvidence?
}

struct AlgorithmicThinkingPracticeSession {
    private(set) var completedStepKeys: [String] = []
    private(set) var answerOrders: [QuizAnswerOrder]
    private var assessmentTracker: InteractiveChoiceAssessmentTracker

    var isComplete: Bool { completedStepKeys.count == AlgorithmicThinkingPractice.questions.count }
    var currentQuestion: AlgorithmicThinkingQuestion? {
        AlgorithmicThinkingPractice.questions.indices.contains(completedStepKeys.count)
            ? AlgorithmicThinkingPractice.questions[completedStepKeys.count]
            : nil
    }

    var displayedChoiceKeys: [String] {
        let index = completedStepKeys.count
        guard let question = currentQuestion, answerOrders.indices.contains(index) else { return [] }
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
        guard let question = currentQuestion,
              answerOrders.indices.contains(stepIndex),
              answerOrders[stepIndex].displayedOriginalIndices.indices.contains(displayedIndex) else { return nil }

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
        return AlgorithmicThinkingSubmission(
            questionID: question.id,
            stepKey: stepKey,
            isCorrect: isCorrect,
            evidence: evidence
        )
    }

    mutating func restart() {
        completedStepKeys = []
        answerOrders = AlgorithmicThinkingPractice.makeAnswerOrders()
        assessmentTracker.reset()
    }
}
