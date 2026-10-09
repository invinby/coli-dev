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

        precondition(
            !GeneRegulationPractice.isProductMade(variant: 0, signalPresent: false)
                && GeneRegulationPractice.correctPredictionAnswerOriginalIndex == 1,
            "The displayed prediction must agree with the no-signal model state. / Прогноз должен совпадать с состоянием модели без сигнала."
        )

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
    }
}
