import Foundation

@main
enum DebuggingPracticeVerification {
    static func main() {
        precondition(DebuggingPractice.scenarios.count == 3)
        precondition(Set(DebuggingPractice.scenarios.map(\.id)).count == DebuggingPractice.scenarios.count)
        for scenario in DebuggingPractice.scenarios {
            precondition(scenario.choiceKeys.count == 3)
            precondition(scenario.choiceKeys.indices.contains(scenario.correctChoice))
            precondition(DebuggingPractice.isCorrect(scenario.correctChoice, for: scenario.id))
            for choice in scenario.choiceKeys.indices where choice != scenario.correctChoice {
                precondition(!DebuggingPractice.isCorrect(choice, for: scenario.id))
            }
        }
        precondition(DebuggingPractice.scenario(id: "unknown") == nil)
        precondition(!DebuggingPractice.isCorrect(0, for: "unknown"))
        precondition(!DebuggingPractice.isCorrect(-1, for: "name-error"))
        precondition(!DebuggingPractice.isCorrect(3, for: "name-error"))
        print("Debugging practice model checks passed")
    }
}
