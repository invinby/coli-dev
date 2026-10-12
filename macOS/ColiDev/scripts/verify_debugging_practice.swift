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

        precondition(GitWorkflowPractice.steps.count == 6)
        precondition(Set(GitWorkflowPractice.steps.map(\.id)).count == GitWorkflowPractice.steps.count)
        for step in GitWorkflowPractice.steps {
            precondition(step.commandKeys.count == 3)
            precondition(step.commandKeys.indices.contains(step.correctCommandIndex))
            precondition(GitWorkflowPractice.isCorrect(step.correctCommandIndex, for: step.id))
            for choice in step.commandKeys.indices where choice != step.correctCommandIndex {
                precondition(!GitWorkflowPractice.isCorrect(choice, for: step.id))
            }
        }
        precondition(GitWorkflowPractice.step(id: "unknown") == nil)
        precondition(!GitWorkflowPractice.isCorrect(0, for: "unknown"))
        precondition(!GitWorkflowPractice.isCorrect(-1, for: GitWorkflowPractice.steps[0].id))
        precondition(!GitWorkflowPractice.isCorrect(3, for: GitWorkflowPractice.steps[0].id))
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: -1) == .unstaged)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 2) == .unstaged)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 3) == .staged)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 4) == .staged)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 5) == .committedWithUntrackedFile)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 100) == .committedWithUntrackedFile)
        print("Debugging practice model checks passed")
    }
}
