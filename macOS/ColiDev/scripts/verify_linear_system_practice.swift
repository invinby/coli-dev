import Foundation

@main
enum LinearSystemPracticeVerification {
    static func main() {
        let unique = LinearSystemPractice.scenario(id: "unique")
        precondition(LinearSystemPractice.classify(unique) == .oneSolution(x: 4, y: 3))
        precondition(LinearSystemPractice.classify(unique) == unique.outcome)
        precondition(LinearSystemPractice.correctPredictionIndex(for: unique) == 0)
        precondition(LinearSystemPractice.isCorrectPrediction(0, for: unique))
        precondition(!LinearSystemPractice.isCorrectPrediction(1, for: unique))
        precondition(!LinearSystemPractice.isCorrectPrediction(2, for: unique))
        verifyPredictionEvidence(for: unique)

        let parallel = LinearSystemPractice.scenario(id: "parallel")
        precondition(LinearSystemPractice.classify(parallel) == .noSolution)
        precondition(LinearSystemPractice.classify(parallel) == parallel.outcome)
        precondition(LinearSystemPractice.correctPredictionIndex(for: parallel) == 1)
        precondition(!LinearSystemPractice.isCorrectPrediction(0, for: parallel))
        precondition(LinearSystemPractice.isCorrectPrediction(1, for: parallel))
        precondition(!LinearSystemPractice.isCorrectPrediction(2, for: parallel))
        verifyPredictionEvidence(for: parallel)

        let sameLine = LinearSystemPractice.scenario(id: "same-line")
        precondition(LinearSystemPractice.classify(sameLine) == .infinitelyManySolutions)
        precondition(LinearSystemPractice.classify(sameLine) == sameLine.outcome)
        precondition(LinearSystemPractice.correctPredictionIndex(for: sameLine) == 2)
        precondition(!LinearSystemPractice.isCorrectPrediction(0, for: sameLine))
        precondition(!LinearSystemPractice.isCorrectPrediction(1, for: sameLine))
        precondition(LinearSystemPractice.isCorrectPrediction(2, for: sameLine))
        verifyPredictionEvidence(for: sameLine)

        precondition(LinearSystemPractice.scenario(id: "unknown").id == "unique")
        print("Linear system practice checks passed.")
    }

    private static func verifyPredictionEvidence(for scenario: LinearSystemScenario) {
        let expectedItemID = "mathematics.systems_of_linear_equations.\(scenario.id).solution_classification"
        let reflectedItemID = Mirror(reflecting: scenario).children
            .first { $0.label == "itemID" }?.value as? String
        precondition(reflectedItemID == expectedItemID, "prediction identity must stay tied to scenario \(scenario.id)")
        guard var attempt = InteractivePredictionAttempt(
            optionCount: 3,
            answerOriginalIndex: LinearSystemPractice.correctPredictionIndex(for: scenario),
            itemID: reflectedItemID
        ) else {
            preconditionFailure("prediction attempt must have a valid answer for \(scenario.id)")
        }
        let correctOptionIndex = LinearSystemPractice.correctPredictionIndex(for: scenario)
        let wrongDisplayedIndex = attempt.choiceOrder.displayedOriginalIndices
            .firstIndex { $0 != correctOptionIndex }!
        attempt.select(displayedIndex: wrongDisplayedIndex)
        precondition(
            attempt.currentAnswerEventEvidence()?.itemID == expectedItemID
                && attempt.currentAnswerEventEvidence()?.firstTryCorrect == false,
            "incorrect answer evidence must retain the scenario identity for \(scenario.id)"
        )
        attempt.retry()
        let correctDisplayedIndex = attempt.choiceOrder.displayedOriginalIndices
            .firstIndex(of: correctOptionIndex)!
        attempt.select(displayedIndex: correctDisplayedIndex)
        precondition(
            attempt.currentAnswerEventEvidence()?.itemID == expectedItemID
                && attempt.currentAnswerEventEvidence()?.attempts == 2,
            "retry evidence must retain the scenario identity for \(scenario.id)"
        )
    }
}
