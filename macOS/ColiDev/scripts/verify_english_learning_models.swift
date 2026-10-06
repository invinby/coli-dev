import Foundation

@main
enum EnglishLearningModelsVerification {
    static func main() {
        let scenarios = EnglishConditionalPractice.scenarios
        precondition(scenarios.count == EnglishConditionalForm.allCases.count, "practice must cover every taught conditional form")
        precondition(Set(scenarios.map(\.id)).count == scenarios.count, "conditional scenario IDs should be unique")
        precondition(Set(scenarios.map(\.correctForm)) == Set(EnglishConditionalForm.allCases), "each form should have one reference scenario")

        for scenario in scenarios {
            precondition(
                EnglishConditionalPractice.isCorrect(scenario.correctForm, for: scenario.id),
                "the expected form should pass for \(scenario.id)"
            )
            for alternative in EnglishConditionalForm.allCases where alternative != scenario.correctForm {
                precondition(
                    !EnglishConditionalPractice.isCorrect(alternative, for: scenario.id),
                    "an alternative form should not pass for \(scenario.id)"
                )
            }
        }

        precondition(
            !EnglishConditionalPractice.isCorrect(.zero, for: "missing-scenario"),
            "unknown scenario IDs should fail closed"
        )

        let readingQuestions = EnglishReadingPractice.questions
        precondition(readingQuestions.count == 3, "reading practice should cover its three reading strategies")
        precondition(Set(readingQuestions.map(\.id)).count == readingQuestions.count, "reading question IDs should be unique")
        for question in readingQuestions {
            precondition(
                EnglishReadingPractice.isCorrect(question.correctOption, for: question.id),
                "the reference option should pass for \(question.id)"
            )
            for alternative in 0..<3 where alternative != question.correctOption {
                precondition(
                    !EnglishReadingPractice.isCorrect(alternative, for: question.id),
                    "an alternative answer should not pass for \(question.id)"
                )
            }
        }
        precondition(!EnglishReadingPractice.isCorrect(0, for: "missing-question"), "unknown question IDs should fail closed")
        print("English conditional and reading practice model checks passed.")
    }
}
