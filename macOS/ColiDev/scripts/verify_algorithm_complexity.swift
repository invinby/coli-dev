import Foundation

@main
enum AlgorithmComplexityVerification {
    static func main() {
        let expectedBinaryBounds = [5, 7, 9, 11]
        precondition(AlgorithmComplexityPractice.sampleSizes.count == expectedBinaryBounds.count)
        for (index, itemCount) in AlgorithmComplexityPractice.sampleSizes.enumerated() {
            let linear = AlgorithmComplexityPractice.linearSearchWorstCaseComparisons(for: itemCount)
            let binary = AlgorithmComplexityPractice.binarySearchWorstCaseComparisons(for: itemCount)
            precondition(linear == itemCount, "linear search can inspect every item")
            precondition(binary == expectedBinaryBounds[index], "binary upper bound should be ceil(log2(n + 1))")
            precondition(binary < linear, "binary search should use fewer comparisons for the displayed sizes")
        }
        precondition(AlgorithmComplexityPractice.binarySearchWorstCaseComparisons(for: 0) == 0)
        precondition(AlgorithmComplexityPractice.binarySearchApplies(isSorted: true))
        precondition(!AlgorithmComplexityPractice.binarySearchApplies(isSorted: false))

        let scenarios = DataStructureChoicePractice.scenarios
        let expectedScenarioIDs = [
            "programming.data_structures.keep_order_and_duplicates",
            "programming.data_structures.unique_membership",
            "programming.data_structures.lookup_by_key"
        ]
        precondition(scenarios.map(\.id) == expectedScenarioIDs)
        precondition(Set(scenarios.map(\.id)).count == scenarios.count)
        for scenario in scenarios {
            precondition(scenario.optionKeys.count == 3)
            precondition(scenario.optionKeys.indices.contains(scenario.correctOptionIndex))
            precondition(DataStructureChoicePractice.isCorrect(scenario.correctOptionIndex, for: scenario.id))
            for option in scenario.optionKeys.indices where option != scenario.correctOptionIndex {
                precondition(!DataStructureChoicePractice.isCorrect(option, for: scenario.id))
            }
        }
        precondition(!DataStructureChoicePractice.isCorrect(-1, for: expectedScenarioIDs[0]))
        precondition(!DataStructureChoicePractice.isCorrect(0, for: "programming.data_structures.unknown"))
        print("Algorithm complexity and data structure choice checks passed.")
    }
}
