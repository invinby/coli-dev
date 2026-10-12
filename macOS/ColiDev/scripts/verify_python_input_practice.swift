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
    }
}
