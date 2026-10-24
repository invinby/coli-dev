import Foundation

struct LabeledPracticeExample: Equatable {
    let minutes: Int
    let passed: Bool
}

struct HeldOutAccuracy: Equatable {
    let correct: Int
    let total: Int

    var percent: Int {
        guard total > 0 else { return 0 }
        return Int((Double(correct) * 100 / Double(total)).rounded())
    }
}

/// A k-nearest-neighbours experiment for the held-out evaluation lesson.
/// The examples are invented for practice; they are not data about real learners.
enum HeldOutEvaluationPractice {
    static let neighbourCounts = [1, 3, 5, 7, 9, 11, 13]

    static let trainingExamples: [LabeledPracticeExample] = [
        .init(minutes: 10, passed: false), .init(minutes: 15, passed: false), .init(minutes: 20, passed: false),
        .init(minutes: 25, passed: true), .init(minutes: 30, passed: false), .init(minutes: 35, passed: false),
        .init(minutes: 40, passed: true), .init(minutes: 45, passed: true), .init(minutes: 50, passed: false),
        .init(minutes: 55, passed: true), .init(minutes: 60, passed: true), .init(minutes: 65, passed: true),
        .init(minutes: 70, passed: true)
    ]

    static let heldOutExamples: [LabeledPracticeExample] = [
        .init(minutes: 12, passed: false), .init(minutes: 17, passed: false), .init(minutes: 22, passed: false),
        .init(minutes: 27, passed: false), .init(minutes: 33, passed: false), .init(minutes: 38, passed: false),
        .init(minutes: 42, passed: false), .init(minutes: 47, passed: true), .init(minutes: 52, passed: true),
        .init(minutes: 58, passed: true), .init(minutes: 63, passed: true), .init(minutes: 68, passed: true)
    ]

    /// Majority vote of the `k` closest training examples. Equal distances keep the earlier training example,
    /// and the lab offers only odd `k`, so a two-class vote cannot tie.
    static func predictsPass(minutes: Int, neighbours k: Int) -> Bool {
        let count = min(max(k, 1), trainingExamples.count)
        let nearest = trainingExamples.enumerated()
            .sorted { lhs, rhs in
                let left = abs(lhs.element.minutes - minutes)
                let right = abs(rhs.element.minutes - minutes)
                return left == right ? lhs.offset < rhs.offset : left < right
            }
            .prefix(count)
        let passes = nearest.filter { $0.element.passed }.count
        return passes * 2 > count
    }

    static func accuracy(of examples: [LabeledPracticeExample], neighbours k: Int) -> HeldOutAccuracy {
        let correct = examples.filter { predictsPass(minutes: $0.minutes, neighbours: k) == $0.passed }.count
        return HeldOutAccuracy(correct: correct, total: examples.count)
    }

    static var majorityTrainingLabel: Bool {
        trainingExamples.filter { $0.passed }.count * 2 > trainingExamples.count
    }

    /// The most-frequent-class baseline ignores the input, like scikit-learn's `DummyClassifier(strategy="most_frequent")`.
    static func baselineAccuracy(on examples: [LabeledPracticeExample]) -> HeldOutAccuracy {
        let label = majorityTrainingLabel
        return HeldOutAccuracy(correct: examples.filter { $0.passed == label }.count, total: examples.count)
    }

    /// The smallest `k` with the best held-out accuracy.
    static var bestHeldOutNeighbourCount: Int {
        var best = neighbourCounts[0]
        var bestCorrect = accuracy(of: heldOutExamples, neighbours: best).correct
        for k in neighbourCounts.dropFirst() {
            let correct = accuracy(of: heldOutExamples, neighbours: k).correct
            if correct > bestCorrect {
                best = k
                bestCorrect = correct
            }
        }
        return best
    }

    /// A gap of at least 15 percentage points between training and held-out accuracy is shown as overfitting.
    static func showsOverfitting(neighbours k: Int) -> Bool {
        accuracy(of: trainingExamples, neighbours: k).percent - accuracy(of: heldOutExamples, neighbours: k).percent >= 15
    }

    static func matchesBaseline(neighbours k: Int) -> Bool {
        accuracy(of: heldOutExamples, neighbours: k).correct <= baselineAccuracy(on: heldOutExamples).correct
    }
}
