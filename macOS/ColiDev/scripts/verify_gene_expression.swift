import Foundation

@main
enum GeneExpressionVerification {
    static func main() {
        precondition(GeneExpressionPractice.transcribe(templateDNA: "TAC GGA ACT") == "AUG CCU UGA")
        precondition(GeneExpressionPractice.transcribe(templateDNA: "TACG GAAC") == nil)
        precondition(GeneExpressionPractice.transcribe(templateDNA: "TAC GGA ACN") == nil)
        precondition(GeneExpressionPractice.translate(messengerRNA: "AUG CCU UGA") == ["Met", "Pro", "Stop"])
        precondition(GeneExpressionPractice.translate(messengerRNA: "AUG UGA CCU") == ["Met", "Stop"])
        precondition(GeneExpressionPractice.translate(messengerRNA: "CCU AUG UGA") == nil)
        precondition(GeneExpressionPractice.translate(messengerRNA: "AUG CCU") == nil)
        precondition(GeneExpressionPractice.translate(messengerRNA: "AUG XXX UGA") == nil)

        let active = GeneExpressionPractice.snapshot(promoterIsActive: true)
        precondition(active.messengerRNA == "AUG CCU UGA")
        precondition(active.peptide == ["Met", "Pro", "Stop"])
        let inactive = GeneExpressionPractice.snapshot(promoterIsActive: false)
        precondition(inactive.messengerRNA == nil && inactive.peptide == nil)

        var retriedPrediction = GeneExpressionPractice.makeStopCodonAttempt()
        precondition(retriedPrediction.currentAnswerEventEvidence() == nil)
        let wrongDisplayIndex = retriedPrediction.choiceOrder.displayedOriginalIndices.firstIndex(of: 0)!
        retriedPrediction.select(displayedIndex: wrongDisplayIndex)
        let wrongEvidence = retriedPrediction.currentAnswerEventEvidence()
        precondition(wrongEvidence?.taskType == "interactive_prediction")
        precondition(wrongEvidence?.attempts == 1)
        precondition(wrongEvidence?.firstTryCorrect == false)
        precondition(retriedPrediction.canRetry)

        retriedPrediction.retry()
        let correctDisplayIndex = retriedPrediction.choiceOrder.displayedOriginalIndices.firstIndex(of: 1)!
        retriedPrediction.select(displayedIndex: correctDisplayIndex)
        let recoveredEvidence = retriedPrediction.currentAnswerEventEvidence()
        precondition(recoveredEvidence?.attempts == 2)
        precondition(recoveredEvidence?.firstTryCorrect == false)
        precondition(!retriedPrediction.canRetry)

        var firstTryPrediction = GeneExpressionPractice.makeStopCodonAttempt()
        let firstTryCorrectDisplayIndex = firstTryPrediction.choiceOrder.displayedOriginalIndices.firstIndex(of: 1)!
        firstTryPrediction.select(displayedIndex: firstTryCorrectDisplayIndex)
        precondition(firstTryPrediction.currentAnswerEventEvidence()?.attempts == 1)
        precondition(firstTryPrediction.currentAnswerEventEvidence()?.firstTryCorrect == true)

        print("Gene expression model checks passed.")
    }
}
