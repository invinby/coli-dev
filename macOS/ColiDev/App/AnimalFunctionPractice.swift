import Foundation

enum AnimalFunction: String, CaseIterable, Identifiable {
    case feeding
    case gasExchange
    case movement
    case reproduction

    var id: String { rawValue }

    var titleKey: String { "lab.zoology.function.\(rawValue)" }
    var exampleKey: String { "lab.zoology.example.\(rawValue)" }
    var mechanismKey: String { "lab.zoology.mechanism.\(rawValue)" }
    var limitationKey: String { "lab.zoology.limitation.\(rawValue)" }
}

enum AnimalFunctionPractice {
    static let correctComparisonAnswer = 1

    static func makeComparisonAttempt() -> InteractivePredictionAttempt {
        guard let attempt = InteractivePredictionAttempt(
            optionCount: 3,
            answerOriginalIndex: correctComparisonAnswer,
            itemID: "zoology.animal_function.structure_task_environment_comparison"
        ) else {
            preconditionFailure("The animal-function comparison must have one valid answer.")
        }
        return attempt
    }

    static func isCorrectComparisonAnswer(_ answer: Int) -> Bool {
        answer == correctComparisonAnswer
    }
}
