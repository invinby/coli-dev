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
        print("Gene expression model checks passed.")
    }
}
