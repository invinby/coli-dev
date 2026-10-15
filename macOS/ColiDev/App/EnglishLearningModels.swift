import Foundation

enum EnglishConditionalForm: Int, CaseIterable, Hashable {
    case zero
    case first
    case second
}

struct EnglishConditionalScenario: Equatable, Identifiable {
    let id: String
    let correctForm: EnglishConditionalForm
}

enum EnglishConditionalPractice {
    static let scenarios = [
        EnglishConditionalScenario(id: "general-rule", correctForm: .zero),
        EnglishConditionalScenario(id: "real-future", correctForm: .first),
        EnglishConditionalScenario(id: "imagined-condition", correctForm: .second)
    ]

    static func isCorrect(_ selectedForm: EnglishConditionalForm, for scenarioID: String) -> Bool {
        guard let scenario = scenarios.first(where: { $0.id == scenarioID }) else { return false }
        return scenario.correctForm == selectedForm
    }
}

struct EnglishConditionalAssessmentTracker {
    private struct ScenarioState {
        var attempts = 0
        var firstTryCorrect: Bool?
        var lastSubmittedForm: EnglishConditionalForm?
    }

    private var scenarioStates: [String: ScenarioState] = [:]

    mutating func recordSubmission(form: EnglishConditionalForm, for scenarioID: String) -> StudyAssessmentEvidence? {
        guard let scenario = EnglishConditionalPractice.scenarios.first(where: { $0.id == scenarioID }) else {
            return nil
        }

        var state = scenarioStates[scenarioID] ?? ScenarioState()
        guard state.lastSubmittedForm != form else { return nil }

        let isCorrect = scenario.correctForm == form
        state.attempts += 1
        if state.firstTryCorrect == nil {
            state.firstTryCorrect = isCorrect
        }
        state.lastSubmittedForm = form
        scenarioStates[scenarioID] = state

        return StudyAssessmentEvidence(
            taskType: "interactive_practice",
            attempts: state.attempts,
            firstTryCorrect: state.firstTryCorrect ?? isCorrect,
            hintsUsed: 0,
            itemID: scenarioID
        )
    }

    mutating func reset() {
        scenarioStates.removeAll()
    }
}

struct EnglishReadingQuestion: Equatable, Identifiable {
    let id: String
    let correctOption: Int
}

enum EnglishReadingPractice {
    static let questions = [
        EnglishReadingQuestion(id: "first-pass-purpose", correctOption: 1),
        EnglishReadingQuestion(id: "meeting-detail", correctOption: 0),
        EnglishReadingQuestion(id: "unknown-word", correctOption: 2)
    ]

    static func isCorrect(_ option: Int, for questionID: String) -> Bool {
        guard let question = questions.first(where: { $0.id == questionID }) else { return false }
        return option == question.correctOption
    }
}

struct EnglishReadingAssessmentTracker {
    private struct QuestionState {
        var attempts = 0
        var firstTryCorrect: Bool?
        var lastSubmittedOption: Int?
    }

    private var questionStates: [String: QuestionState] = [:]

    mutating func recordSubmission(option: Int, for questionID: String) -> StudyAssessmentEvidence? {
        guard (0..<3).contains(option),
              let question = EnglishReadingPractice.questions.first(where: { $0.id == questionID }) else {
            return nil
        }

        var state = questionStates[questionID] ?? QuestionState()
        guard state.lastSubmittedOption != option else { return nil }

        let isCorrect = option == question.correctOption
        state.attempts += 1
        if state.firstTryCorrect == nil {
            state.firstTryCorrect = isCorrect
        }
        state.lastSubmittedOption = option
        questionStates[questionID] = state

        return StudyAssessmentEvidence(
            taskType: "interactive_practice",
            attempts: state.attempts,
            firstTryCorrect: state.firstTryCorrect ?? isCorrect,
            hintsUsed: 0,
            itemID: questionID
        )
    }

    mutating func reset() {
        questionStates.removeAll()
    }
}

struct EnglishReportedSpeechQuestion: Equatable, Identifiable {
    let id: String
    let correctOption: Int
}

enum EnglishReportedSpeechPractice {
    static let questions = [
        EnglishReportedSpeechQuestion(id: "backshift-and-time-reference", correctOption: 1),
        EnglishReportedSpeechQuestion(id: "reported-wh-question", correctOption: 0),
        EnglishReportedSpeechQuestion(id: "reported-yes-no-question", correctOption: 2),
        EnglishReportedSpeechQuestion(id: "reported-request", correctOption: 1)
    ]

    static func isCorrect(_ option: Int, for questionID: String) -> Bool {
        guard let question = questions.first(where: { $0.id == questionID }) else { return false }
        return option == question.correctOption
    }
}

struct EnglishWordStressQuestion: Equatable, Identifiable {
    let id: String
    let word: String
    let correctOption: Int
    let spokenSentence: String
}

enum EnglishWordStressPractice {
    static let questions = [
        EnglishWordStressQuestion(
            id: "present-as-gift",
            word: "present",
            correctOption: 0,
            spokenSentence: "I received a present from the school."
        ),
        EnglishWordStressQuestion(
            id: "present-the-results",
            word: "present",
            correctOption: 1,
            spokenSentence: "She will present the results tomorrow."
        ),
        EnglishWordStressQuestion(
            id: "record-as-a-file",
            word: "record",
            correctOption: 0,
            spokenSentence: "The record is stored locally."
        ),
        EnglishWordStressQuestion(
            id: "record-the-audio",
            word: "record",
            correctOption: 1,
            spokenSentence: "Please record the result."
        )
    ]

    static func isCorrect(_ option: Int, for questionID: String) -> Bool {
        guard (0..<2).contains(option),
              let question = questions.first(where: { $0.id == questionID }) else {
            return false
        }
        return option == question.correctOption
    }
}

enum EnglishSpeechAccent: String, CaseIterable, Identifiable {
    case british = "en-GB"
    case american = "en-US"

    var id: String { rawValue }

    static func available(in installedLanguageCodes: [String]) -> [EnglishSpeechAccent] {
        let installed = Set(installedLanguageCodes)
        return allCases.filter { installed.contains($0.rawValue) }
    }
}

struct EnglishWordStressAssessmentTracker {
    private struct QuestionState {
        var attempts = 0
        var firstTryCorrect: Bool?
        var lastSubmittedOption: Int?
    }

    private var questionStates: [String: QuestionState] = [:]

    mutating func recordSubmission(option: Int, for questionID: String) -> StudyAssessmentEvidence? {
        guard (0..<2).contains(option),
              let question = EnglishWordStressPractice.questions.first(where: { $0.id == questionID }) else {
            return nil
        }

        var state = questionStates[questionID] ?? QuestionState()
        guard state.lastSubmittedOption != option else { return nil }

        let isCorrect = option == question.correctOption
        state.attempts += 1
        if state.firstTryCorrect == nil {
            state.firstTryCorrect = isCorrect
        }
        state.lastSubmittedOption = option
        questionStates[questionID] = state

        return StudyAssessmentEvidence(
            taskType: "interactive_practice",
            attempts: state.attempts,
            firstTryCorrect: state.firstTryCorrect ?? isCorrect,
            hintsUsed: 0,
            itemID: question.id
        )
    }

    mutating func reset() {
        questionStates.removeAll()
    }
}
