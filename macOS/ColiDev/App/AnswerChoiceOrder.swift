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

    func originalIndex(forDisplayedIndex index: Int) -> Int? {
        choiceOrder.originalIndex(forDisplayedIndex: index)
    }

    func isCorrect(displayedIndex: Int) -> Bool {
        choiceOrder.isCorrect(displayedIndex: displayedIndex, answerOriginalIndex: answerOriginalIndex)
    }
}

struct CurriculumCheckAttempt: Equatable {
    let answerOriginalIndex: Int
    private(set) var choiceOrder: AnswerChoiceOrder
    private(set) var selectedOriginalIndex: Int?
    private(set) var attemptCount: Int
    private(set) var firstTryCorrect: Bool?

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
            hintsUsed: 0
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

    mutating func retry() {
        var generator = SystemRandomNumberGenerator()
        retry(using: &generator)
    }

    mutating func retry<Generator: RandomNumberGenerator>(using generator: inout Generator) {
        guard canRetry else { return }
        choiceOrder = AnswerChoiceOrder(optionCount: choiceOrder.displayedOriginalIndices.count, using: &generator)
        selectedOriginalIndex = nil
    }
}

struct StudyAssessmentEvidence: Codable, Equatable {
    let taskType: String
    let attempts: Int
    let firstTryCorrect: Bool
    let hintsUsed: Int

    enum CodingKeys: String, CodingKey {
        case taskType = "task_type"
        case attempts
        case firstTryCorrect = "first_try_correct"
        case hintsUsed = "hints_used"
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

    static func presentation(
        isCorrect: Bool,
        correctFeedback: String,
        retryPrompt: String
    ) -> LessonAnswerFeedback {
        guard !isCorrect else {
            return LessonAnswerFeedback(statusMessage: correctFeedback, explanation: nil)
        }

        let explanation = correctFeedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : correctFeedback
        return LessonAnswerFeedback(statusMessage: retryPrompt, explanation: explanation)
    }
}
