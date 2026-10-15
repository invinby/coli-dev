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

        let wordStressQuestions = EnglishWordStressPractice.questions
        precondition(wordStressQuestions.count == 4, "word-stress practice should cover two noun/verb pairs / тренажёр ударения должен покрывать две пары существительное/глагол")
        precondition(Set(wordStressQuestions.map(\.id)).count == wordStressQuestions.count, "word-stress question IDs should be unique / ID заданий ударения должны быть уникальными")
        precondition(
            wordStressQuestions.map { "\($0.id):\($0.word)" }
                == ["present-as-gift:present", "present-the-results:present", "record-as-a-file:record", "record-the-audio:record"],
            "word-stress examples should match the sentence and localization keys / примеры должны совпадать с контекстом и ключами локализации"
        )
        precondition(
            wordStressQuestions.map(\.spokenSentence)
                == [
                    "I received a present from the school.",
                    "She will present the results tomorrow.",
                    "The record is stored locally.",
                    "Please record the result."
                ],
            "audio must speak the exact English context for each noun and verb form / озвучка должна произносить точное английское предложение для каждой формы"
        )
        precondition(
            EnglishSpeechAccent.available(in: ["en-US", "fr-FR", "en-GB"]).map(\.rawValue) == ["en-GB", "en-US"]
                && EnglishSpeechAccent.available(in: ["en-AU"]).isEmpty,
            "only installed UK and US English voices should be offered / предлагать только установленные голоса UK и US"
        )
        precondition(wordStressQuestions.map(\.correctOption) == [0, 1, 0, 1], "word-stress examples should not always place the answer in one position / правильный вариант не должен всегда стоять на одной позиции")
        for question in wordStressQuestions {
            precondition(
                EnglishWordStressPractice.isCorrect(question.correctOption, for: question.id),
                "the reference stress pattern should pass for \(question.id) / эталонный рисунок ударения должен приниматься для \(question.id)"
            )
            for alternative in 0..<2 where alternative != question.correctOption {
                precondition(
                    !EnglishWordStressPractice.isCorrect(alternative, for: question.id),
                    "an alternative stress pattern should not pass for \(question.id) / неверный рисунок ударения не должен приниматься для \(question.id)"
                )
            }
        }
        precondition(!EnglishWordStressPractice.isCorrect(2, for: "present-as-gift"), "out-of-range stress choices must fail closed / выходящий за диапазон ответ должен отклоняться")
        precondition(!EnglishWordStressPractice.isCorrect(0, for: "missing-stress-question"), "unknown stress questions must fail closed / неизвестный вопрос об ударении должен отклоняться")

        var wordStressTracker = EnglishWordStressAssessmentTracker()
        let firstStressAttempt = wordStressTracker.recordSubmission(option: 1, for: "present-as-gift")!
        precondition(
            firstStressAttempt.taskType == "interactive_practice"
                && firstStressAttempt.attempts == 1
                && !firstStressAttempt.firstTryCorrect
                && firstStressAttempt.itemID == "present-as-gift",
            "save a first word-stress attempt with its stable question ID / сохранять первую попытку с постоянным ID вопроса"
        )
        precondition(
            wordStressTracker.recordSubmission(option: 1, for: "present-as-gift") == nil,
            "do not count a duplicate word-stress choice / не считать повтор той же попытки"
        )
        let stressRetry = wordStressTracker.recordSubmission(option: 0, for: "present-as-gift")!
        precondition(
            stressRetry.attempts == 2 && !stressRetry.firstTryCorrect && stressRetry.itemID == "present-as-gift",
            "retain first-try evidence after the learner corrects the stress pattern / сохранять результат первой попытки после исправления"
        )
        let anotherStressQuestion = wordStressTracker.recordSubmission(option: 1, for: "present-the-results")!
        precondition(
            anotherStressQuestion.attempts == 1 && anotherStressQuestion.firstTryCorrect,
            "track the verb example independently / вести отдельную историю для второго примера"
        )
        precondition(wordStressTracker.recordSubmission(option: 2, for: "present-as-gift") == nil, "reject an invalid stress choice / отклонять несуществующий вариант")
        precondition(wordStressTracker.recordSubmission(option: 0, for: "missing-stress-question") == nil, "reject an unknown stress question / отклонять неизвестный вопрос")

        let stressEvent = StudyAssessmentEvent(
            id: "00000000-0000-0000-0000-000000000003",
            lessonID: "english.sounds_stress_rhythm",
            assessment: stressRetry
        )
        let stressEventObject = try JSONSerialization.jsonObject(with: encoder.encode(stressEvent)) as! [String: Any]
        let stressEventAssessment = stressEventObject["assessment"] as! [String: Any]
        precondition(
            stressEventObject["lesson_id"] as? String == "english.sounds_stress_rhythm"
                && stressEventAssessment["task_type"] as? String == "interactive_practice"
                && stressEventAssessment["item_id"] as? String == "present-as-gift",
            "word-stress attempts should serialize using the supported bilingual course evidence contract / попытки должны передаваться в существующем контракте учебных свидетельств"
        )
        let restoredStressEvent = try JSONDecoder().decode(StudyAssessmentEvent.self, from: encoder.encode(stressEvent))
        precondition(
            restoredStressEvent.assessment.itemID == "present-as-gift"
                && restoredStressEvent.assessment.firstTryCorrect == false,
            "offline word-stress evidence should preserve its item identity and first result / офлайн-результат должен сохранять ID задания и первую оценку"
        )

        let beQuestions = EnglishBePractice.questions
        precondition(beQuestions.count == 7, "beginner be practice should cover statements, negatives, questions, and short answers / базовый тренажёр be должен охватывать утверждения, отрицания, вопросы и краткие ответы")
        precondition(Set(beQuestions.map(\.id)).count == beQuestions.count, "be-practice IDs should be unique / ID заданий be должны быть уникальными")
        let expectedAnswers = [
            "i-am": "am",
            "she-is": "is",
            "you-are": "are",
            "we-are": "are",
            "plural-negative": "are",
            "inverted-question": "Are",
            "short-answer": "are"
        ]
        precondition(Set(expectedAnswers.keys) == Set(beQuestions.map(\.id)), "the beginner be practice should cover the independently specified learner contexts / тренажёр должен покрывать все заданные контексты")
        precondition(Set(beQuestions.map(\.correctOption)) == Set([0, 1, 2]), "correct answer positions should vary / позиции правильных ответов должны различаться")
        for question in beQuestions {
            precondition(question.options.count == 3, "each be question should offer three choices / в каждом задании be должны быть три варианта")
            precondition(!question.prompt.isEmpty && !question.translation.isEmpty, "each prompt should have English and Russian learner text / каждое задание должно иметь английский и русский текст")
            precondition(!question.explanationRussian.isEmpty && !question.explanationEnglish.isEmpty, "feedback should be bilingual / обратная связь должна быть двуязычной")
            precondition((0..<question.options.count).contains(question.correctOption), "the correct answer index must be inside the options / индекс правильного ответа должен входить в список вариантов")
            precondition(question.options[question.correctOption] == expectedAnswers[question.id], "the answer key must match the grammar in each context / ключ должен соответствовать грамматике контекста")
            precondition(EnglishBePractice.isCorrect(question.correctOption, for: question.id), "the reference answer should pass for \(question.id) / правильный ответ должен приниматься для \(question.id)")
            for alternative in question.options.indices where alternative != question.correctOption {
                precondition(!EnglishBePractice.isCorrect(alternative, for: question.id), "a distractor should fail for \(question.id) / отвлекающий вариант должен отклоняться для \(question.id)")
            }
        }
        precondition(!EnglishBePractice.isCorrect(3, for: "i-am"), "out-of-range answers should fail closed / выходящие за список ответы должны отклоняться")
        precondition(!EnglishBePractice.isCorrect(0, for: "missing-be-question"), "unknown be questions should fail closed / неизвестный вопрос be должен отклоняться")

        var beAssessment = EnglishBeAssessmentTracker()
        let firstBeAttempt = beAssessment.recordSubmission(option: 1, for: "i-am")!
        precondition(firstBeAttempt.taskType == "interactive_practice" && firstBeAttempt.attempts == 1 && !firstBeAttempt.firstTryCorrect && firstBeAttempt.itemID == "i-am", "save the incorrect first be response with its stable question ID / сохранять первую ошибку с постоянным ID вопроса")
        precondition(beAssessment.recordSubmission(option: 1, for: "i-am") == nil, "do not count submitting the same be answer twice / повтор одинакового ответа не должен увеличивать попытки")
        let beRetry = beAssessment.recordSubmission(option: 0, for: "i-am")!
        precondition(beRetry.attempts == 2 && !beRetry.firstTryCorrect && beRetry.itemID == "i-am", "keep the first error after a correct retry / сохранять первую ошибку после исправления")
        precondition(beAssessment.recordSubmission(option: 2, for: "you-are")?.firstTryCorrect == true, "track a separate correct be response / отдельно записывать правильный ответ")
        precondition(beAssessment.recordSubmission(option: 3, for: "i-am") == nil && beAssessment.recordSubmission(option: 0, for: "missing-be-question") == nil, "reject invalid answers and unknown be questions / отклонять неверные индексы и неизвестные вопросы")

        let beEvent = StudyAssessmentEvent(
            id: "00000000-0000-0000-0000-000000000004",
            lessonID: "english.subject_pronouns_and_be",
            assessment: beRetry
        )
        let beEventObject = try JSONSerialization.jsonObject(with: encoder.encode(beEvent)) as! [String: Any]
        let beEventAssessment = beEventObject["assessment"] as! [String: Any]
        precondition(beEventObject["lesson_id"] as? String == "english.subject_pronouns_and_be" && beEventAssessment["item_id"] as? String == "i-am", "offline be evidence should use the lesson and item IDs consumed by progress and review / офлайн-свидетельства должны использовать ID урока и вопроса системы прогресса")

        print("English conditionals, reading, reported speech, word stress, be practice, and assessment event checks passed. / Проверки условных конструкций, чтения, косвенной речи, ударения, тренажёра be и событий результатов пройдены.")
    }
}
