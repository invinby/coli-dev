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
            let expectedItemID = "programming.loop_trace.\(id).final_count"
            let reflectedItemID = Mirror(reflecting: question).children
                .first { $0.label == "itemID" }?.value as? String
            precondition(reflectedItemID == expectedItemID, "question identity must stay tied to scenario \(id)")
            guard var attempt = InteractivePredictionAttempt(
                optionCount: question.options.count,
                answerOriginalIndex: question.correctOptionIndex,
                itemID: reflectedItemID
            ) else {
                preconditionFailure("prediction attempt must have a valid answer for \(id)")
            }
            if question.options.count > 1 {
                let wrongDisplayedIndex = attempt.choiceOrder.displayedOriginalIndices
                    .firstIndex { $0 != question.correctOptionIndex }!
                attempt.select(displayedIndex: wrongDisplayedIndex)
                precondition(
                    attempt.currentAnswerEventEvidence()?.itemID == expectedItemID
                        && attempt.currentAnswerEventEvidence()?.firstTryCorrect == false,
                    "incorrect answer evidence must retain the scenario identity for \(id)"
                )
                attempt.retry()
                let correctDisplayedIndex = attempt.choiceOrder.displayedOriginalIndices
                    .firstIndex(of: question.correctOptionIndex)!
                attempt.select(displayedIndex: correctDisplayedIndex)
                precondition(
                    attempt.currentAnswerEventEvidence()?.itemID == expectedItemID
                        && attempt.currentAnswerEventEvidence()?.attempts == 2,
                    "retry evidence must retain the scenario identity for \(id)"
                )
            } else {
                attempt.select(displayedIndex: 0)
                precondition(
                    attempt.currentAnswerEventEvidence()?.itemID == expectedItemID
                        && attempt.currentAnswerEventEvidence()?.firstTryCorrect == true,
                    "single-option evidence must retain the scenario identity for \(id)"
                )
            }
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

        var whileTrace = WhileLoopTrace(initialValue: 5, decrement: 2)
        let expectedWhileSteps = [
            WhileLoopTraceStep(checkNumber: 1, valueBeforeCheck: 5, conditionTrue: true, valueAfterBody: 3),
            WhileLoopTraceStep(checkNumber: 2, valueBeforeCheck: 3, conditionTrue: true, valueAfterBody: 1),
            WhileLoopTraceStep(checkNumber: 3, valueBeforeCheck: 1, conditionTrue: true, valueAfterBody: -1),
            WhileLoopTraceStep(checkNumber: 4, valueBeforeCheck: -1, conditionTrue: false, valueAfterBody: nil)
        ]
        for expectedStep in expectedWhileSteps {
            precondition(
                whileTrace.checkNextStep() == expectedStep,
                "while must check the condition before each body and stop before executing a false branch"
            )
        }
        precondition(whileTrace.isComplete, "a false condition should finish the bounded while trace")
        precondition(whileTrace.checkNextStep() == nil, "a finished trace must not execute another body")
        precondition(whileTrace.steps == expectedWhileSteps, "a finished trace must retain its exact execution history")
        precondition(whileTrace.printedValues == [5, 3, 1], "only values from executed while bodies should be printed")

        var initiallyFalseTrace = WhileLoopTrace(initialValue: 0, decrement: 3)
        precondition(
            initiallyFalseTrace.checkNextStep() == WhileLoopTraceStep(
                checkNumber: 1,
                valueBeforeCheck: 0,
                conditionTrue: false,
                valueAfterBody: nil
            ),
            "a false condition on the first check must skip the loop body"
        )
        precondition(initiallyFalseTrace.printedValues.isEmpty, "a skipped loop body must produce no printed values")

        var maximumTeachingTrace = WhileLoopTrace(initialValue: 9, decrement: 1)
        while maximumTeachingTrace.checkNextStep() != nil {}
        precondition(maximumTeachingTrace.isComplete && maximumTeachingTrace.steps.count == 10, "fixed positive decrement must bound the longest teaching trace")
        let boundedInputs = WhileLoopTrace(initialValue: 12, decrement: 0)
        precondition(boundedInputs.initialValue == 9 && boundedInputs.decrement == 1, "out-of-range settings must be clamped to the terminating teaching limits")
        print("Loop trace model checks passed")
    }
}
