import Foundation

enum AppLanguage {
    case ru
    case en
}

@main
enum TenseContrastFeedbackVerification {
    static func main() {
        let cases: [(scenario: Int, isCorrect: Bool, expectedKey: String)] = [
            (0, true, "lab.tenseExplanation.0.correct"),
            (0, false, "lab.tenseExplanation.0.incorrect"),
            (1, true, "lab.tenseExplanation.1.correct"),
            (1, false, "lab.tenseExplanation.1.incorrect")
        ]

        for testCase in cases {
            guard let key = TenseContrastFeedback.explanationKey(
                scenario: testCase.scenario,
                isCorrect: testCase.isCorrect
            ) else {
                preconditionFailure("A supported tense scenario must provide feedback. / Для поддерживаемого сценария времён нужен разбор ответа.")
            }
            precondition(
                key == testCase.expectedKey,
                "Feedback must match the selected scenario and answer result. / Разбор должен соответствовать выбранному сценарию и результату ответа."
            )

            let russian = L10n.text(key, .ru)
            let english = L10n.text(key, .en)
            precondition(
                russian != key && english != key && russian != english,
                "Every tense explanation needs distinct Russian and English copy. / Для каждого разбора нужен отдельный русский и английский текст."
            )
        }

        for unsupportedScenario in [-1, 2] {
            precondition(
                TenseContrastFeedback.explanationKey(scenario: unsupportedScenario, isCorrect: true) == nil,
                "Unsupported scenarios must not borrow another question's explanation. / Неподдерживаемый сценарий не должен брать разбор от другого вопроса."
            )
        }
    }
}
