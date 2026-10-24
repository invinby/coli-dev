import Foundation

@main
enum HeldOutEvaluationVerification {
    static func main() {
        let expected: [Int: (training: Int, heldOut: Int)] = [
            1: (13, 8), 3: (11, 10), 5: (9, 11), 7: (11, 10), 9: (11, 10), 11: (11, 10), 13: (7, 5)
        ]
        precondition(HeldOutEvaluationPractice.neighbourCounts == [1, 3, 5, 7, 9, 11, 13])
        precondition(HeldOutEvaluationPractice.trainingExamples.count == 13)
        precondition(HeldOutEvaluationPractice.heldOutExamples.count == 12)

        let trainingMinutes = Set(HeldOutEvaluationPractice.trainingExamples.map { $0.minutes })
        precondition(
            HeldOutEvaluationPractice.heldOutExamples.allSatisfy { !trainingMinutes.contains($0.minutes) },
            "held-out examples must not repeat training inputs"
        )

        for k in HeldOutEvaluationPractice.neighbourCounts {
            precondition(k % 2 == 1, "only odd k avoids two-class vote ties")
            guard let counts = expected[k] else { preconditionFailure("missing expectation for k=\(k)") }
            let training = HeldOutEvaluationPractice.accuracy(of: HeldOutEvaluationPractice.trainingExamples, neighbours: k)
            let heldOut = HeldOutEvaluationPractice.accuracy(of: HeldOutEvaluationPractice.heldOutExamples, neighbours: k)
            precondition(training == HeldOutAccuracy(correct: counts.training, total: 13), "training accuracy for k=\(k)")
            precondition(heldOut == HeldOutAccuracy(correct: counts.heldOut, total: 12), "held-out accuracy for k=\(k)")
        }

        precondition(HeldOutEvaluationPractice.majorityTrainingLabel, "seven of thirteen training examples passed")
        let baseline = HeldOutEvaluationPractice.baselineAccuracy(on: HeldOutEvaluationPractice.heldOutExamples)
        precondition(baseline == HeldOutAccuracy(correct: 5, total: 12))
        precondition(
            HeldOutEvaluationPractice.accuracy(of: HeldOutEvaluationPractice.heldOutExamples, neighbours: 13) == baseline,
            "letting every training example vote collapses to the majority baseline"
        )
        precondition(HeldOutEvaluationPractice.bestHeldOutNeighbourCount == 5)

        precondition(HeldOutEvaluationPractice.showsOverfitting(neighbours: 1), "k=1 memorises the noisy training labels")
        for k in [3, 5, 7, 9, 11, 13] {
            precondition(!HeldOutEvaluationPractice.showsOverfitting(neighbours: k), "no large gap for k=\(k)")
        }
        precondition(HeldOutEvaluationPractice.matchesBaseline(neighbours: 13))
        for k in [1, 3, 5, 7, 9, 11] {
            precondition(!HeldOutEvaluationPractice.matchesBaseline(neighbours: k), "k=\(k) should beat the baseline")
        }

        precondition(HeldOutAccuracy(correct: 8, total: 12).percent == 67)
        precondition(HeldOutAccuracy(correct: 11, total: 12).percent == 92)
        precondition(HeldOutAccuracy(correct: 5, total: 12).percent == 42)
        precondition(HeldOutAccuracy(correct: 0, total: 0).percent == 0)
        print("Held-out evaluation model checks passed.")
    }
}
