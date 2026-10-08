import Foundation

@main
enum LessonAnswerFeedbackVerification {
    static func main() {
        let explanation = "The answer follows from the definition."
        let correctPrompt = "Correct."
        let retryPrompt = "Not quite. Try again."

        let wrongAnswer = LessonAnswerFeedback.presentation(
            isCorrect: false,
            explanation: explanation,
            correctPrompt: correctPrompt,
            retryPrompt: retryPrompt
        )
        precondition(
            wrongAnswer.statusMessage == retryPrompt
                && wrongAnswer.explanation == nil
                && wrongAnswer.canRevealExplanation,
            "An incorrect answer must offer a retry without revealing the explanation, but allow the learner to request it. / После ошибки нужно предложить повтор, не раскрывая разбор, но дать возможность открыть его."
        )

        let requestedExplanation = LessonAnswerFeedback.presentation(
            isCorrect: false,
            explanationRevealed: true,
            explanation: explanation,
            correctPrompt: correctPrompt,
            retryPrompt: retryPrompt
        )
        precondition(
            requestedExplanation.statusMessage == retryPrompt
                && requestedExplanation.explanation == explanation
                && !requestedExplanation.canRevealExplanation,
            "A learner-requested reveal must show the available explanation once. / По запросу ученика нужно показать разбор и убрать повторную кнопку раскрытия."
        )

        let correctAnswer = LessonAnswerFeedback.presentation(
            isCorrect: true,
            explanation: explanation,
            correctPrompt: correctPrompt,
            retryPrompt: retryPrompt
        )
        precondition(
            correctAnswer.statusMessage == correctPrompt
                && correctAnswer.explanation == explanation
                && !correctAnswer.canRevealExplanation,
            "A correct answer must show its explanation automatically without retry guidance. / После правильного ответа разбор показывается автоматически, без подсказки для повтора."
        )

        let missingExplanation = LessonAnswerFeedback.presentation(
            isCorrect: false,
            explanation: " \n ",
            correctPrompt: correctPrompt,
            retryPrompt: retryPrompt
        )
        precondition(
            missingExplanation.statusMessage == retryPrompt
                && missingExplanation.explanation == nil
                && !missingExplanation.canRevealExplanation,
            "Whitespace-only content must not create an empty explanation or reveal action. / Одни пробелы не должны создавать пустой блок разбора или кнопку раскрытия."
        )

        print("Learner-facing lesson feedback checks passed. / Проверки обратной связи для ученика прошли.")
    }
}
