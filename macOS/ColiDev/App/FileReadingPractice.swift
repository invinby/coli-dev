import Foundation

enum FileReadingOutcome: Int, CaseIterable, Hashable {
    case missingFile
    case invalidNumber
    case successfulSum

    var localizationKey: String {
        switch self {
        case .missingFile: "lab.fileTrace.outcome.missing"
        case .invalidNumber: "lab.fileTrace.outcome.invalid"
        case .successfulSum: "lab.fileTrace.outcome.success"
        }
    }
}

struct FileReadingScenario: Equatable, Identifiable {
    let id: String
    let expectedOutcome: FileReadingOutcome
    let explanationKey: String
}

enum FileReadingPractice {
    static let outcomes = FileReadingOutcome.allCases

    static let scenarios = [
        FileReadingScenario(
            id: "missing",
            expectedOutcome: .missingFile,
            explanationKey: "lab.fileTrace.explanation.missing"
        ),
        FileReadingScenario(
            id: "invalid-number",
            expectedOutcome: .invalidNumber,
            explanationKey: "lab.fileTrace.explanation.invalid"
        ),
        FileReadingScenario(
            id: "valid-numbers",
            expectedOutcome: .successfulSum,
            explanationKey: "lab.fileTrace.explanation.success"
        )
    ]

    static func scenario(id: String) -> FileReadingScenario? {
        scenarios.first { $0.id == id }
    }

    static func isCorrect(_ choice: FileReadingOutcome, for scenarioID: String) -> Bool {
        guard let scenario = scenario(id: scenarioID) else { return false }
        return choice == scenario.expectedOutcome
    }
}
