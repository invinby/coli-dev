import Foundation

struct AlgorithmicThinkingSeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

@main
enum AlgorithmicThinkingVerification {
    static func main() {
        let questions = AlgorithmicThinkingPractice.questions
        let expectedIDs = [
            "programming.computational_thinking.step.input",
            "programming.computational_thinking.step.compare",
            "programming.computational_thinking.step.otherwise",
            "programming.computational_thinking.step.display",
            "programming.computational_thinking.maximum_list.check_nonempty",
            "programming.computational_thinking.maximum_list.initialize_current_maximum",
            "programming.computational_thinking.maximum_list.inspect_remaining_values",
            "programming.computational_thinking.maximum_list.update_if_greater",
            "programming.computational_thinking.maximum_list.return_maximum",
            "programming.computational_thinking.tests.maximum_list.typical_maximum_at_end",
            "programming.computational_thinking.tests.maximum_list.single_value",
            "programming.computational_thinking.tests.maximum_list.all_negative",
            "programming.computational_thinking.tests.maximum_list.repeated_maximum",
            "programming.computational_thinking.tests.maximum_list.empty_list",
            "programming.computational_thinking.debugging.find_counterexample",
            "programming.computational_thinking.debugging.repair_initialization",
            "programming.computational_thinking.average.check_nonempty",
            "programming.computational_thinking.average.initialize_total",
            "programming.computational_thinking.average.accumulate_values",
            "programming.computational_thinking.average.divide_by_count",
            "programming.computational_thinking.average.return_average",
            "programming.computational_thinking.tests.average.typical",
            "programming.computational_thinking.tests.average.single_value",
            "programming.computational_thinking.tests.average.empty_list",
            "programming.computational_thinking.tests.average.negative_cancellation",
            "programming.computational_thinking.decompose.hot_days.initialize",
            "programming.computational_thinking.decompose.hot_days.scan",
            "programming.computational_thinking.decompose.hot_days.threshold",
            "programming.computational_thinking.decompose.hot_days.return",
            "programming.computational_thinking.decompose.recipe.validate_servings",
            "programming.computational_thinking.decompose.recipe.compute_factor",
            "programming.computational_thinking.decompose.recipe.scale_ingredients",
            "programming.computational_thinking.decompose.recipe.present_result",
            "programming.computational_thinking.tests.senior_discount.typical_below",
            "programming.computational_thinking.tests.senior_discount.below_threshold",
            "programming.computational_thinking.tests.senior_discount.at_threshold",
            "programming.computational_thinking.tests.senior_discount.typical_above",
            "programming.computational_thinking.tests.senior_discount.invalid_below_domain",
            "programming.computational_thinking.tests.senior_discount.invalid_above_domain"
        ]
        precondition(questions.map(\.id) == expectedIDs, "EN: Practice must cover list-max debugging with stable question identities. / RU: Тренажёр должен включать отладку максимума списка и вопросы с постоянными идентификаторами.")
        precondition(Set(questions.map(\.id)).count == questions.count, "Every pseudocode step needs a unique ID.")
        precondition(questions.map { $0.choiceKeys[$0.correctOptionIndex] } == [
            "input", "compare", "otherwise", "display",
            "checkNonemptyList", "initializeCurrentMaximum", "inspectRemainingValues", "updateIfGreater", "returnMaximum",
            "lab.algorithmMaximumResult9", "lab.algorithmMaximumResult7", "lab.algorithmMaximumResultMinus2",
            "lab.algorithmMaximumResult9", "lab.algorithmEmptyError",
            "lab.algorithmDebugInputNegativeSingleton", "initializeCurrentMaximum",
            "checkNonempty", "initializeTotal", "accumulateValues", "divideByCount", "returnAverage",
            "typical", "boundary", "invalid", "typical",
            "initializeHotDayCount", "scanEveryReading", "countAtOrAboveThreshold", "returnHotDayCount",
            "validateServings", "computeServingFactor", "scaleEachIngredient", "presentAdjustedRecipe",
            "typical", "boundary", "boundary", "typical", "invalid", "invalid"
        ])
        precondition(
            AlgorithmicThinkingPractice.maximumAlgorithmQuestionCount == 9
                && AlgorithmicThinkingPractice.maximumSectionQuestionCount == 14
                && questions.count == 39
                && !AlgorithmicThinkingPractice.showsMaximumExperiment(completedQuestionCount: 8)
                && AlgorithmicThinkingPractice.showsMaximumExperiment(completedQuestionCount: 9)
                && !AlgorithmicThinkingPractice.showsMaximumTestResults(completedQuestionCount: 13)
                && AlgorithmicThinkingPractice.showsMaximumTestResults(completedQuestionCount: 14),
            "EN: Interactive maximum controls must appear after the list-maximum algorithm and its five test questions, without delaying them until the mean section is complete. / RU: Интерактив для максимума должен появляться после алгоритма списка и пяти проверочных вопросов, не дожидаясь завершения раздела о среднем."
        )
        precondition(questions.allSatisfy { $0.choiceKeys.count == 3 && $0.choiceKeys.indices.contains($0.correctOptionIndex) })
        let debuggingQuestions = questions.filter { $0.maximumDebuggingStage != nil }
        precondition(
            debuggingQuestions.compactMap(\.maximumDebuggingStage) == [.findCounterexample, .repairInitialization]
                && AlgorithmicThinkingPractice.maximumDebuggingCounterexampleValues == [-1]
                && AlgorithmicThinkingPractice.maximum(of: AlgorithmicThinkingPractice.maximumDebuggingCounterexampleValues) == -1
                && AlgorithmicThinkingPractice.faultyMaximumInitializedAtZero(
                    of: AlgorithmicThinkingPractice.maximumDebuggingCounterexampleValues
                ) == 0,
            "EN: The debugging task must expose a valid input where zero initialization violates the maximum contract. / RU: Задание по отладке должно показывать допустимый ввод, на котором инициализация нулём нарушает контракт максимума."
        )
        precondition(
            debuggingQuestions.map(\.contextKey) == [
                "lab.algorithm.context.maximumDebuggingFindCounterexample",
                "lab.algorithm.context.maximumDebuggingRepairInitialization"
            ],
            "EN: Counterexample discovery must come before the repair prompt. / RU: Сначала ученик должен найти контрпример, а затем перейти к исправлению."
        )
        precondition(
            AlgorithmicThinkingPractice.maximumTestCases.map(\.id) == [
                "typical_maximum_at_end", "single_value", "all_negative", "repeated_maximum", "empty_list"
            ]
                && AlgorithmicThinkingPractice.maximumTestCases.map(\.expectedMaximum) == [9, 7, -2, 9, nil]
                && AlgorithmicThinkingPractice.maximumTestCases.allSatisfy({
                    AlgorithmicThinkingPractice.maximum(of: $0.values) == $0.expectedMaximum
                }),
            "EN: List-maximum tests must cover typical, boundary, negative, repeated, and invalid inputs with explicit outcomes. / RU: Тесты максимума списка должны охватывать обычный и граничный случаи, отрицательные и повторяющиеся значения, а также недопустимый ввод с явными результатами."
        )
        precondition(
            AlgorithmicThinkingPractice.maximumTestCases.allSatisfy { testCase in
                guard let question = questions.first(where: { $0.maximumTestCaseID == testCase.id }) else { return false }
                return AlgorithmicThinkingPractice.maximumTestCase(forQuestionID: question.id) == testCase
            },
            "EN: Every maximum test question must resolve to its visible input, expected result, and explanation. / RU: Для каждого вопроса о максимуме должны находиться его видимый ввод, ожидаемый результат и объяснение."
        )
        precondition(AlgorithmicThinkingPractice.maximum(of: AlgorithmicThinkingPractice.maximumListValues) == -2)
        precondition(AlgorithmicThinkingPractice.maximum(of: []) == nil, "EN: An empty maximum-list input must not produce a value. / RU: Для пустого списка алгоритм максимума не должен возвращать значение.")
        precondition(
            AlgorithmicThinkingPractice.averageTestCases.map(\.id) == ["typical", "single_value", "empty_list", "negative_cancellation"]
                && AlgorithmicThinkingPractice.averageTestCases.map(\.correctCategory) == [.typical, .boundary, .invalid, .typical]
                && AlgorithmicThinkingPractice.averageTestCases.last?.values == [-2, 2],
            "EN: Mean exercises must include typical, boundary, invalid, and negative-cancellation test cases. / RU: Упражнения на среднее должны включать обычный и граничный случаи, недопустимый ввод и взаимное сокращение отрицательных и положительных значений."
        )
        precondition(AlgorithmicThinkingPractice.average(of: [2, 4, 6]) == 4)
        precondition(AlgorithmicThinkingPractice.average(of: [7]) == 7)
        precondition(AlgorithmicThinkingPractice.average(of: [-2, 2]) == 0)
        precondition(AlgorithmicThinkingPractice.average(of: []) == nil, "The empty-list contract must be explicit.")

        precondition(
            AlgorithmicThinkingPractice.decompositionScenarios.map(\.id) == ["hot_days", "recipe"]
                && questions.filter { $0.decompositionScenarioID != nil }.count == 8
                && questions.filter { $0.decompositionScenarioID == "hot_days" }.count == 4
                && questions.filter { $0.decompositionScenarioID == "recipe" }.count == 4
                && questions.filter { $0.decompositionScenarioID != nil }.allSatisfy({
                    AlgorithmicThinkingPractice.decompositionScenario(forQuestionID: $0.id) != nil
                }),
            "EN: Two distinct problem types must expose four ordered, resolvable decomposition steps each. / RU: Для двух разных типов задач нужны отдельные последовательности из четырёх доступных шагов."
        )
        precondition(
            AlgorithmicThinkingPractice.eligibilityTestCases.map(\.age) == [40, 64, 65, 66, -1, 121]
                && AlgorithmicThinkingPractice.eligibilityTestCases.map(\.correctCategory) == [
                    .typical, .boundary, .boundary, .typical, .invalid, .invalid
                ]
                && questions.filter { $0.eligibilityTestCaseID != nil }.count == 6
                && questions.filter { $0.eligibilityTestCaseID != nil }.allSatisfy({
                    AlgorithmicThinkingPractice.eligibilityTestCase(forQuestionID: $0.id) != nil
                }),
            "EN: Threshold-neighbor and invalid-domain examples must map to stable, reviewable questions. / RU: Соседние значения порога и недопустимые значения должны соответствовать устойчивым проверяемым вопросам."
        )

        for seed in 0..<256 {
            var generator = AlgorithmicThinkingSeededGenerator(seed: UInt64(seed))
            let orders = AlgorithmicThinkingPractice.answerOrders(using: &generator)
            precondition(orders.count == questions.count, "Each step needs a displayed answer order.")
            let correctSlots = zip(questions, orders).map { pair in pair.1.correctDisplayedIndex }
            precondition(
                zip(correctSlots, correctSlots.dropFirst()).allSatisfy { pair in pair.0 != pair.1 },
                "Correct choices must not occupy the same slot on adjacent steps."
            )
            let counts = (0..<3).map { slot in correctSlots.filter { $0 == slot }.count }
            precondition((counts.max()! - counts.min()!) <= 1, "Correct answer slots must remain balanced across the full sequence.")

            for (question, order) in zip(questions, orders) {
                precondition(order.displayedOriginalIndices.sorted() == Array(question.choiceKeys.indices), "Every choice must appear exactly once.")
                precondition(order.displayedOriginalIndices[order.correctDisplayedIndex] == question.correctOptionIndex, "The displayed correct choice must map to the expected action.")
            }
        }

        var generator = AlgorithmicThinkingSeededGenerator(seed: 42)
        let orders = AlgorithmicThinkingPractice.answerOrders(using: &generator)
        var session = AlgorithmicThinkingPracticeSession(answerOrders: orders)
        let firstQuestion = questions[0]
        let firstOrder = orders[0]
        let wrongDisplayedIndex = firstOrder.displayedOriginalIndices.firstIndex { $0 != firstQuestion.correctOptionIndex }!
        let wrong = session.submit(displayedIndex: wrongDisplayedIndex)
        precondition(
            wrong?.evidence?.itemID == firstQuestion.id
                && wrong?.evidence?.attempts == 1
                && wrong?.evidence?.firstTryCorrect == false
                && wrong?.isCorrect == false,
            "A wrong displayed choice must produce evidence for the matching stable step ID."
        )
        precondition(
            session.submit(displayedIndex: wrongDisplayedIndex)?.evidence == nil,
            "Submitting the same choice again must not inflate saved attempts."
        )
        let correctDisplayedIndex = firstOrder.correctDisplayedIndex
        let retry = session.submit(displayedIndex: correctDisplayedIndex)
        precondition(
            retry?.stepKey == "input"
                && retry?.isCorrect == true
                && retry?.evidence?.itemID == firstQuestion.id
                && retry?.evidence?.attempts == 2
                && retry?.evidence?.firstTryCorrect == false,
            "A correct retry must retain the failed first attempt and complete the expected step."
        )

        for stepIndex in 1..<questions.count {
            let question = questions[stepIndex]
            let order = orders[stepIndex]
            let result = session.submit(displayedIndex: order.correctDisplayedIndex)
            precondition(
                result?.isCorrect == true
                    && result?.stepKey == question.choiceKeys[question.correctOptionIndex]
                    && result?.evidence?.itemID == question.id
                    && result?.evidence?.attempts == 1
                    && result?.evidence?.firstTryCorrect == true,
                "Each completed step must save its own first-try evidence."
            )
        }
        precondition(session.isComplete && session.completedStepKeys == questions.map { $0.choiceKeys[$0.correctOptionIndex] })
        precondition(session.displayedChoiceKeys.isEmpty && session.submit(displayedIndex: 0) == nil)

        let firstMaximumTestIndex = questions.firstIndex { $0.maximumTestCaseID != nil }!
        var maximumTestSession = AlgorithmicThinkingPracticeSession(answerOrders: orders)
        for index in 0..<firstMaximumTestIndex {
            precondition(maximumTestSession.submit(displayedIndex: orders[index].correctDisplayedIndex)?.isCorrect == true)
        }
        let maximumTestQuestion = questions[firstMaximumTestIndex]
        let maximumTestOrder = orders[firstMaximumTestIndex]
        let wrongMaximumChoice = maximumTestOrder.displayedOriginalIndices.firstIndex {
            $0 != maximumTestQuestion.correctOptionIndex
        }!
        let wrongMaximumTest = maximumTestSession.submit(displayedIndex: wrongMaximumChoice)
        precondition(
            wrongMaximumTest?.evidence?.itemID == maximumTestQuestion.id
                && wrongMaximumTest?.evidence?.firstTryCorrect == false
                && wrongMaximumTest?.questionID == maximumTestQuestion.id,
            "EN: A wrong expected maximum must save evidence to that exact test case. / RU: Ошибочный ответ о максимуме должен сохранить учебное свидетельство с ID именно этого тест-кейса."
        )
        let correctMaximumTest = maximumTestSession.submit(displayedIndex: maximumTestOrder.correctDisplayedIndex)
        precondition(
            correctMaximumTest?.isCorrect == true
                && correctMaximumTest?.evidence?.itemID == maximumTestQuestion.id
                && correctMaximumTest?.evidence?.attempts == 2
                && correctMaximumTest?.evidence?.firstTryCorrect == false,
            "EN: A corrected maximum-test answer must preserve the initial failed attempt. / RU: После исправления ответа история должна сохранять первую неудачную попытку."
        )

        let firstDebuggingIndex = questions.firstIndex { $0.maximumDebuggingStage == .findCounterexample }!
        var debuggingSession = AlgorithmicThinkingPracticeSession(answerOrders: orders)
        for index in 0..<firstDebuggingIndex {
            precondition(debuggingSession.submit(displayedIndex: orders[index].correctDisplayedIndex)?.isCorrect == true)
        }
        let counterexampleQuestion = questions[firstDebuggingIndex]
        let counterexampleOrder = orders[firstDebuggingIndex]
        let wrongCounterexampleChoice = counterexampleOrder.displayedOriginalIndices.firstIndex {
            $0 != counterexampleQuestion.correctOptionIndex
        }!
        let wrongCounterexample = debuggingSession.submit(displayedIndex: wrongCounterexampleChoice)
        let correctedCounterexample = debuggingSession.submit(displayedIndex: counterexampleOrder.correctDisplayedIndex)
        precondition(
            wrongCounterexample?.questionID == counterexampleQuestion.id
                && wrongCounterexample?.evidence?.firstTryCorrect == false
                && correctedCounterexample?.isCorrect == true
                && correctedCounterexample?.evidence?.itemID == counterexampleQuestion.id
                && correctedCounterexample?.evidence?.attempts == 2
                && correctedCounterexample?.evidence?.firstTryCorrect == false,
            "EN: Finding a counterexample must retain the learner's wrong first attempt when corrected. / RU: При поиске контрпримера после исправления ответа должна сохраняться первая ошибка ученика."
        )

        let firstAverageTestIndex = questions.firstIndex { $0.averageTestCaseID != nil }!
        var caseSession = AlgorithmicThinkingPracticeSession(answerOrders: orders)
        for index in 0..<firstAverageTestIndex {
            precondition(caseSession.submit(displayedIndex: orders[index].correctDisplayedIndex)?.isCorrect == true)
        }
        let caseQuestion = questions[firstAverageTestIndex]
        let caseOrder = orders[firstAverageTestIndex]
        let wrongCategoryIndex = caseOrder.displayedOriginalIndices.firstIndex { $0 != caseQuestion.correctOptionIndex }!
        let wrongCategory = caseSession.submit(displayedIndex: wrongCategoryIndex)
        precondition(
            wrongCategory?.questionID == caseQuestion.id
                && wrongCategory?.evidence?.itemID == caseQuestion.id
                && wrongCategory?.evidence?.attempts == 1
                && wrongCategory?.evidence?.firstTryCorrect == false,
            "A wrong test-case category must save evidence against that stable case ID."
        )
        let correctCategory = caseSession.submit(displayedIndex: caseOrder.correctDisplayedIndex)
        precondition(
            correctCategory?.stepKey == "typical"
                && correctCategory?.isCorrect == true
                && correctCategory?.evidence?.itemID == caseQuestion.id
                && correctCategory?.evidence?.attempts == 2
                && correctCategory?.evidence?.firstTryCorrect == false,
            "Retrying a test-case classification must preserve the first incorrect attempt."
        )

        let pythonCases = AlgorithmicPythonPractice.testCases
        precondition(
            pythonCases.map(\.id) == ["typical", "single", "negative", "repeated", "empty"]
                && pythonCases.map(\.values) == [[2, 4, 9], [7], [-8, -2, -5], [3, 9, 9], []]
                && pythonCases.map(\.expectedMaximum) == [9, 7, -2, 9, nil]
                && Set(pythonCases.map(\.evidenceID)).count == pythonCases.count,
            "EN: The code runner must keep bilingual max-list cases and stable unique evidence IDs. / RU: В исполнителе кода должны быть тесты максимума списка и стабильные уникальные ID учебных результатов."
        )
        let negativeCase = pythonCases.first { $0.id == "negative" }!
        var pythonEvidence = InteractiveChoiceAssessmentTracker(itemIDs: [negativeCase.evidenceID])
        let wrongPythonRun = pythonEvidence.recordSubmission(
            selectedAnswerIndex: 0,
            correctAnswerIndex: 1,
            optionCount: 2,
            itemID: negativeCase.evidenceID
        )
        let correctedPythonRun = pythonEvidence.recordSubmission(
            selectedAnswerIndex: 1,
            correctAnswerIndex: 1,
            optionCount: 2,
            itemID: negativeCase.evidenceID
        )
        precondition(
            wrongPythonRun?.itemID == negativeCase.evidenceID
                && wrongPythonRun?.firstTryCorrect == false
                && correctedPythonRun?.itemID == negativeCase.evidenceID
                && correctedPythonRun?.attempts == 2
                && correctedPythonRun?.firstTryCorrect == false,
            "EN: The code runner must retain the first failed attempt after a corrected run. / RU: После исправления кода история должна сохранять первую неудачную попытку."
        )
        print("Algorithmic-thinking model checks passed")
    }
}
