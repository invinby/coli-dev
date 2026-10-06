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

        let nodeIDs = Set(PondFoodWebModel.nodes.map(\.id))
        precondition(nodeIDs.count == PondFoodWebModel.nodes.count, "food-web node IDs should be unique")
        let linkIDs = Set(PondFoodWebModel.links.map(\.id))
        precondition(linkIDs.count == PondFoodWebModel.links.count, "food-web links should be unique")
        precondition(
            PondFoodWebModel.nodes.allSatisfy({ (0...1).contains($0.x) && (0...1).contains($0.y) }),
            "food-web node positions should remain inside the diagram bounds"
        )
        precondition(
            PondFoodWebModel.links.allSatisfy({ nodeIDs.contains($0.from) && nodeIDs.contains($0.to) }),
            "every food-web link should point to existing nodes"
        )
        precondition(
            PondFoodWebModel.links.contains(where: { $0.from == "algae" && $0.to == "zooplankton" && $0.kind == .feeding }),
            "feeding links should point from food to consumer"
        )
        precondition(
            PondFoodWebModel.links.contains(where: { $0.from == "decomposers" && $0.to == "nutrients" && $0.kind == .matterCycle })
                && PondFoodWebModel.links.contains(where: { $0.from == "nutrients" && $0.to == "algae" && $0.kind == .matterCycle }),
            "the matter-cycle path should return from decomposers through nutrients to producers"
        )
        precondition(
            PondFoodWebModel.directConsumers(of: "snails") == ["smallFish"],
            "snails should have the fish as their only depicted direct consumer"
        )
        let withoutSnails = PondFoodWebModel.visibleLinks(excluding: "snails")
        precondition(!withoutSnails.contains(where: { $0.from == "snails" || $0.to == "snails" }), "removing snails should hide their direct links")
        precondition(
            PondFoodWebModel.incomingLinks(to: "smallFish", excluding: "snails").map(\.from) == ["zooplankton"],
            "the remaining fish food source should still be available after removing snails"
        )
        precondition(PondFoodWebModel.visibleLinks(excluding: "none") == PondFoodWebModel.links, "the default scenario should show every link")

        print("Biology experiment and food-web model checks passed.")
    }
}
