import Foundation

struct AlgorithmicThinkingQuestion: Equatable, Identifiable {
    let id: String
    let choiceKeys: [String]
    let correctOptionIndex: Int
    let contextKey: String
    let averageTestCaseID: String?
    let maximumTestCaseID: String?

    init(
        id: String,
        choiceKeys: [String],
        correctOptionIndex: Int,
        contextKey: String = "lab.algorithm.context.maximum",
        averageTestCaseID: String? = nil,
        maximumTestCaseID: String? = nil
    ) {
        self.id = id
        self.choiceKeys = choiceKeys
        self.correctOptionIndex = correctOptionIndex
        self.contextKey = contextKey
        self.averageTestCaseID = averageTestCaseID
        self.maximumTestCaseID = maximumTestCaseID
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

struct AlgorithmicMaximumTestCase: Equatable, Identifiable {
    let id: String
    let values: [Int]
    let answerChoiceKeys: [String]
    let expectedMaximum: Int?
    let correctOptionIndex: Int
    let explanationKey: String
}

enum AlgorithmicThinkingPractice {
    static let maximumListValues = [-8, -2, -5]

    static let maximumTestCases = [
        AlgorithmicMaximumTestCase(
            id: "typical_maximum_at_end",
            values: [2, 4, 9],
            answerChoiceKeys: ["lab.algorithmMaximumResult2", "lab.algorithmMaximumResult9", "lab.algorithmEmptyError"],
            expectedMaximum: 9,
            correctOptionIndex: 1,
            explanationKey: "lab.algorithmMaximumTypicalExplanation"
        ),
        AlgorithmicMaximumTestCase(
            id: "single_value",
            values: [7],
            answerChoiceKeys: ["lab.algorithmMaximumResult7", "lab.algorithmMaximumResult0", "lab.algorithmEmptyError"],
            expectedMaximum: 7,
            correctOptionIndex: 0,
            explanationKey: "lab.algorithmMaximumSingleExplanation"
        ),
        AlgorithmicMaximumTestCase(
            id: "all_negative",
            values: [-8, -2, -5],
            answerChoiceKeys: ["lab.algorithmMaximumResult0", "lab.algorithmMaximumResultMinus2", "lab.algorithmMaximumResultMinus8"],
            expectedMaximum: -2,
            correctOptionIndex: 1,
            explanationKey: "lab.algorithmMaximumNegativeExplanation"
        ),
        AlgorithmicMaximumTestCase(
            id: "repeated_maximum",
            values: [3, 9, 9],
            answerChoiceKeys: ["lab.algorithmMaximumResult3", "lab.algorithmMaximumResult9", "lab.algorithmEmptyError"],
            expectedMaximum: 9,
            correctOptionIndex: 1,
            explanationKey: "lab.algorithmMaximumRepeatedExplanation"
        ),
        AlgorithmicMaximumTestCase(
            id: "empty_list",
            values: [],
            answerChoiceKeys: ["lab.algorithmMaximumResult0", "lab.algorithmMaximumResultMinusOne", "lab.algorithmEmptyError"],
            expectedMaximum: nil,
            correctOptionIndex: 2,
            explanationKey: "lab.algorithmMaximumEmptyExplanation"
        )
    ]

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
        ),
        AlgorithmicAverageTestCase(
            id: "negative_cancellation",
            values: [-2, 2],
            correctCategory: .typical,
            explanationKey: "lab.algorithmTestCaseNegativeCancellationExplanation"
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

    private static let maximumListQuestions = [
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.maximum_list.check_nonempty",
            choiceKeys: ["checkNonemptyList", "initializeCurrentMaximum", "returnMaximum"],
            correctOptionIndex: 0,
            contextKey: "lab.algorithm.context.maximumList"
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.maximum_list.initialize_current_maximum",
            choiceKeys: ["initializeCurrentMaximum", "initializeFromZero", "inspectRemainingValues"],
            correctOptionIndex: 0,
            contextKey: "lab.algorithm.context.maximumList"
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.maximum_list.inspect_remaining_values",
            choiceKeys: ["returnMaximum", "inspectRemainingValues", "checkNonemptyList"],
            correctOptionIndex: 1,
            contextKey: "lab.algorithm.context.maximumList"
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.maximum_list.update_if_greater",
            choiceKeys: ["updateIfGreater", "initializeFromZero", "returnMaximum"],
            correctOptionIndex: 0,
            contextKey: "lab.algorithm.context.maximumList"
        ),
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.maximum_list.return_maximum",
            choiceKeys: ["returnMaximum", "inspectRemainingValues", "checkNonemptyList"],
            correctOptionIndex: 0,
            contextKey: "lab.algorithm.context.maximumList"
        )
    ]

    private static let maximumTestCaseQuestions = maximumTestCases.map { testCase in
        AlgorithmicThinkingQuestion(
            id: "programming.computational_thinking.tests.maximum_list.\(testCase.id)",
            choiceKeys: testCase.answerChoiceKeys,
            correctOptionIndex: testCase.correctOptionIndex,
            contextKey: "lab.algorithm.context.maximumListTests",
            maximumTestCaseID: testCase.id
        )
    }

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

    static let maximumAlgorithmQuestionCount = maximumQuestions.count + maximumListQuestions.count
    static let maximumSectionQuestionCount = maximumAlgorithmQuestionCount + maximumTestCaseQuestions.count
    static let questions = maximumQuestions + maximumListQuestions + maximumTestCaseQuestions + averageQuestions + testCaseQuestions

    static func showsMaximumExperiment(completedQuestionCount: Int) -> Bool {
        completedQuestionCount >= maximumAlgorithmQuestionCount
    }

    static func showsMaximumTestResults(completedQuestionCount: Int) -> Bool {
        completedQuestionCount >= maximumSectionQuestionCount
    }

    static func maximum(of values: [Int]) -> Int? {
        values.max()
    }

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

    static func maximumTestCase(forQuestionID questionID: String) -> AlgorithmicMaximumTestCase? {
        guard let testCaseID = questions.first(where: { $0.id == questionID })?.maximumTestCaseID else { return nil }
        return maximumTestCases.first { $0.id == testCaseID }
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
