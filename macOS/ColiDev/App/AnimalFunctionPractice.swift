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

    static func isCorrectComparisonAnswer(_ answer: Int) -> Bool {
        answer == correctComparisonAnswer
    }
}
