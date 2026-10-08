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
                && wrongAnswer.explanation == explanation,
            "An incorrect answer must keep the retry prompt and reveal the specific explanation. / После ошибочного ответа нужно показать подсказку для повтора и конкретное объяснение."
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

        print("Learner-facing lesson feedback checks passed. / Проверки обратной связи для ученика прошли.")
    }
}
