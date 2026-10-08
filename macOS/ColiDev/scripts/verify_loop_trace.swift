import Foundation

@main
enum LoopTraceVerification {
    static func main() {
        precondition(Set(LoopTracePractice.scenarios.map(\.id)).count == LoopTracePractice.scenarios.count)

        let expected: [(String, [Int], Int)] = [
            ("mixed", [2, 5, 8], 2),
            ("zero-negative", [0, -2, 3], 2),
            ("empty", [], 0),
            ("larger-values", [11, 12, 15, 20], 2)
        ]

        for (id, values, answer) in expected {
            guard let scenario = LoopTracePractice.scenario(id: id) else {
                preconditionFailure("missing scenario \(id)")
            }
            precondition(scenario.values == values, "unexpected values for \(id)")
            precondition(scenario.expectedCount == answer, "incorrect final count for \(id)")
            let question = LoopTraceQuestion(scenario: scenario)
            precondition(question.options == Array(0...values.count), "prediction choices should cover every possible count for \(id)")
            precondition(question.options[question.correctOptionIndex] == answer, "randomized prediction should map to the correct count for \(id)")
            precondition(scenario.steps.count == values.count, "trace length should match input length for \(id)")
            precondition((scenario.steps.last?.countAfter ?? 0) == answer, "trace should end at the returned count for \(id)")
            precondition(LoopTracePractice.isCorrect(prediction: answer, for: id), "expected answer should pass for \(id)")
            precondition(!LoopTracePractice.isCorrect(prediction: answer + 1, for: id), "incorrect answer should fail for \(id)")

            var runningCount = 0
            for (index, step) in scenario.steps.enumerated() {
                precondition(step.index == index, "trace index should be stable for \(id)")
                precondition(step.value == values[index], "trace should preserve input order for \(id)")
                if step.isEven { runningCount += 1 }
                precondition(step.countAfter == runningCount, "count should update only for even values in \(id)")
            }
        }

        precondition(LoopTracePractice.scenario(id: "unknown") == nil, "unknown scenarios should fail closed")
        precondition(!LoopTracePractice.isCorrect(prediction: 0, for: "unknown"), "unknown scenarios should reject answers")
        print("Loop trace model checks passed")
    }
}
