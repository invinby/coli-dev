import Foundation

@main
enum AnimalFunctionPracticeVerification {
    static func main() {
        precondition(AnimalFunction.allCases.count == 4)
        precondition(Set(AnimalFunction.allCases.map(\.rawValue)).count == 4)
        for function in AnimalFunction.allCases {
            precondition(!function.titleKey.isEmpty)
            precondition(!function.exampleKey.isEmpty)
            precondition(!function.mechanismKey.isEmpty)
            precondition(!function.limitationKey.isEmpty)
        }
        precondition(!AnimalFunctionPractice.isCorrectComparisonAnswer(-1))
        precondition(!AnimalFunctionPractice.isCorrectComparisonAnswer(0))
        precondition(AnimalFunctionPractice.isCorrectComparisonAnswer(1))
        precondition(!AnimalFunctionPractice.isCorrectComparisonAnswer(2))

        var prediction = AnimalFunctionPractice.makeComparisonAttempt()
        precondition(prediction.currentAnswerEventEvidence() == nil)
        let wrongDisplayIndex = prediction.choiceOrder.displayedOriginalIndices.firstIndex(of: 0)!
        prediction.select(displayedIndex: wrongDisplayIndex)
        let failedEvidence = prediction.currentAnswerEventEvidence()
        precondition(failedEvidence?.taskType == "interactive_prediction")
        precondition(failedEvidence?.attempts == 1)
        precondition(failedEvidence?.firstTryCorrect == false)
        precondition(prediction.canRetry)

        prediction.retry()
        let correctDisplayIndex = prediction.choiceOrder.displayedOriginalIndices.firstIndex(of: 1)!
        prediction.select(displayedIndex: correctDisplayIndex)
        let recoveredEvidence = prediction.currentAnswerEventEvidence()
        precondition(recoveredEvidence?.attempts == 2)
        precondition(recoveredEvidence?.firstTryCorrect == false)
        precondition(!prediction.canRetry)

        print("Animal function practice checks passed.")
    }
}
