import Foundation

struct AnswerChoiceOrder: Equatable {
    private(set) var displayedOriginalIndices: [Int]

    init(optionCount: Int) {
        var generator = SystemRandomNumberGenerator()
        self.init(optionCount: optionCount, using: &generator)
    }

    init<Generator: RandomNumberGenerator>(optionCount: Int, using generator: inout Generator) {
        precondition(optionCount > 0, "A multiple-choice question needs at least one option.")
        displayedOriginalIndices = Array(0..<optionCount).shuffled(using: &generator)
    }

    init<Generator: RandomNumberGenerator>(
        optionCount: Int,
        placingOriginalIndex originalIndex: Int,
        atDisplayedIndex displayedIndex: Int,
        using generator: inout Generator
    ) {
        precondition(
            optionCount > 0 && (0..<optionCount).contains(originalIndex) && (0..<optionCount).contains(displayedIndex),
            "A pinned answer must refer to a valid option and display slot. / Закреплённый ответ должен ссылаться на существующий вариант и позицию."
        )

        var displayedIndices = Array<Int?>(repeating: nil, count: optionCount)
        displayedIndices[displayedIndex] = originalIndex
        var distractors = (0..<optionCount).filter { $0 != originalIndex }
        distractors.shuffle(using: &generator)

        var distractorIndex = 0
        for index in displayedIndices.indices where displayedIndices[index] == nil {
            displayedIndices[index] = distractors[distractorIndex]
            distractorIndex += 1
        }
        self.displayedOriginalIndices = displayedIndices.map { $0! }
    }

    mutating func reshuffle() {
        var generator = SystemRandomNumberGenerator()
        reshuffle(using: &generator)
    }

    mutating func reshuffle<Generator: RandomNumberGenerator>(using generator: inout Generator) {
        displayedOriginalIndices = Array(displayedOriginalIndices.indices).shuffled(using: &generator)
    }

    func originalIndex(forDisplayedIndex index: Int) -> Int? {
        guard displayedOriginalIndices.indices.contains(index) else { return nil }
        return displayedOriginalIndices[index]
    }

    func isCorrect(displayedIndex: Int, answerOriginalIndex: Int) -> Bool {
        originalIndex(forDisplayedIndex: displayedIndex) == answerOriginalIndex
    }
}

struct QuizAnswerOrder: Equatable {
    let answerOriginalIndex: Int
    private let choiceOrder: AnswerChoiceOrder

    var displayedOriginalIndices: [Int] { choiceOrder.displayedOriginalIndices }
    var correctDisplayedIndex: Int { displayedOriginalIndices.firstIndex(of: answerOriginalIndex)! }

    init(optionCount: Int, answerOriginalIndex: Int) {
        precondition(optionCount > 0 && (0..<optionCount).contains(answerOriginalIndex), "The answer index must match an option.")
        var generator = SystemRandomNumberGenerator()
        self.init(optionCount: optionCount, answerOriginalIndex: answerOriginalIndex, using: &generator)
    }

    init<Generator: RandomNumberGenerator>(
        optionCount: Int,
        answerOriginalIndex: Int,
        using generator: inout Generator
    ) {
        precondition(optionCount > 0 && (0..<optionCount).contains(answerOriginalIndex), "The answer index must match an option.")
        self.answerOriginalIndex = answerOriginalIndex
        choiceOrder = AnswerChoiceOrder(optionCount: optionCount, using: &generator)
    }

    private init<Generator: RandomNumberGenerator>(
        optionCount: Int,
        answerOriginalIndex: Int,
        correctDisplayedIndex: Int,
        using generator: inout Generator
    ) {
        precondition(
            optionCount > 0 && (0..<optionCount).contains(answerOriginalIndex) && (0..<optionCount).contains(correctDisplayedIndex),
            "A balanced answer slot must refer to a valid option. / Сбалансированная позиция должна ссылаться на существующий вариант."
        )
        self.answerOriginalIndex = answerOriginalIndex
        choiceOrder = AnswerChoiceOrder(
            optionCount: optionCount,
            placingOriginalIndex: answerOriginalIndex,
            atDisplayedIndex: correctDisplayedIndex,
            using: &generator
        )
    }

    static func balancedSequence(optionCount: Int, answerOriginalIndices: [Int]) -> [QuizAnswerOrder] {
        var generator = SystemRandomNumberGenerator()
        return balancedSequence(optionCount: optionCount, answerOriginalIndices: answerOriginalIndices, using: &generator)
    }

