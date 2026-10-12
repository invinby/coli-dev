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

        var conditionalAssessment = EnglishConditionalAssessmentTracker()
        let firstConditionalAttempt = conditionalAssessment.recordSubmission(form: .first, for: "general-rule")!
        precondition(
            firstConditionalAttempt.taskType == "interactive_practice"
                && firstConditionalAttempt.attempts == 1
                && !firstConditionalAttempt.firstTryCorrect
                && firstConditionalAttempt.itemID == "general-rule",
            "save an incorrect first conditional-form attempt with its scenario identity"
        )
        precondition(
            conditionalAssessment.recordSubmission(form: .first, for: "general-rule") == nil,
            "do not count a duplicate conditional-form submission"
        )
        let conditionalRetry = conditionalAssessment.recordSubmission(form: .zero, for: "general-rule")!
        precondition(
            conditionalRetry.attempts == 2 && !conditionalRetry.firstTryCorrect,
            "retain the first conditional result after a correct retry"
        )
        let otherScenarioFirstTry = conditionalAssessment.recordSubmission(form: .first, for: "real-future")!
        precondition(
            otherScenarioFirstTry.attempts == 1 && otherScenarioFirstTry.firstTryCorrect,
            "track each conditional scenario independently"
        )
        precondition(
            conditionalAssessment.recordSubmission(form: .zero, for: "missing-scenario") == nil,
            "do not create assessment evidence for an unknown conditional scenario"
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

        var readingAssessment = EnglishReadingAssessmentTracker()
        let firstReadingAttempt = readingAssessment.recordSubmission(option: 0, for: "first-pass-purpose")!
        precondition(firstReadingAttempt.taskType == "interactive_practice", "classify reading-strategy responses as interactive practice")
        precondition(firstReadingAttempt.attempts == 1 && !firstReadingAttempt.firstTryCorrect, "save an incorrect first reading answer")
        precondition(readingAssessment.recordSubmission(option: 0, for: "first-pass-purpose") == nil, "do not count a duplicate answer submission")
        let readingRetry = readingAssessment.recordSubmission(option: 1, for: "first-pass-purpose")!
        precondition(readingRetry.attempts == 2 && !readingRetry.firstTryCorrect, "retain the first result after correcting a reading answer")
        precondition(readingRetry.itemID == "first-pass-purpose", "preserve the question identity with the reading evidence")
        precondition(readingAssessment.recordSubmission(option: 3, for: "first-pass-purpose") == nil, "reject an out-of-range reading option")
        precondition(readingAssessment.recordSubmission(option: 2, for: "missing-question") == nil, "reject an unknown reading question")

        let anotherQuestionFirstTry = readingAssessment.recordSubmission(option: 0, for: "meeting-detail")!
        precondition(anotherQuestionFirstTry.attempts == 1 && anotherQuestionFirstTry.firstTryCorrect, "track first-try evidence independently per question")

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
        let readingPracticeEvent = StudyAssessmentEvent(
            id: "00000000-0000-0000-0000-000000000002",
            lessonID: "english.reading_for_gist_and_detail",
            assessment: readingRetry
        )
        let readingPracticeEventData = try encoder.encode(readingPracticeEvent)
        let readingEventObject = try JSONSerialization.jsonObject(with: readingPracticeEventData) as! [String: Any]
        let readingEventAssessment = readingEventObject["assessment"] as! [String: Any]
        precondition(
            readingEventAssessment["task_type"] as? String == "interactive_practice"
                && readingEventAssessment["item_id"] as? String == "first-pass-purpose"
                && Set(readingEventAssessment.keys) == Set(["task_type", "item_id", "attempts", "first_try_correct", "hints_used"]),
            "reading-practice evidence should serialize in the supported backend format"
        )
        let restoredReadingPracticeEvent = try JSONDecoder().decode(StudyAssessmentEvent.self, from: readingPracticeEventData)
        precondition(
            restoredReadingPracticeEvent.assessment.itemID == "first-pass-purpose",
            "offline reading-practice evidence should preserve its question identity"
        )

        let knowledgeCheckEvent = StudyAssessmentEvent(
            id: "00000000-0000-0000-0000-000000000001",
            lessonID: "english.reported_speech_questions_and_backshift",
            assessment: StudyAssessmentEvidence(
                taskType: "knowledge_check",
                attempts: 2,
                firstTryCorrect: false,
                hintsUsed: 0,
                errorCategories: [.understanding],
                passed: false,
                itemID: "reported-speech.question-1"
            )
        )
        let eventObject = try JSONSerialization.jsonObject(with: encoder.encode(knowledgeCheckEvent)) as! [String: Any]
        let assessment = eventObject["assessment"] as! [String: Any]
        precondition(
            Set(assessment.keys) == Set(["task_type", "passed", "error_categories", "item_id"])
                && assessment["item_id"] as? String == "reported-speech.question-1",
            "knowledge-check events must preserve the individual question ID / события проверки должны сохранять ID отдельного вопроса"
        )
        let restoredEvent = try JSONDecoder().decode(StudyAssessmentEvent.self, from: encoder.encode(knowledgeCheckEvent))
        precondition(restoredEvent.assessment.taskType == "knowledge_check", "offline queued checks should restore after app restart / ожидающая офлайн-запись должна восстановиться после перезапуска")
        precondition(restoredEvent.assessment.passed == false, "restored offline checks should preserve their result / восстановленная запись должна сохранять результат проверки")
        precondition(restoredEvent.assessment.itemID == "reported-speech.question-1", "offline queued checks should preserve the individual question ID / офлайн-событие должно сохранять ID отдельного вопроса")
        let legacyKnowledgeCheck = Data(#"{"event_id":"00000000-0000-0000-0000-000000000002","lesson_id":"english.reported_speech_questions_and_backshift","assessment":{"task_type":"knowledge_check","passed":false}}"#.utf8)
        let restoredLegacyCheck = try JSONDecoder().decode(StudyAssessmentEvent.self, from: legacyKnowledgeCheck)
        precondition(restoredLegacyCheck.assessment.itemID == nil, "older knowledge-check events without an item ID must remain readable / старые события без ID вопроса должны читаться")

        print("English conditionals, reading, reported speech, and assessment event checks passed. / Проверки условных конструкций, чтения, косвенной речи и событий результатов пройдены.")
    }
}
