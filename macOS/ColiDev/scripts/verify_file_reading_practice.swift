import Foundation

@main
enum FileReadingPracticeVerification {
    static func main() {
        precondition(Set(FileReadingPractice.scenarios.map(\.id)).count == FileReadingPractice.scenarios.count)
        precondition(Set(FileReadingPractice.scenarios.map(\.expectedOutcome)) == Set(FileReadingOutcome.allCases))

        for scenario in FileReadingPractice.scenarios {
            precondition(
                FileReadingPractice.isCorrect(scenario.expectedOutcome, for: scenario.id),
                "expected file-reading outcome should pass for \(scenario.id)"
            )
            for other in FileReadingPractice.outcomes where other != scenario.expectedOutcome {
                precondition(
                    !FileReadingPractice.isCorrect(other, for: scenario.id),
                    "unrelated outcomes should fail for \(scenario.id)"
                )
            }
        }

        precondition(FileReadingPractice.scenario(id: "unknown") == nil)
        precondition(!FileReadingPractice.isCorrect(.missingFile, for: "unknown"))
        print("File-reading practice model checks passed")
    }
}
