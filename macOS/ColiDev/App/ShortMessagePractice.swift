import Foundation

struct ShortMessageStep: Equatable, Identifiable {
    let id: String
    let promptKey: String
    let optionKeys: [String]
    let correctOptionIndex: Int
    let explanationKey: String
}

/// Building an informal thank-you email to a friend in five parts, following the structure in the
/// British Council LearnEnglish A1 lesson “A thank-you email”: greeting, reason, details, a wish, closing.
enum ShortMessagePractice {
    static let steps = [
        ShortMessageStep(
            id: "english.short_message.greeting",
            promptKey: "lab.message.greeting.prompt",
            optionKeys: ["lab.message.greeting.option0", "lab.message.greeting.option1", "lab.message.greeting.option2"],
            correctOptionIndex: 0,
            explanationKey: "lab.message.greeting.explanation"
        ),
        ShortMessageStep(
            id: "english.short_message.reason",
            promptKey: "lab.message.reason.prompt",
            optionKeys: ["lab.message.reason.option0", "lab.message.reason.option1", "lab.message.reason.option2"],
            correctOptionIndex: 1,
            explanationKey: "lab.message.reason.explanation"
        ),
        ShortMessageStep(
            id: "english.short_message.details",
            promptKey: "lab.message.details.prompt",
            optionKeys: ["lab.message.details.option0", "lab.message.details.option1", "lab.message.details.option2"],
            correctOptionIndex: 2,
            explanationKey: "lab.message.details.explanation"
        ),
        ShortMessageStep(
            id: "english.short_message.wish",
            promptKey: "lab.message.wish.prompt",
            optionKeys: ["lab.message.wish.option0", "lab.message.wish.option1", "lab.message.wish.option2"],
            correctOptionIndex: 0,
            explanationKey: "lab.message.wish.explanation"
        ),
        ShortMessageStep(
            id: "english.short_message.closing",
            promptKey: "lab.message.closing.prompt",
            optionKeys: ["lab.message.closing.option0", "lab.message.closing.option1", "lab.message.closing.option2"],
            correctOptionIndex: 1,
            explanationKey: "lab.message.closing.explanation"
        )
    ]

    static func isCorrect(_ option: Int, stepID: String) -> Bool {
        guard let step = steps.first(where: { $0.id == stepID }),
              step.optionKeys.indices.contains(option) else { return false }
        return option == step.correctOptionIndex
    }

    /// The finished email: the correct option of every step, in order.
    static var assembledMessageKeys: [String] {
        steps.map { $0.optionKeys[$0.correctOptionIndex] }
    }
}
