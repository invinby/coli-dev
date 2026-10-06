import Foundation

enum EnglishConditionalForm: Int, CaseIterable, Hashable {
    case zero
    case first
    case second
}

struct EnglishConditionalScenario: Equatable, Identifiable {
    let id: String
    let correctForm: EnglishConditionalForm
}

enum EnglishConditionalPractice {
    static let scenarios = [
        EnglishConditionalScenario(id: "general-rule", correctForm: .zero),
        EnglishConditionalScenario(id: "real-future", correctForm: .first),
        EnglishConditionalScenario(id: "imagined-condition", correctForm: .second)
    ]

    static func isCorrect(_ selectedForm: EnglishConditionalForm, for scenarioID: String) -> Bool {
        guard let scenario = scenarios.first(where: { $0.id == scenarioID }) else { return false }
        return scenario.correctForm == selectedForm
    }
}
