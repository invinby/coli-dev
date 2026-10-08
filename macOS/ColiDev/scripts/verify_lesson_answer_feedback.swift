import Foundation

@main
enum LessonAnswerFeedbackVerification {
    static func main() {
        let explanation = "The answer follows from the definition."
        let retryPrompt = "Not quite. Try again."

        let wrongAnswer = LessonAnswerFeedback.presentation(
            isCorrect: false,
            correctFeedback: explanation,
            retryPrompt: retryPrompt
        )
        precondition(
            wrongAnswer.statusMessage == retryPrompt
                && wrongAnswer.explanation == nil,
            "An incorrect answer must offer a retry without revealing the answer explanation immediately. / После ошибки нужно предложить повтор, не раскрывая сразу ответ и разбор."
        )

        let correctAnswer = LessonAnswerFeedback.presentation(
            isCorrect: true,
            correctFeedback: explanation,
            retryPrompt: retryPrompt
        )
        precondition(
            correctAnswer.statusMessage == explanation
                && correctAnswer.explanation == nil,
            "A correct answer must keep its explanation without showing retry guidance. / После правильного ответа нужно показать объяснение без подсказки для повтора."
        )

        let missingExplanation = LessonAnswerFeedback.presentation(
            isCorrect: false,
            correctFeedback: " \n ",
            retryPrompt: retryPrompt
        )
        precondition(
            missingExplanation.statusMessage == retryPrompt
                && missingExplanation.explanation == nil,
            "Whitespace-only content must not create an empty explanation card. / Одни пробелы не должны создавать пустой блок разбора."
        )

        print("Learner-facing lesson feedback checks passed. / Проверки обратной связи для ученика прошли.")
    }
}
