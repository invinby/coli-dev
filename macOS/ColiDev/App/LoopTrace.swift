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
    let itemID: String
    let options: [Int]
    let correctOptionIndex: Int

    init(scenario: LoopTraceScenario) {
        let options = Array(0...scenario.values.count)
        guard let correctOptionIndex = options.firstIndex(of: scenario.expectedCount) else {
            preconditionFailure("A loop-trace result must be one of the possible counts.")
        }
        self.itemID = "programming.loop_trace.\(scenario.id).final_count"
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

struct WhileLoopTraceStep: Equatable, Identifiable {
    let checkNumber: Int
    let valueBeforeCheck: Int
    let conditionTrue: Bool
    let valueAfterBody: Int?

    var id: Int { checkNumber }
}

struct WhileLoopTrace {
    static let initialValueRange = 0...9
    static let decrementRange = 1...3

    let initialValue: Int
    let decrement: Int
    private(set) var currentValue: Int
    private(set) var steps: [WhileLoopTraceStep] = []
    private(set) var isComplete = false

    var printedValues: [Int] {
        steps.compactMap { $0.conditionTrue ? $0.valueBeforeCheck : nil }
    }

    init(initialValue: Int, decrement: Int) {
        let boundedInitialValue = min(max(initialValue, Self.initialValueRange.lowerBound), Self.initialValueRange.upperBound)
        let boundedDecrement = min(max(decrement, Self.decrementRange.lowerBound), Self.decrementRange.upperBound)
        self.initialValue = boundedInitialValue
        self.decrement = boundedDecrement
        currentValue = boundedInitialValue
    }

    @discardableResult
    mutating func checkNextStep() -> WhileLoopTraceStep? {
        guard !isComplete else { return nil }

        let valueBeforeCheck = currentValue
        let conditionTrue = valueBeforeCheck > 0
        let valueAfterBody: Int?
        if conditionTrue {
            currentValue -= decrement
            valueAfterBody = currentValue
        } else {
            valueAfterBody = nil
            isComplete = true
        }

        let step = WhileLoopTraceStep(
            checkNumber: steps.count + 1,
            valueBeforeCheck: valueBeforeCheck,
            conditionTrue: conditionTrue,
            valueAfterBody: valueAfterBody
        )
        steps.append(step)
        return step
    }
}