    static func balancedSequence<Generator: RandomNumberGenerator>(
        optionCount: Int,
        answerOriginalIndices: [Int],
        using generator: inout Generator
    ) -> [QuizAnswerOrder] {
        precondition(optionCount > 0, "A multiple-choice question needs at least one option.")

        var positionCounts = Array(repeating: 0, count: optionCount)
        var previousPosition: Int?
        var orders: [QuizAnswerOrder] = []
        orders.reserveCapacity(answerOriginalIndices.count)

        for answerOriginalIndex in answerOriginalIndices {
            precondition(
                (0..<optionCount).contains(answerOriginalIndex),
                "Every answer must match an available option. / Каждый правильный ответ должен соответствовать одному из вариантов."
            )

            var eligiblePositions = Array(0..<optionCount)
            if optionCount > 1, let previousPosition {
                eligiblePositions.removeAll { $0 == previousPosition }
            }
            let leastUsedCount = eligiblePositions.map { positionCounts[$0] }.min()!
            let leastUsedPositions = eligiblePositions.filter { positionCounts[$0] == leastUsedCount }
            let displayedIndex = leastUsedPositions.randomElement(using: &generator)!

            orders.append(QuizAnswerOrder(
                optionCount: optionCount,
                answerOriginalIndex: answerOriginalIndex,
                correctDisplayedIndex: displayedIndex,
                using: &generator
            ))
            positionCounts[displayedIndex] += 1
            previousPosition = displayedIndex
        }

        return orders
    }

    func originalIndex(forDisplayedIndex index: Int) -> Int? {
        choiceOrder.originalIndex(forDisplayedIndex: index)
    }

    func isCorrect(displayedIndex: Int) -> Bool {
        choiceOrder.isCorrect(displayedIndex: displayedIndex, answerOriginalIndex: answerOriginalIndex)
    }
}

enum StudyErrorCategory: String, CaseIterable, Codable, Equatable, Identifiable {
    case understanding
    case memory
    case application
    case attention
    case logic
    case foundation
    case method

    var id: String { rawValue }
    var titleKey: String { "module.errorCategory.\(rawValue)" }
    var guidanceKey: String { "module.errorGuidance.\(rawValue)" }
}

struct CurriculumCheckAttempt: Equatable {
    let answerOriginalIndex: Int
    private(set) var choiceOrder: AnswerChoiceOrder
    private(set) var selectedOriginalIndex: Int?
    private(set) var attemptCount: Int
    private(set) var firstTryCorrect: Bool?
    private(set) var reportedErrorCategories: [StudyErrorCategory]

    var isCorrect: Bool { selectedOriginalIndex == answerOriginalIndex }
    var canComplete: Bool { isCorrect }
    var canRetry: Bool { selectedOriginalIndex != nil && !isCorrect }
    var hasAnswered: Bool { selectedOriginalIndex != nil }
    var assessmentEvidence: StudyAssessmentEvidence? {
        guard canComplete, attemptCount > 0, let firstTryCorrect else { return nil }
        return StudyAssessmentEvidence(
            taskType: "knowledge_check",
            attempts: attemptCount,
            firstTryCorrect: firstTryCorrect,
            hintsUsed: 0,
            errorCategories: reportedErrorCategories.isEmpty ? nil : reportedErrorCategories
        )
    }

    func currentAnswerEventEvidence(errorCategory: StudyErrorCategory? = nil) -> StudyAssessmentEvidence? {
        guard hasAnswered else { return nil }
        return StudyAssessmentEvidence(
            taskType: "knowledge_check",
            attempts: 1,
            firstTryCorrect: isCorrect,
            hintsUsed: 0,
            errorCategories: errorCategory.map { [$0] },
            passed: isCorrect
        )
    }

    init?(optionCount: Int, answerOriginalIndex: Int) {
        var generator = SystemRandomNumberGenerator()
        self.init(optionCount: optionCount, answerOriginalIndex: answerOriginalIndex, using: &generator)
    }

    init?<Generator: RandomNumberGenerator>(
        optionCount: Int,
        answerOriginalIndex: Int,
        using generator: inout Generator
    ) {
        guard optionCount > 0, (0..<optionCount).contains(answerOriginalIndex) else { return nil }
        self.answerOriginalIndex = answerOriginalIndex
        choiceOrder = AnswerChoiceOrder(optionCount: optionCount, using: &generator)
        selectedOriginalIndex = nil
        attemptCount = 0
        firstTryCorrect = nil
        reportedErrorCategories = []
    }

    mutating func select(displayedIndex: Int) {
        guard !hasAnswered,
              let originalIndex = choiceOrder.originalIndex(forDisplayedIndex: displayedIndex) else { return }
        selectedOriginalIndex = originalIndex
        attemptCount += 1
        if firstTryCorrect == nil {
            firstTryCorrect = originalIndex == answerOriginalIndex
        }
    }

    mutating func retry(errorCategory: StudyErrorCategory? = nil) {
        var generator = SystemRandomNumberGenerator()
        retry(errorCategory: errorCategory, using: &generator)
    }

