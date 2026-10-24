import Foundation

@main
enum ShortMessageVerification {
    static func main() {
        let steps = ShortMessagePractice.steps
        precondition(steps.map(\.id) == [
            "english.short_message.greeting",
            "english.short_message.reason",
            "english.short_message.details",
            "english.short_message.wish",
            "english.short_message.closing"
        ], "greeting, reason, details, wish, closing in that order")
        precondition(Set(steps.map(\.id)).count == steps.count)
        precondition(Set(steps.map(\.correctOptionIndex)).count > 1, "correct answers do not always sit in the same position")

        for step in steps {
            precondition(step.optionKeys.count == 3)
            precondition(step.optionKeys.indices.contains(step.correctOptionIndex))
            precondition(ShortMessagePractice.isCorrect(step.correctOptionIndex, stepID: step.id))
            for option in step.optionKeys.indices where option != step.correctOptionIndex {
                precondition(!ShortMessagePractice.isCorrect(option, stepID: step.id))
            }
            precondition(step.optionKeys.allSatisfy { $0.hasPrefix(step.promptKey.replacingOccurrences(of: ".prompt", with: ".option")) })
        }
        precondition(!ShortMessagePractice.isCorrect(-1, stepID: steps[0].id))
        precondition(!ShortMessagePractice.isCorrect(0, stepID: "english.short_message.unknown"))
        precondition(ShortMessagePractice.assembledMessageKeys == [
            "lab.message.greeting.option0",
            "lab.message.reason.option1",
            "lab.message.details.option2",
            "lab.message.wish.option0",
            "lab.message.closing.option1"
        ])
        print("Short message practice checks passed.")
    }
}
