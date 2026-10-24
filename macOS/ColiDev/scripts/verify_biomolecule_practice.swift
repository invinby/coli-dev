import Foundation

@main
enum BiomoleculePracticeVerification {
    static func main() {
        precondition(BiomoleculeExample.allCases.count == 4)
        precondition(BiomoleculeExample.enzyme.correctGroup == .protein)
        precondition(BiomoleculeExample.starch.correctGroup == .carbohydrate)
        precondition(BiomoleculeExample.dna.correctGroup == .nucleicAcid)
        precondition(BiomoleculeExample.triglyceride.correctGroup == .lipid)
        precondition(BiomoleculeExample.enzyme.isPolymer)
        precondition(BiomoleculeExample.starch.isPolymer)
        precondition(BiomoleculeExample.dna.isPolymer)
        precondition(!BiomoleculeExample.triglyceride.isPolymer)

        let itemID = "biology.biomolecules_and_building_blocks.classify_enzyme"
        var tracker = BiomoleculeAssessmentTracker()
        let first = tracker.recordSubmission(group: .carbohydrate, for: .enzyme)
        precondition(first?.taskType == "interactive_practice")
        precondition(first?.itemID == itemID)
        precondition(first?.attempts == 1)
        precondition(first?.firstTryCorrect == false)
        precondition(tracker.recordSubmission(group: .carbohydrate, for: .enzyme) == nil)

        let retry = tracker.recordSubmission(group: .protein, for: .enzyme)
        precondition(retry?.itemID == itemID)
        precondition(retry?.attempts == 2)
        precondition(retry?.firstTryCorrect == false)

        let triglyceride = tracker.recordSubmission(group: .lipid, for: .triglyceride)
        precondition(triglyceride?.itemID == "biology.biomolecules_and_building_blocks.classify_triglyceride")
        precondition(triglyceride?.attempts == 1)
        precondition(triglyceride?.firstTryCorrect == true)

        print("Biomolecule practice checks passed.")
    }
}
