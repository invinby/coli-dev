import Foundation

struct LinearFunctionModel: Equatable {
    let slope: Double
    let intercept: Double

    init?(slope: Double, intercept: Double) {
        guard slope.isFinite, intercept.isFinite else { return nil }
        self.slope = slope
        self.intercept = intercept
    }

    func value(at input: Double) -> Double? {
        guard input.isFinite else { return nil }
        let output = slope * input + intercept
        return output.isFinite ? output : nil
    }
}

enum LinearFunctionPracticeRoute {
    static let subjectID = "mathematics"
    static let lessonResource = "functions_as_models"
    static let lessonID = "mathematics.functions_as_models"

    static func matches(subjectID: String, resource: String?) -> Bool {
        subjectID == Self.subjectID && resource == Self.lessonResource
    }
}

struct LinearFunctionPredictionRound {
    static let lessonID = LinearFunctionPracticeRoute.lessonID
    static let itemID = "mathematics.functions_as_models.evaluate_linear_function"

    let function: LinearFunctionModel
    let input: Double

    private(set) var attempts = 0
    private(set) var firstTryCorrect: Bool?
    private(set) var submittedAnswer: Double?
    private(set) var lastAnswerCorrect: Bool?

    init(function: LinearFunctionModel, input: Double) {
        self.function = function
        self.input = input
    }

    var evidence: StudyAssessmentEvidence? {
        guard attempts > 0, let firstTryCorrect else { return nil }
        return StudyAssessmentEvidence(
            taskType: "interactive_prediction",
            attempts: attempts,
            firstTryCorrect: firstTryCorrect,
            hintsUsed: 0,
            itemID: Self.itemID
        )
    }

    mutating func submit(answer: Double) -> Bool? {
        guard submittedAnswer == nil,
              answer.isFinite,
              let expected = function.value(at: input) else { return nil }

        let correct = abs(answer - expected) < 1e-9
        attempts += 1
        if firstTryCorrect == nil {
            firstTryCorrect = correct
        }
        submittedAnswer = answer
        lastAnswerCorrect = correct
        return correct
    }

    mutating func retry() {
        guard lastAnswerCorrect == false else { return }
        submittedAnswer = nil
        lastAnswerCorrect = nil
    }
}
