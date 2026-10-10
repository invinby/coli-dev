import Foundation

enum LinearSystemOutcome: Equatable {
    case oneSolution(x: Double, y: Double)
    case noSolution
    case infinitelyManySolutions
}

struct LinearSystemScenario: Identifiable {
    let id: String
    let first: (x: Int, y: Int, result: Int)
    let second: (x: Int, y: Int, result: Int)
    let outcome: LinearSystemOutcome
    let eliminationResult: (x: Int, result: Int)
}

enum LinearSystemPractice {
    static let scenarios: [LinearSystemScenario] = [
        LinearSystemScenario(
            id: "unique",
            first: (2, 1, 11),
            second: (1, -1, 1),
            outcome: .oneSolution(x: 4, y: 3),
            eliminationResult: (3, 12)
        ),
        LinearSystemScenario(
            id: "parallel",
            first: (1, 1, 8),
            second: (-1, -1, -10),
            outcome: .noSolution,
            eliminationResult: (0, -2)
        ),
        LinearSystemScenario(
            id: "same-line",
            first: (1, 1, 4),
            second: (-2, -2, -8),
            outcome: .infinitelyManySolutions,
            eliminationResult: (0, 0)
        )
    ]

    static func scenario(id: String) -> LinearSystemScenario {
        scenarios.first(where: { $0.id == id }) ?? scenarios[0]
    }

    static func classify(_ scenario: LinearSystemScenario) -> LinearSystemOutcome {
        let determinant = scenario.first.x * scenario.second.y - scenario.second.x * scenario.first.y
        guard determinant != 0 else {
            let constantsAgree = scenario.first.x * scenario.second.result == scenario.second.x * scenario.first.result
                && scenario.first.y * scenario.second.result == scenario.second.y * scenario.first.result
            return constantsAgree ? .infinitelyManySolutions : .noSolution
        }

        let xNumerator = scenario.first.result * scenario.second.y - scenario.second.result * scenario.first.y
        let yNumerator = scenario.first.x * scenario.second.result - scenario.second.x * scenario.first.result
        return .oneSolution(
            x: Double(xNumerator) / Double(determinant),
            y: Double(yNumerator) / Double(determinant)
        )
    }

    static func isCorrectPrediction(_ prediction: Int, for scenario: LinearSystemScenario) -> Bool {
        prediction == correctPredictionIndex(for: scenario)
    }

    static func correctPredictionIndex(for scenario: LinearSystemScenario) -> Int {
        switch classify(scenario) {
        case .oneSolution:
            0
        case .noSolution:
            1
        case .infinitelyManySolutions:
            2
        }
    }
}
