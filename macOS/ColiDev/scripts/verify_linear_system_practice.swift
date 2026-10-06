import Foundation

@main
enum LinearSystemPracticeVerification {
    static func main() {
        let unique = LinearSystemPractice.scenario(id: "unique")
        precondition(LinearSystemPractice.classify(unique) == .oneSolution(x: 4, y: 3))
        precondition(LinearSystemPractice.classify(unique) == unique.outcome)
        precondition(LinearSystemPractice.isCorrectPrediction(0, for: unique))
        precondition(!LinearSystemPractice.isCorrectPrediction(1, for: unique))

        let parallel = LinearSystemPractice.scenario(id: "parallel")
        precondition(LinearSystemPractice.classify(parallel) == .noSolution)
        precondition(LinearSystemPractice.classify(parallel) == parallel.outcome)
        precondition(LinearSystemPractice.isCorrectPrediction(1, for: parallel))

        let sameLine = LinearSystemPractice.scenario(id: "same-line")
        precondition(LinearSystemPractice.classify(sameLine) == .infinitelyManySolutions)
        precondition(LinearSystemPractice.classify(sameLine) == sameLine.outcome)
        precondition(LinearSystemPractice.isCorrectPrediction(2, for: sameLine))

        precondition(LinearSystemPractice.scenario(id: "unknown").id == "unique")
        print("Linear system practice checks passed.")
    }
}
