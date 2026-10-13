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

        precondition(GitWorkflowPractice.steps.count == 12)
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
        let createBranchID = "programming.git_workflow.create_feature_branch"
        let createBranch = GitWorkflowPractice.step(id: createBranchID)
        precondition(createBranch?.commandKeys[createBranch?.correctCommandIndex ?? -1] == "lab.git.command.switchCreate")
        let publishBranchID = "programming.git_workflow.publish_feature_branch"
        let publishBranch = GitWorkflowPractice.step(id: publishBranchID)
        precondition(publishBranch?.commandKeys[publishBranch?.correctCommandIndex ?? -1] == "lab.git.command.pushUpstream")
        let openPullRequestID = "programming.git_workflow.open_pull_request"
        let openPullRequest = GitWorkflowPractice.step(id: openPullRequestID)
        precondition(openPullRequest?.commandKeys[openPullRequest?.correctCommandIndex ?? -1] == "lab.git.action.openPullRequest")
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: -1) == .unstaged)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 2) == .unstaged)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 3) == .staged)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 4) == .staged)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 5) == .committedWithUntrackedFile)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 6) == .committedWithUntrackedFile)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 7) == .featureBranchWithChanges)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 8) == .featureBranchStaged)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 9) == .featureBranchStaged)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 10) == .featureBranchCommitted)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 11) == .featureBranchPublished)
        precondition(GitWorkflowPractice.snapshotState(afterCompletedSteps: 100) == .pullRequestOpen)
        print("Debugging practice model checks passed")
    }
}
