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
