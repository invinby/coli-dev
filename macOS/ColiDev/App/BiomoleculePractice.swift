import Foundation

enum BiomoleculeGroup: String, CaseIterable, Hashable {
    case carbohydrate
    case lipid
    case protein
    case nucleicAcid = "nucleic_acid"
}

enum BiomoleculeExample: String, CaseIterable, Hashable {
    case enzyme
    case starch
    case dna
    case triglyceride

    var correctGroup: BiomoleculeGroup {
        switch self {
        case .enzyme: .protein
        case .starch: .carbohydrate
        case .dna: .nucleicAcid
        case .triglyceride: .lipid
        }
    }

    var isPolymer: Bool { self != .triglyceride }
}

struct BiomoleculeAssessmentTracker {
    private struct ItemState {
        var attempts = 0
        var firstTryCorrect: Bool?
        var lastSubmittedGroup: BiomoleculeGroup?
    }

    private var states: [BiomoleculeExample: ItemState] = [:]

    init() {}

    mutating func recordSubmission(
        group: BiomoleculeGroup,
        for example: BiomoleculeExample
    ) -> StudyAssessmentEvidence? {
        var state = states[example] ?? ItemState()
        guard state.lastSubmittedGroup != group else { return nil }

        let correct = group == example.correctGroup
        state.attempts += 1
        if state.firstTryCorrect == nil {
            state.firstTryCorrect = correct
        }
        state.lastSubmittedGroup = group
        states[example] = state

        return StudyAssessmentEvidence(
            taskType: "interactive_practice",
            attempts: state.attempts,
            firstTryCorrect: state.firstTryCorrect ?? correct,
            hintsUsed: 0,
            itemID: "biology.biomolecules_and_building_blocks.classify_\(example.rawValue)"
        )
    }
}
