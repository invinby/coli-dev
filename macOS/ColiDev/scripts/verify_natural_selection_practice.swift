import Foundation

@main
enum NaturalSelectionPracticeVerification {
    static func main() {
        let startingPopulation = NaturalSelectionPopulation(
            traitMean: 35,
            traitSpread: 20,
            generation: 0
        )

        precondition(NaturalSelectionPractice.expectedTrend(
            population: startingPopulation,
            environmentOptimum: 75,
            selectionStrength: 0.45,
            heritability: 0.8
        ) == .increase)

        precondition(NaturalSelectionPractice.expectedTrend(
            population: startingPopulation,
            environmentOptimum: 5,
            selectionStrength: 0.45,
            heritability: 0.8
        ) == .decrease)

        precondition(NaturalSelectionPractice.expectedTrend(
            population: startingPopulation,
            environmentOptimum: 75,
            selectionStrength: 0.45,
            heritability: 0
        ) == .noChange)
        precondition(NaturalSelectionPractice.expectedTrend(
            population: startingPopulation,
            environmentOptimum: 35,
            selectionStrength: 0.45,
            heritability: 0.8
        ) == .noChange)

        let nextGeneration = NaturalSelectionPractice.advanceGeneration(
            from: startingPopulation,
            environmentOptimum: 75,
            selectionStrength: 0.45,
            heritability: 0.8
        )
        precondition(abs(nextGeneration.traitMean - 49.4) < 0.000_001)
        precondition(nextGeneration.generation == 1)
        precondition(nextGeneration.traitSpread < startingPopulation.traitSpread)

        let nonHeritableGeneration = NaturalSelectionPractice.advanceGeneration(
            from: startingPopulation,
            environmentOptimum: 75,
            selectionStrength: 0.45,
            heritability: 0
        )
        precondition(nonHeritableGeneration.traitMean == startingPopulation.traitMean)
        precondition(nonHeritableGeneration.traitSpread == startingPopulation.traitSpread)
        precondition(nonHeritableGeneration.generation == 1)

        let predictionItemID = "biology.zoology.natural_selection.trait_mean_direction"
        for trend in NaturalSelectionTrend.allCases {
            precondition(
                NaturalSelectionPractice.makePredictionAttempt(for: trend).itemID == predictionItemID,
                "The prediction identity must describe the skill, not reveal the answer. / ID должен описывать проверяемый навык, а не выдавать ответ."
            )
        }

        var prediction = NaturalSelectionPractice.makePredictionAttempt(for: .increase)
        precondition(prediction.itemID == predictionItemID)
        precondition(prediction.currentAnswerEventEvidence() == nil)
        let wrongDisplayIndex = prediction.choiceOrder.displayedOriginalIndices.firstIndex(of: NaturalSelectionTrend.decrease.rawValue)!
        prediction.select(displayedIndex: wrongDisplayIndex)
        let failedEvidence = prediction.currentAnswerEventEvidence()
        precondition(failedEvidence?.taskType == "interactive_prediction")
        precondition(failedEvidence?.attempts == 1)
        precondition(failedEvidence?.firstTryCorrect == false)
        precondition(failedEvidence?.itemID == predictionItemID)
        precondition(prediction.canRetry)

        prediction.retry()
        let correctDisplayIndex = prediction.choiceOrder.displayedOriginalIndices.firstIndex(of: NaturalSelectionTrend.increase.rawValue)!
        prediction.select(displayedIndex: correctDisplayIndex)
        let recoveredEvidence = prediction.currentAnswerEventEvidence()
        precondition(recoveredEvidence?.attempts == 2)
        precondition(recoveredEvidence?.firstTryCorrect == false)
        precondition(recoveredEvidence?.itemID == predictionItemID)
        precondition(!prediction.canRetry)

        print("Natural-selection practice checks passed.")
    }
}
