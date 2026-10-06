import Foundation

@main
enum BiologyInvestigationVerification {
    static func main() {
        let correct = BiologyExperimentDesign()
        precondition(correct.isReadyToCollectData, "the complete reference design should pass")

        var design = correct
        design.factorToChange = .waterAmount
        precondition(design.issues.contains(.changeFactor), "changing a different factor should be reported")

        design = correct
        design.outcomeToMeasure = .leafCount
        precondition(design.issues.contains(.measuredOutcome), "measuring a different outcome should be reported")

        for control in BiologyStudyControl.allCases {
            design = correct
            design.controls.remove(control)
            precondition(!design.isReadyToCollectData, "omitting a required control should prevent a ready design")
        }

        design = correct
        design.plantsPerGroup = 2
        precondition(design.issues.contains(.replication), "fewer than three independent plants should be flagged")

        design = correct
        design.plantsPerGroup = 12
        precondition(design.isReadyToCollectData, "twelve plants per group should pass the replication threshold")

        print("Biology experiment design checks passed.")
    }
}
