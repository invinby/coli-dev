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
