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

struct EnglishBeQuestion: Equatable, Identifiable {
    let id: String
    let prompt: String
    let translation: String
    let options: [String]
    let correctOption: Int
    let hintRussian: String
    let hintEnglish: String
    let explanationRussian: String
    let explanationEnglish: String
}

enum EnglishBePractice {
    static let questions = [
        EnglishBeQuestion(
            id: "i-am",
            prompt: "I ___ in the beginner group.",
            translation: "Я занимаюсь в группе для начинающих.",
            options: ["am", "is", "are"],
            correctOption: 0,
            hintRussian: "Найди форму be, которая употребляется с местоимением I.",
            hintEnglish: "Find the form of be used with the pronoun I.",
            explanationRussian: "С I употребляется am: I am. В разговорной речи часто пишут I'm.",
            explanationEnglish: "Use am with I: I am. In speech and informal writing, this is often I'm."
        ),
        EnglishBeQuestion(
            id: "she-is",
            prompt: "She ___ our English tutor.",
            translation: "Она — наш репетитор по английскому.",
            options: ["am", "is", "are"],
            correctOption: 1,
            hintRussian: "She — местоимение третьего лица единственного числа.",
            hintEnglish: "She is a third-person singular pronoun.",
            explanationRussian: "С he, she и it в настоящем времени употребляется is: she is.",
            explanationEnglish: "Use is with he, she, and it in the present: she is."
        ),
        EnglishBeQuestion(
            id: "you-are",
            prompt: "You ___ early today.",
            translation: "Ты сегодня пришёл / пришла рано.",
            options: ["am", "is", "are"],
            correctOption: 2,
            hintRussian: "В английском you сочетается с are и для одного собеседника, и для нескольких.",
            hintEnglish: "In English, you takes are for one person and for more than one person.",
            explanationRussian: "Форма you are используется и при обращении к одному человеку, и к нескольким.",
            explanationEnglish: "Use you are when speaking to one person or to a group."
        ),
        EnglishBeQuestion(
            id: "we-are",
            prompt: "Amina and I are in one class. ___ classmates.",
            translation: "Амина и я занимаемся в одной группе. Мы одногруппники.",
            options: ["They are", "We are", "We is"],
            correctOption: 1,
            hintRussian: "Говорящий включён в группу «Амина и я» — выбери местоимение от лица группы.",
            hintEnglish: "The speaker is part of “Amina and I”; choose the pronoun from the group's point of view.",
            explanationRussian: "Когда говорящий включён в группу, используется we; с we нужна форма are.",
            explanationEnglish: "When the speaker is part of the group, use we; we takes are."
        ),
        EnglishBeQuestion(
            id: "plural-negative",
            prompt: "The two books ___ not on the desk.",
            translation: "Двух книг нет на столе.",
            options: ["is", "are", "am"],
            correctOption: 1,
            hintRussian: "Подлежащее состоит из двух книг; отрицание ставится после формы be.",
            hintEnglish: "The subject is two books; the negative comes after the form of be.",
            explanationRussian: "Множественное подлежащее требует are; отрицательная форма — are not (aren't).",
            explanationEnglish: "A plural subject takes are; the negative is are not (aren't)."
        ),
        EnglishBeQuestion(
            id: "inverted-question",
            prompt: "___ they at the library now?",
            translation: "Они сейчас в библиотеке?",
            options: ["Am", "Is", "Are"],
            correctOption: 2,
            hintRussian: "В вопросе с be поставь am, is или are перед подлежащим they.",
            hintEnglish: "In a question with be, put am, is, or are before the subject they.",
            explanationRussian: "В вопросе форма be стоит перед подлежащим: Are they ...?",
            explanationEnglish: "In a be question, put the verb before the subject: Are they ...?"
        ),
        EnglishBeQuestion(
            id: "short-answer",
            prompt: "Are your notes here? Yes, they ___.",
            translation: "Твои записи здесь? Да, они здесь.",
            options: ["is", "am", "are"],
            correctOption: 2,
            hintRussian: "Краткий ответ сохраняет форму, согласованную с they.",
            hintEnglish: "A short answer keeps the form that agrees with they.",
            explanationRussian: "В кратком ответе сохраняется are: Yes, they are. Обычно ответ не сокращают до they're.",
            explanationEnglish: "Keep are in the short answer: Yes, they are. Short positive answers do not normally contract it to they're."
        )
    ]

    static func isCorrect(_ option: Int, for questionID: String) -> Bool {
        guard let question = questions.first(where: { $0.id == questionID }),
              question.options.indices.contains(option) else { return false }
        return option == question.correctOption
    }
}

struct EnglishBeAssessmentTracker {
    private struct QuestionState {
        var attempts = 0
        var firstTryCorrect: Bool?
        var lastSubmittedOption: Int?
    }

    private var questionStates: [String: QuestionState] = [:]

    mutating func recordSubmission(option: Int, for questionID: String) -> StudyAssessmentEvidence? {
        guard let question = EnglishBePractice.questions.first(where: { $0.id == questionID }),
              question.options.indices.contains(option) else { return nil }

        var state = questionStates[questionID] ?? QuestionState()
        guard state.lastSubmittedOption != option else { return nil }

        let isCorrect = option == question.correctOption
        state.attempts += 1
        if state.firstTryCorrect == nil { state.firstTryCorrect = isCorrect }
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
