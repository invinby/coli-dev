import Foundation

enum AppLanguage {
    case ru
    case en
}

@main
enum GeneRegulationFeedbackVerification {
    static func main() {
        let states: [(variant: Int, signalPresent: Bool, expectedProduct: Bool)] = [
            (0, true, true),
            (0, false, false),
            (1, true, false),
            (1, false, false)
        ]

        for state in states {
            precondition(
                GeneRegulationPractice.isProductMade(variant: state.variant, signalPresent: state.signalPresent)
                    == state.expectedProduct,
                "Product state must follow the selected variant and signal. / Состояние продукта должно зависеть от выбранного варианта и сигнала."
            )
        }

        let answerCases: [(variant: Int, signalPresent: Bool, expectedAnswer: Int)] = [
            (0, true, 0),
            (0, false, 1),
            (1, true, 1),
            (1, false, 1)
        ]
        for answerCase in answerCases {
            precondition(
                GeneRegulationPractice.correctPredictionAnswerOriginalIndex(
                    variant: answerCase.variant,
                    signalPresent: answerCase.signalPresent
                ) == answerCase.expectedAnswer,
                "The prediction answer must match the selected variant and signal. / Ответ должен соответствовать выбранному варианту и сигналу."
            )
        }

        for productMade in [false, true] {
            precondition(
                GeneRegulationPractice.geneActivityKey(
                    productMade: productMade,
                    outcomeRevealed: false
                ) == "lab.dnaOutcomeHidden"
                    && GeneRegulationPractice.productKey(
                        productMade: productMade,
                        outcomeRevealed: false
                    ) == "lab.dnaOutcomeHidden",
                "The model outcome must stay hidden until the learner predicts correctly. / Результат модели должен оставаться скрытым до правильного прогноза ученика."
            )
            precondition(
                GeneRegulationPractice.geneActivityKey(
                    productMade: productMade,
                    outcomeRevealed: true
                ) == (productMade ? "lab.dnaGeneOn" : "lab.dnaGeneOff")
                    && GeneRegulationPractice.productKey(
                        productMade: productMade,
                        outcomeRevealed: true
                    ) == (productMade ? "lab.dnaProductMade" : "lab.dnaProductAbsent"),
                "A correct prediction must reveal the matching model outcome. / После правильного прогноза нужно показать соответствующее состояние модели."
            )
        }

        let hiddenOutcomeRU = L10n.text("lab.dnaOutcomeHidden", .ru)
        let hiddenOutcomeEN = L10n.text("lab.dnaOutcomeHidden", .en)
        precondition(
            hiddenOutcomeRU != "lab.dnaOutcomeHidden"
                && hiddenOutcomeEN != "lab.dnaOutcomeHidden"
                && hiddenOutcomeRU != hiddenOutcomeEN,
            "The hidden outcome needs distinct Russian and English labels. / Скрытый результат должен иметь отдельные подписи на русском и английском."
        )

        for key in [
            "lab.dnaPredict",
            "lab.dnaPredictOption0",
            "lab.dnaPredictOption1",
            "lab.dnaRetry"
        ] {
            let russian = L10n.text(key, .ru)
            let english = L10n.text(key, .en)
            precondition(
                russian != key && english != key && russian != english,
                "Each prediction and retry action needs Russian and English copy. / Вопрос и действие повтора должны быть переведены на русский и английский."
            )
        }

        let cases: [(isCorrect: Bool, expectedKey: String)] = [
            (true, "lab.dnaPredictExplanation.correct"),
            (false, "lab.dnaPredictExplanation.incorrect")
        ]
        for testCase in cases {
            let key = GeneRegulationPractice.explanationKey(isCorrect: testCase.isCorrect)
            precondition(
                key == testCase.expectedKey,
                "Gene-regulation feedback must match the result. / Разбор регуляции гена должен соответствовать результату ответа."
            )
            let russian = L10n.text(key, .ru)
            let english = L10n.text(key, .en)
            precondition(
                russian != key && english != key && russian != english,
                "Each feedback state needs distinct Russian and English copy. / Для каждого результата нужен отдельный русский и английский текст."
            )
        }

        guard var prediction = InteractivePredictionAttempt(
            optionCount: 2,
            answerOriginalIndex: GeneRegulationPractice.correctPredictionAnswerOriginalIndex(
                variant: 0,
                signalPresent: false
            )
        ) else {
            preconditionFailure("A valid gene-regulation scenario must start a prediction. / Для корректного сценария регуляции гена должен создаваться прогноз.")
        }
        let firstOrder = prediction.choiceOrder.displayedOriginalIndices
        let wrongDisplayedIndex = firstOrder.firstIndex(where: { $0 != prediction.answerOriginalIndex })!
        prediction.select(displayedIndex: wrongDisplayedIndex)
        precondition(
            prediction.currentAnswerEventEvidence()?.taskType == "interactive_prediction"
                && prediction.currentAnswerEventEvidence()?.attempts == 1
                && prediction.currentAnswerEventEvidence()?.firstTryCorrect == false,
            "A wrong gene-regulation prediction must be saved as learning evidence. / Неверный прогноз по регуляции гена должен сохраняться как учебный результат."
        )
        prediction.retry()
        let retryIndex = prediction.choiceOrder.displayedOriginalIndices.firstIndex(of: prediction.answerOriginalIndex)!
        prediction.select(displayedIndex: retryIndex)
        precondition(
            prediction.isCorrect
                && prediction.currentAnswerEventEvidence()?.attempts == 2
                && prediction.currentAnswerEventEvidence()?.firstTryCorrect == false,
            "A correct retry must preserve the first-attempt result and cumulative count. / Правильный повтор должен сохранять результат первой попытки и общее число попыток."
        )
    }
}
