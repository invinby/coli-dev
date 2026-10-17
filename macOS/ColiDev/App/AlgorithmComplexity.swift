import Foundation

enum AlgorithmComplexityPractice {
    static let sampleSizes = [16, 64, 256, 1024]

    static func linearSearchWorstCaseComparisons(for itemCount: Int) -> Int {
        max(0, itemCount)
    }

    static func binarySearchWorstCaseComparisons(for itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }
        return Int(ceil(log2(Double(itemCount) + 1)))
    }

    static func binarySearchApplies(isSorted: Bool) -> Bool {
        isSorted
    }
}

struct DataStructureChoiceScenario: Equatable, Identifiable {
    let id: String
    let promptKey: String
    let optionKeys: [String]
    let correctOptionIndex: Int
    let explanationKey: String
}

enum DataStructureChoicePractice {
    static let scenarios = [
        DataStructureChoiceScenario(
            id: "programming.data_structures.keep_order_and_duplicates",
            promptKey: "lab.dataStructures.order.prompt",
            optionKeys: ["lab.dataStructures.choice.list", "lab.dataStructures.choice.set", "lab.dataStructures.choice.dict"],
            correctOptionIndex: 0,
            explanationKey: "lab.dataStructures.order.explanation"
        ),
        DataStructureChoiceScenario(
            id: "programming.data_structures.unique_membership",
            promptKey: "lab.dataStructures.membership.prompt",
            optionKeys: ["lab.dataStructures.choice.list", "lab.dataStructures.choice.set", "lab.dataStructures.choice.dict"],
            correctOptionIndex: 1,
            explanationKey: "lab.dataStructures.membership.explanation"
        ),
        DataStructureChoiceScenario(
            id: "programming.data_structures.lookup_by_key",
            promptKey: "lab.dataStructures.mapping.prompt",
            optionKeys: ["lab.dataStructures.choice.list", "lab.dataStructures.choice.set", "lab.dataStructures.choice.dict"],
            correctOptionIndex: 2,
            explanationKey: "lab.dataStructures.mapping.explanation"
        )
    ]

    static func isCorrect(_ option: Int, for scenarioID: String) -> Bool {
        guard let scenario = scenarios.first(where: { $0.id == scenarioID }),
              scenario.optionKeys.indices.contains(option) else { return false }
        return option == scenario.correctOptionIndex
    }
}
