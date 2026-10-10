import Foundation

@main
enum CellCyclePracticeVerification {
    static func main() {
        precondition(CellCyclePractice.sequence.first == .g1)
        precondition(CellCyclePractice.sequence.last == .differentiation)
        precondition(CellCyclePractice.sequence.count == 10)
        precondition(CellCyclePractice.next(after: .g1) == .s)
        precondition(CellCyclePractice.next(after: .s) == .g2)
        precondition(CellCyclePractice.next(after: .anaphase) == .telophase)
        precondition(CellCyclePractice.next(after: .differentiation) == nil)
        precondition(CellCyclePractice.isDNAReplicationStage(.s))
        precondition(!CellCyclePractice.isDNAReplicationStage(.anaphase))
        precondition(CellCyclePractice.isNuclearDivision(.metaphase))
        precondition(!CellCyclePractice.isNuclearDivision(.cytokinesis))
        precondition(CellCyclePractice.isCytoplasmDivision(.cytokinesis))
        precondition(!CellCyclePractice.isCytoplasmDivision(.telophase))

        var knowledgeCheck = CellCyclePractice.makeKnowledgeCheckAttempt()
        precondition(knowledgeCheck.answerOriginalIndex == 0)
        precondition(knowledgeCheck.currentAnswerEventEvidence() == nil)
        let wrongDisplayIndex = knowledgeCheck.choiceOrder.displayedOriginalIndices.firstIndex(of: 1)!
        knowledgeCheck.select(displayedIndex: wrongDisplayIndex)
        let failedAttempt = knowledgeCheck.currentAnswerEventEvidence()
        precondition(failedAttempt?.taskType == "interactive_prediction")
        precondition(failedAttempt?.attempts == 1)
        precondition(failedAttempt?.firstTryCorrect == false)
        precondition(failedAttempt?.hintsUsed == 1)
        precondition(knowledgeCheck.canRetry)

        knowledgeCheck.retry()
        precondition(!knowledgeCheck.hasAnswered)
        precondition(knowledgeCheck.currentAnswerEventEvidence() == nil)
        let correctDisplayIndex = knowledgeCheck.choiceOrder.displayedOriginalIndices.firstIndex(of: 0)!
        knowledgeCheck.select(displayedIndex: correctDisplayIndex)
        let recoveredAttempt = knowledgeCheck.currentAnswerEventEvidence()
        precondition(recoveredAttempt?.attempts == 2)
        precondition(recoveredAttempt?.firstTryCorrect == false)
        precondition(recoveredAttempt?.hintsUsed == 1)
        precondition(!knowledgeCheck.canRetry)

        var firstTrySuccess = CellCyclePractice.makeKnowledgeCheckAttempt()
        let initialCorrectIndex = firstTrySuccess.choiceOrder.displayedOriginalIndices.firstIndex(of: 0)!
        firstTrySuccess.select(displayedIndex: initialCorrectIndex)
        let successfulAttempt = firstTrySuccess.currentAnswerEventEvidence()
        precondition(successfulAttempt?.attempts == 1)
        precondition(successfulAttempt?.firstTryCorrect == true)
        precondition(successfulAttempt?.hintsUsed == 0)
        precondition(!firstTrySuccess.canRetry)

        print("Cell-cycle practice checks passed. / Проверки тренажёра клеточного цикла прошли.")
    }
}