    mutating func retry<Generator: RandomNumberGenerator>(
        errorCategory: StudyErrorCategory? = nil,
        using generator: inout Generator
    ) {
        guard canRetry else { return }
        if let errorCategory {
            reportedErrorCategories.append(errorCategory)
        }
        choiceOrder = AnswerChoiceOrder(optionCount: choiceOrder.displayedOriginalIndices.count, using: &generator)
        selectedOriginalIndex = nil
    }
}

struct InteractivePredictionAttempt: Equatable {
    let answerOriginalIndex: Int
    private(set) var choiceOrder: AnswerChoiceOrder
    private(set) var selectedOriginalIndex: Int?
    private(set) var attemptCount: Int
    private(set) var firstTryCorrect: Bool?
    private(set) var hintsUsed: Int

    var hasAnswered: Bool { selectedOriginalIndex != nil }
    var isCorrect: Bool { selectedOriginalIndex == answerOriginalIndex }
    var canRetry: Bool { hasAnswered && !isCorrect }

    init?(optionCount: Int, answerOriginalIndex: Int) {
        var generator = SystemRandomNumberGenerator()
        self.init(optionCount: optionCount, answerOriginalIndex: answerOriginalIndex, using: &generator)
    }

    init?<Generator: RandomNumberGenerator>(
        optionCount: Int,
        answerOriginalIndex: Int,
        using generator: inout Generator
    ) {
        guard optionCount > 0, (0..<optionCount).contains(answerOriginalIndex) else { return nil }
        self.answerOriginalIndex = answerOriginalIndex
        choiceOrder = AnswerChoiceOrder(optionCount: optionCount, using: &generator)
        selectedOriginalIndex = nil
        attemptCount = 0
        firstTryCorrect = nil
        hintsUsed = 0
    }

    mutating func select(displayedIndex: Int) {
        guard !hasAnswered,
              let originalIndex = choiceOrder.originalIndex(forDisplayedIndex: displayedIndex) else { return }
        selectedOriginalIndex = originalIndex
        attemptCount += 1
        if firstTryCorrect == nil {
            firstTryCorrect = originalIndex == answerOriginalIndex
        }
        if originalIndex != answerOriginalIndex {
            hintsUsed += 1
        }
    }

    mutating func retry() {
        var generator = SystemRandomNumberGenerator()
        retry(using: &generator)
    }

    mutating func retry<Generator: RandomNumberGenerator>(using generator: inout Generator) {
        guard canRetry else { return }
        choiceOrder = AnswerChoiceOrder(optionCount: choiceOrder.displayedOriginalIndices.count, using: &generator)
        selectedOriginalIndex = nil
    }

    func currentAnswerEventEvidence() -> StudyAssessmentEvidence? {
        guard hasAnswered, let firstTryCorrect else { return nil }
        return StudyAssessmentEvidence(
            taskType: "interactive_prediction",
            attempts: attemptCount,
            firstTryCorrect: firstTryCorrect,
            hintsUsed: hintsUsed
        )
    }
}

struct StudyAssessmentEvidence: Codable, Equatable {
    let taskType: String
    let attempts: Int
    let firstTryCorrect: Bool
    let hintsUsed: Int
    let errorCategories: [StudyErrorCategory]?
    let passed: Bool?

    init(
        taskType: String,
        attempts: Int,
        firstTryCorrect: Bool,
        hintsUsed: Int,
        errorCategories: [StudyErrorCategory]? = nil,
        passed: Bool? = nil
    ) {
        self.taskType = taskType
        self.attempts = attempts
        self.firstTryCorrect = firstTryCorrect
        self.hintsUsed = hintsUsed
        self.errorCategories = errorCategories
        self.passed = passed
    }

    enum CodingKeys: String, CodingKey {
        case taskType = "task_type"
        case attempts
        case firstTryCorrect = "first_try_correct"
        case hintsUsed = "hints_used"
        case errorCategories = "error_categories"
        case passed
    }
}

struct StudyAssessmentEvent: Codable, Identifiable {
    let id: String
    let lessonID: String
    let assessment: StudyAssessmentEvidence

    enum CodingKeys: String, CodingKey {
        case id = "event_id"
        case lessonID = "lesson_id"
        case assessment
    }
}

struct LessonAnswerFeedback: Equatable {
    let statusMessage: String
    let explanation: String?
    let canRevealExplanation: Bool

    static func presentation(
        isCorrect: Bool,
        explanationRevealed: Bool = false,
        explanation: String,
        correctPrompt: String,
        retryPrompt: String
    ) -> LessonAnswerFeedback {
        let cleanedExplanation = explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        let availableExplanation = cleanedExplanation.isEmpty ? nil : cleanedExplanation

        if isCorrect {
            return LessonAnswerFeedback(
                statusMessage: correctPrompt,
                explanation: availableExplanation,
                canRevealExplanation: false
            )
        }

        return LessonAnswerFeedback(
            statusMessage: retryPrompt,
            explanation: explanationRevealed ? availableExplanation : nil,
            canRevealExplanation: !explanationRevealed && availableExplanation != nil
        )
    }
}
