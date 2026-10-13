import Foundation

struct DebuggingScenario: Equatable, Identifiable {
    let id: String
    let code: String
    let traceback: String
    let choiceKeys: [String]
    let correctChoice: Int
    let explanationKey: String

    var promptKey: String { "lab.debugging.scenario.\(id)" }
}

enum DebuggingPractice {
    static let scenarios = [
        DebuggingScenario(id: "name-error", code: "total = 12\nprint(totel)", traceback: "NameError: name 'totel' is not defined", choiceKeys: ["lab.debugging.choice.name", "lab.debugging.choice.expected", "lab.debugging.choice.indentation"], correctChoice: 0, explanationKey: "lab.debugging.explanation.name"),
        DebuggingScenario(id: "index-error", code: "items = [\"a\", \"b\", \"c\"]\nfor i in range(len(items) + 1):\n    print(items[i])", traceback: "IndexError: list index out of range", choiceKeys: ["lab.debugging.choice.rename", "lab.debugging.choice.boundary", "lab.debugging.choice.catch"], correctChoice: 1, explanationKey: "lab.debugging.explanation.index"),
        DebuggingScenario(id: "assertion-error", code: "def double(n):\n    return n * 2\nassert double(3) == 5", traceback: "AssertionError", choiceKeys: ["lab.debugging.choice.requirement", "lab.debugging.choice.delete", "lab.debugging.choice.random"], correctChoice: 0, explanationKey: "lab.debugging.explanation.assertion")
    ]

    static func scenario(id: String) -> DebuggingScenario? { scenarios.first { $0.id == id } }

    static func isCorrect(_ choice: Int, for scenarioID: String) -> Bool {
        guard let scenario = scenario(id: scenarioID), scenario.choiceKeys.indices.contains(choice) else { return false }
        return choice == scenario.correctChoice
    }
}

struct GitWorkflowStep: Equatable, Identifiable {
    let id: String
    let promptKey: String
    let commandKeys: [String]
    let correctCommandIndex: Int
    let explanationKey: String
}

enum GitWorkflowSnapshotState: Equatable {
    case unstaged
    case staged
    case committedWithUntrackedFile
    case featureBranchWithChanges
    case featureBranchStaged
    case featureBranchCommitted
    case featureBranchPublished
    case pullRequestOpen
}

enum GitWorkflowPractice {
    static let steps = [
        GitWorkflowStep(
            id: "programming.git_workflow.inspect_status",
            promptKey: "lab.git.prompt.status",
            commandKeys: ["lab.git.command.status", "lab.git.command.addAll", "lab.git.command.push"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.status"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.review_changes",
            promptKey: "lab.git.prompt.diff",
            commandKeys: ["lab.git.command.diff", "lab.git.command.diffCached", "lab.git.command.push"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.diff"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.stage_named_files",
            promptKey: "lab.git.prompt.add",
            commandKeys: ["lab.git.command.addNamed", "lab.git.command.addAll", "lab.git.command.commit"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.add"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.review_staged_changes",
            promptKey: "lab.git.prompt.diffCached",
            commandKeys: ["lab.git.command.diffCached", "lab.git.command.diff", "lab.git.command.status"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.diffCached"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.create_commit",
            promptKey: "lab.git.prompt.commit",
            commandKeys: ["lab.git.command.commit", "lab.git.command.push", "lab.git.command.addAll"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.commit"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.verify_status",
            promptKey: "lab.git.prompt.verify",
            commandKeys: ["lab.git.command.status", "lab.git.command.diffCached", "lab.git.command.push"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.verify"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.create_feature_branch",
            promptKey: "lab.git.prompt.createBranch",
            commandKeys: ["lab.git.command.switchCreate", "lab.git.command.switchMain", "lab.git.command.switchForceCreate"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.createBranch"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.stage_feature_files",
            promptKey: "lab.git.prompt.stageBranchFiles",
            commandKeys: ["lab.git.command.addNamed", "lab.git.command.addAll", "lab.git.command.addLog"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.stageBranchFiles"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.review_feature_snapshot",
            promptKey: "lab.git.prompt.reviewBranchSnapshot",
            commandKeys: ["lab.git.command.diffCached", "lab.git.command.diff", "lab.git.command.status"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.reviewBranchSnapshot"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.commit_feature",
            promptKey: "lab.git.prompt.commitBranch",
            commandKeys: ["lab.git.command.commitFeature", "lab.git.command.pushUpstream", "lab.git.command.addAll"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.commitBranch"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.publish_feature_branch",
            promptKey: "lab.git.prompt.publishBranch",
            commandKeys: ["lab.git.command.pushUpstream", "lab.git.command.pushMain", "lab.git.command.forcePush"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.publishBranch"
        ),
        GitWorkflowStep(
            id: "programming.git_workflow.open_pull_request",
            promptKey: "lab.git.prompt.openPullRequest",
            commandKeys: ["lab.git.action.openPullRequest", "lab.git.command.mergeMain", "lab.git.command.forcePush"],
            correctCommandIndex: 0,
            explanationKey: "lab.git.explanation.openPullRequest"
        )
    ]

    static func step(id: String) -> GitWorkflowStep? {
        steps.first { $0.id == id }
    }

    static func isCorrect(_ commandIndex: Int, for stepID: String) -> Bool {
        guard let step = step(id: stepID), step.commandKeys.indices.contains(commandIndex) else { return false }
        return commandIndex == step.correctCommandIndex
    }

    static func snapshotState(afterCompletedSteps completedSteps: Int) -> GitWorkflowSnapshotState {
        let boundedStepCount = min(max(completedSteps, 0), steps.count)
        switch boundedStepCount {
        case 0..<3:
            return .unstaged
        case 3..<5:
            return .staged
        case 5..<7:
            return .committedWithUntrackedFile
        case 7..<8:
            return .featureBranchWithChanges
        case 8..<10:
            return .featureBranchStaged
        case 10..<11:
            return .featureBranchCommitted
        case 11..<12:
            return .featureBranchPublished
        default:
            return .pullRequestOpen
        }
    }
}
