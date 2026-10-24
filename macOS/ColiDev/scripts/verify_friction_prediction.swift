import Foundation

@main
enum FrictionPredictionVerification {
    static func main() {
        var practice = FrictionPredictionPracticeSession()
        let restingQuestion = practice.currentQuestion!
        precondition(restingQuestion.id == "friction.at-15n")
        precondition(restingQuestion.appliedForce == 15 && !restingQuestion.expectedSliding)
        precondition(practice.currentOptionOriginalIndices.sorted() == [0, 1])

        let restingMotion = FrictionMotion(
            mass: 5,
            appliedForce: restingQuestion.appliedForce,
            staticCoefficient: 0.4,
            kineticCoefficient: 0.3,
            time: 2
        )
        precondition(restingMotion.isSliding == restingQuestion.expectedSliding)

        let firstCorrectDisplayedIndex = practice.currentOptionOriginalIndices.firstIndex(of: 0)!
        let firstWrongDisplayedIndex = practice.currentOptionOriginalIndices.firstIndex(of: 1)!
        practice.selectOption(at: firstWrongDisplayedIndex)
        let wrongFirstTry = practice.checkAnswer()
        precondition(practice.feedback == .review)
        precondition(wrongFirstTry == StudyAssessmentEvidence(
            taskType: "interactive_practice",
            attempts: 1,
            firstTryCorrect: false,
            hintsUsed: 0,
            itemID: "friction.at-15n"
        ))
        precondition(practice.checkAnswer() == nil, "Submitting the same wrong choice must not inflate attempts.")
        practice.selectOption(at: firstCorrectDisplayedIndex)
        let correctedFirstScenario = practice.checkAnswer()
        precondition(practice.feedback == .correct)
        precondition(correctedFirstScenario?.attempts == 2 && correctedFirstScenario?.firstTryCorrect == false)
        practice.advance()

        let slidingQuestion = practice.currentQuestion!
        precondition(slidingQuestion.id == "friction.at-25n")
        precondition(slidingQuestion.appliedForce == 25 && slidingQuestion.expectedSliding)
        let slidingMotion = FrictionMotion(
            mass: 5,
            appliedForce: slidingQuestion.appliedForce,
            staticCoefficient: 0.4,
            kineticCoefficient: 0.3,
            time: 2
        )
        precondition(slidingMotion.isSliding == slidingQuestion.expectedSliding)

        let secondCorrectDisplayedIndex = practice.currentOptionOriginalIndices.firstIndex(of: 1)!
        let secondWrongDisplayedIndex = practice.currentOptionOriginalIndices.firstIndex(of: 0)!
        practice.selectOption(at: secondWrongDisplayedIndex)
        precondition(practice.checkAnswer()?.itemID == "friction.at-25n")
        practice.selectOption(at: secondCorrectDisplayedIndex)
        let correctedSecondScenario = practice.checkAnswer()
        precondition(practice.feedback == .correct)
        precondition(correctedSecondScenario?.attempts == 2 && correctedSecondScenario?.firstTryCorrect == false)
        practice.advance()
        precondition(practice.isComplete && practice.currentQuestion == nil)

        practice.restart()
        precondition(!practice.isComplete && practice.currentQuestion?.id == "friction.at-15n")
        precondition(practice.currentOptionOriginalIndices.sorted() == [0, 1])
        print("Friction prediction practice checks passed.")
    }
}
