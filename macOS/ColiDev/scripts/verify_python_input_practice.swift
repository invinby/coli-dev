import Foundation

@main
struct VerifyPythonInputPractice {
    static func main() {
        precondition(PythonInputPractice.inputReturnType == "str", "input() should return text before conversion")
        precondition(PythonInputPractice.convert("12") == .integer(12), "a small whole-number string should convert")
        precondition(PythonInputPractice.convert("  -12  ") == .integer(-12), "surrounding whitespace and a minus sign should be handled")
        precondition(PythonInputPractice.convert("+12") == .integer(12), "a leading plus sign should be handled")
        precondition(PythonInputPractice.convert(" \t12\n") == .integer(12), "surrounding whitespace should be trimmed")
        precondition(PythonInputPractice.convert("+") == .valueError, "a sign without digits should be invalid")
        precondition(PythonInputPractice.convert("1 2") == .valueError, "embedded whitespace should be invalid")
        precondition(PythonInputPractice.convert("twelve") == .valueError, "non-numeric text should show the ValueError case")
        precondition(PythonInputPractice.convert("3.5") == .valueError, "decimal text should not convert with int()")
        precondition(PythonInputPractice.convert("") == .valueError, "empty text should show the ValueError case")
        precondition(
            PythonInputPractice.convert("999999999999999999999999999999") == .outsideSimulatorRange,
            "machine-integer overflow must be scoped as a simulator limit, not a Python ValueError"
        )

        var validFirstPractice = PythonInputPracticeTracker()
        let firstValidAttempt = validFirstPractice.recordSubmission(text: "12")
        precondition(firstValidAttempt == StudyAssessmentEvidence(
            taskType: "interactive_practice",
            attempts: 1,
            firstTryCorrect: true,
            hintsUsed: 0,
            itemID: "programming.variables_and_types.integer_conversion"
        ), "a valid whole-number conversion should create addressable practice evidence")
        precondition(
            validFirstPractice.recordSubmission(text: "12") == nil,
            "resubmitting unchanged text should not create another attempt"
        )

        let invalidAfterSuccess = validFirstPractice.recordSubmission(text: "twelve")
        precondition(
            invalidAfterSuccess?.attempts == 2 && invalidAfterSuccess?.firstTryCorrect == true,
            "a later exploratory invalid value should preserve the valid first-try result"
        )
        precondition(
            invalidAfterSuccess?.itemID == "programming.variables_and_types.integer_conversion",
            "later attempts must keep the same lesson skill identity"
        )
        if let evidence = invalidAfterSuccess,
           let payload = try? JSONEncoder().encode(evidence),
           let json = try? JSONSerialization.jsonObject(with: payload) as? [String: Any] {
            precondition(
                Set(json.keys) == Set(["task_type", "item_id", "attempts", "first_try_correct", "hints_used"]),
                "synced practice evidence must match the backend's supported payload"
            )
            precondition(json["item_id"] as? String == "programming.variables_and_types.integer_conversion")
            precondition(json["attempts"] as? Int == 2)
            precondition(json["input"] == nil, "learner-entered text must not be included in synced evidence")
        } else {
            preconditionFailure("practice evidence should encode into the existing sync payload")
        }

        var correctedPractice = PythonInputPracticeTracker()
        let firstInvalidAttempt = correctedPractice.recordSubmission(text: "3.5")
        precondition(firstInvalidAttempt?.firstTryCorrect == false, "a ValueError on the first task attempt should remain visible")
        let correctedAttempt = correctedPractice.recordSubmission(text: "-12")
        precondition(
            correctedAttempt?.attempts == 2 && correctedAttempt?.firstTryCorrect == false,
            "correcting the input should preserve the initial outcome and count the retry"
        )
        print("Python input practice checks passed.")
    }
}
