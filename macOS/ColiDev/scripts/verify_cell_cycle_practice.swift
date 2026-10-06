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
        print("Cell-cycle practice checks passed.")
    }
}
