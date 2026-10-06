import Foundation

enum CellCycleStage: String, CaseIterable, Identifiable {
    case g1
    case s
    case g2
    case prophase
    case prometaphase
    case metaphase
    case anaphase
    case telophase
    case cytokinesis
    case differentiation

    var id: String { rawValue }

    var localizationKey: String { "lab.cellCycle.stage.\(rawValue)" }
}

enum CellCyclePractice {
    static let sequence = CellCycleStage.allCases

    static func next(after stage: CellCycleStage) -> CellCycleStage? {
        guard let index = sequence.firstIndex(of: stage), sequence.indices.contains(index + 1) else {
            return nil
        }
        return sequence[index + 1]
    }

    static func isDNAReplicationStage(_ stage: CellCycleStage) -> Bool {
        stage == .s
    }

    static func isNuclearDivision(_ stage: CellCycleStage) -> Bool {
        switch stage {
        case .prophase, .prometaphase, .metaphase, .anaphase, .telophase:
            return true
        default:
            return false
        }
    }

    static func isCytoplasmDivision(_ stage: CellCycleStage) -> Bool {
        stage == .cytokinesis
    }
}
