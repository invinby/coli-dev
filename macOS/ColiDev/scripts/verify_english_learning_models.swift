import Foundation

@main
enum EnglishLearningModelsVerification {
    static func main() throws {
        let scenarios = EnglishConditionalPractice.scenarios
        precondition(scenarios.count == EnglishConditionalForm.allCases.count, "practice must cover every taught conditional form")
        precondition(Set(scenarios.map(\.id)).count == scenarios.count, "conditional scenario IDs should be unique")
        precondition(Set(scenarios.map(\.correctForm)) == Set(EnglishConditionalForm.allCases), "each form should have one reference scenario")

        for scenario in scenarios {
            precondition(
                EnglishConditionalPractice.isCorrect(scenario.correctForm, for: scenario.id),
                "the expected form should pass for \(scenario.id)"
            )
            for alternative in EnglishConditionalForm.allCases where alternative != scenario.correctForm {
                precondition(
                    !EnglishConditionalPractice.isCorrect(alternative, for: scenario.id),
                    "an alternative form should not pass for \(scenario.id)"
                )
            }
        }

        precondition(
            !EnglishConditionalPractice.isCorrect(.zero, for: "missing-scenario"),
            "unknown scenario IDs should fail closed"
        )

        let readingQuestions = EnglishReadingPractice.questions
        precondition(readingQuestions.count == 3, "reading practice should cover its three reading strategies")
        precondition(Set(readingQuestions.map(\.id)).count == readingQuestions.count, "reading question IDs should be unique")
        for question in readingQuestions {
            precondition(
                EnglishReadingPractice.isCorrect(question.correctOption, for: question.id),
                "the reference option should pass for \(question.id)"
            )
            for alternative in 0..<3 where alternative != question.correctOption {
                precondition(
                    !EnglishReadingPractice.isCorrect(alternative, for: question.id),
                    "an alternative answer should not pass for \(question.id)"
                )
            }
        }
        precondition(!EnglishReadingPractice.isCorrect(0, for: "missing-question"), "unknown question IDs should fail closed")

        let reportedSpeechQuestions = EnglishReportedSpeechPractice.questions
        precondition(reportedSpeechQuestions.count == 4, "reported speech practice should cover four distinct transformations / тренажёр косвенной речи должен охватывать четыре разные конструкции")
        precondition(Set(reportedSpeechQuestions.map(\.id)).count == reportedSpeechQuestions.count, "reported speech question IDs should be unique / ID вопросов косвенной речи не должны повторяться")
        precondition(Set(reportedSpeechQuestions.map(\.correctOption)) == Set([0, 1, 2]), "correct answer positions should vary / позиции правильных ответов должны различаться")
        for question in reportedSpeechQuestions {
            precondition(
                EnglishReportedSpeechPractice.isCorrect(question.correctOption, for: question.id),
                "the reference option should pass for \(question.id) / правильный ответ должен приниматься для \(question.id)"
            )
            for alternative in 0..<3 where alternative != question.correctOption {
                precondition(
                    !EnglishReportedSpeechPractice.isCorrect(alternative, for: question.id),
                    "an alternative answer should not pass for \(question.id) / неверный вариант не должен приниматься для \(question.id)"
                )
            }
        }
        precondition(!EnglishReportedSpeechPractice.isCorrect(0, for: "missing-question"), "unknown reported-speech questions should fail closed / неизвестный вопрос должен отклоняться")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        let knowledgeCheckEvent = StudyAssessmentEvent(
            id: "00000000-0000-0000-0000-000000000001",
            lessonID: "english.reported_speech_questions_and_backshift",
            assessment: StudyAssessmentEvidence(
                taskType: "knowledge_check",
                attempts: 2,
                firstTryCorrect: false,
                hintsUsed: 0,
                errorCategories: [.understanding],
                passed: false
            )
        )
        let eventObject = try JSONSerialization.jsonObject(with: encoder.encode(knowledgeCheckEvent)) as! [String: Any]
        let assessment = eventObject["assessment"] as! [String: Any]
        precondition(Set(assessment.keys) == Set(["task_type", "passed", "error_categories"]), "knowledge-check events must match the backend event schema / событие проверки должно соответствовать схеме backend")
        let restoredEvent = try JSONDecoder().decode(StudyAssessmentEvent.self, from: encoder.encode(knowledgeCheckEvent))
        precondition(restoredEvent.assessment.taskType == "knowledge_check", "offline queued checks should restore after app restart / ожидающая офлайн-запись должна восстановиться после перезапуска")
        precondition(restoredEvent.assessment.passed == false, "restored offline checks should preserve their result / восстановленная запись должна сохранять результат проверки")

        print("English conditionals, reading, reported speech, and assessment event checks passed. / Проверки условных конструкций, чтения, косвенной речи и событий результатов пройдены.")
    }
}
