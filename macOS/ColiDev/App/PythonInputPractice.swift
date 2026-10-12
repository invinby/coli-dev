import Foundation

enum PythonInputPracticeResult: Equatable {
    case integer(Int)
    case valueError
    case outsideSimulatorRange
}

enum PythonInputPractice {
    static let inputReturnType = "str"

    /// Simulates `int(input_text)` for simple ASCII whole-number examples.
    /// Python integers can exceed Swift's machine-sized `Int`; that case is
    /// reported as a simulator limit rather than as Python's `ValueError`.
    static func convert(_ text: String) -> PythonInputPracticeResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .valueError }

        let digits = trimmed.first == "+" || trimmed.first == "-"
            ? String(trimmed.dropFirst())
            : trimmed
        guard !digits.isEmpty, digits.unicodeScalars.allSatisfy({ (48...57).contains($0.value) }) else {
            return .valueError
        }

        guard let value = Int(trimmed) else { return .outsideSimulatorRange }
        return .integer(value)
    }
}
