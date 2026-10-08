import Foundation

struct LoopTraceScenario: Equatable, Identifiable {
    let id: String
    let values: [Int]

    var expectedCount: Int {
        values.filter { $0.isMultiple(of: 2) }.count
    }

    var steps: [LoopTraceStep] {
        var count = 0
        return values.enumerated().map { index, value in
            let isEven = value.isMultiple(of: 2)
            if isEven { count += 1 }
            return LoopTraceStep(index: index, value: value, isEven: isEven, countAfter: count)
        }
    }

    var displayedValues: String {
        "[" + values.map(String.init).joined(separator: ", ") + "]"
    }
}

struct LoopTraceQuestion: Equatable {
    let options: [Int]
    let correctOptionIndex: Int

    init(scenario: LoopTraceScenario) {
        let options = Array(0...scenario.values.count)
        guard let correctOptionIndex = options.firstIndex(of: scenario.expectedCount) else {
            preconditionFailure("A loop-trace result must be one of the possible counts.")
        }
        self.options = options
        self.correctOptionIndex = correctOptionIndex
    }
}

struct LoopTraceStep: Equatable, Identifiable {
    let index: Int
    let value: Int
    let isEven: Bool
    let countAfter: Int

    var id: Int { index }
}

enum LoopTracePractice {
    static let scenarios = [
        LoopTraceScenario(id: "mixed", values: [2, 5, 8]),
        LoopTraceScenario(id: "zero-negative", values: [0, -2, 3]),
        LoopTraceScenario(id: "empty", values: []),
        LoopTraceScenario(id: "larger-values", values: [11, 12, 15, 20])
    ]

    static func scenario(id: String) -> LoopTraceScenario? {
        scenarios.first { $0.id == id }
    }

    static func isCorrect(prediction: Int, for scenarioID: String) -> Bool {
        guard let scenario = scenario(id: scenarioID) else { return false }
        return prediction == scenario.expectedCount
    }
}
