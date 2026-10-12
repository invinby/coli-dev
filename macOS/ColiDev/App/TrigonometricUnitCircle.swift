import Foundation

enum TrigonometricSineSign: Equatable {
    case negative
    case zero
    case positive

    var answerOriginalIndex: Int {
        switch self {
        case .negative: return 0
        case .zero: return 1
        case .positive: return 2
        }
    }

    var explanationKey: String {
        switch self {
        case .negative: return "lab.trigonometry.explanation.negative"
        case .zero: return "lab.trigonometry.explanation.zero"
        case .positive: return "lab.trigonometry.explanation.positive"
        }
    }

    static func classify(_ sine: Double) -> TrigonometricSineSign {
        if abs(sine) < 1e-9 { return .zero }
        return sine < 0 ? .negative : .positive
    }
}

struct TrigonometricUnitCircle: Equatable {
    static let periodRadians = 2 * Double.pi
    static let sineSignQuestionID = "mathematics.trigonometry_and_periodic_functions.unit_circle_sine_sign"

    let angleRadians: Double

    init?(angleRadians: Double) {
        guard angleRadians.isFinite else { return nil }
        self.angleRadians = angleRadians
    }

    var xCoordinate: Double { cos(angleRadians) }
    var yCoordinate: Double { sin(angleRadians) }
    var sineSign: TrigonometricSineSign { .classify(yCoordinate) }
    var angleDegrees: Double { angleRadians * 180 / Double.pi }
    var radiusSquared: Double { xCoordinate * xCoordinate + yCoordinate * yCoordinate }

    func sine(at radians: Double) -> Double { sin(radians) }
    func cosine(at radians: Double) -> Double { cos(radians) }
}
