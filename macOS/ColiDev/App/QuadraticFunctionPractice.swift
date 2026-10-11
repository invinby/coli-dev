import Foundation

enum QuadraticWidth: Equatable {
    case wider
    case standard
    case narrower
}

struct QuadraticFunctionPractice: Equatable {
    let coefficient: Double
    let horizontalShift: Double
    let verticalShift: Double

    init?(a: Double, h: Double, k: Double) {
        guard a.isFinite, h.isFinite, k.isFinite, a != 0 else { return nil }
        coefficient = a
        horizontalShift = h
        verticalShift = k
    }

    var vertexX: Double { horizontalShift }
    var vertexY: Double { verticalShift }
    var opensUp: Bool { coefficient > 0 }

    var width: QuadraticWidth {
        let magnitude = abs(coefficient)
        if abs(magnitude - 1) < 1e-9 { return .standard }
        return magnitude > 1 ? .narrower : .wider
    }

    func value(at x: Double) -> Double {
        coefficient * (x - horizontalShift) * (x - horizontalShift) + verticalShift
    }

    func realRoots() -> [Double] {
        let squaredOffset = -verticalShift / coefficient
        guard squaredOffset >= -1e-9 else { return [] }
        let offset = sqrt(max(0, squaredOffset))
        if offset < 1e-9 { return [horizontalShift] }
        return [horizontalShift - offset, horizontalShift + offset]
    }
}

struct QuadraticPredictionAssessment {
    static let lessonID = "mathematics.quadratic_functions_and_transformations"

    private(set) var attemptCount = 0
    private(set) var firstTryCorrect: Bool?

    mutating func recordAnswer(isCorrect: Bool) -> StudyAssessmentEvidence {
        attemptCount += 1
        if firstTryCorrect == nil {
            firstTryCorrect = isCorrect
        }
        return StudyAssessmentEvidence(
            taskType: "interactive_prediction",
            attempts: attemptCount,
            firstTryCorrect: firstTryCorrect ?? isCorrect,
            hintsUsed: 0
        )
    }
}
