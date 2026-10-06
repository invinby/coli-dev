import Foundation

@main
enum AnimalFunctionPracticeVerification {
    static func main() {
        precondition(AnimalFunction.allCases.count == 4)
        precondition(Set(AnimalFunction.allCases.map(\.rawValue)).count == 4)
        for function in AnimalFunction.allCases {
            precondition(!function.titleKey.isEmpty)
            precondition(!function.exampleKey.isEmpty)
            precondition(!function.mechanismKey.isEmpty)
            precondition(!function.limitationKey.isEmpty)
        }
        precondition(!AnimalFunctionPractice.isCorrectComparisonAnswer(-1))
        precondition(!AnimalFunctionPractice.isCorrectComparisonAnswer(0))
        precondition(AnimalFunctionPractice.isCorrectComparisonAnswer(1))
        precondition(!AnimalFunctionPractice.isCorrectComparisonAnswer(2))
        print("Animal function practice checks passed.")
    }
}
