import SwiftUI

struct StatisticsPracticeLab: View {
    @EnvironmentObject private var store: LearningStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finalMeasurement = 20.0
    @State private var answerOrder = QuizAnswerOrder(optionCount: 2, answerOriginalIndex: 1)
    @State private var selectedAnswer: Int?
    @State private var attemptCount = 0
    @State private var firstTryCorrect: Bool?

    private let optionKeys = ["lab.statistics.option.no", "lab.statistics.option.yes"]

    private var model: DescriptiveStatistics {
        DescriptiveStatistics(values: [4, 5, 5, 6, 6, finalMeasurement])!
    }

    private var maximumIsBeyondUpperFence: Bool {
        guard let maximum = model.sortedValues.last else { return false }
        return maximum > model.upperFence
    }

    private var correctAnswerIndex: Int { maximumIsBeyondUpperFence ? 1 : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("lab.statistics.intro", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            StatisticsDistributionChart(model: model, language: store.language)
                .frame(height: 168)

            Text(L10n.text("lab.statistics.plot", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], alignment: .leading, spacing: 10) {
                metric("lab.statistics.mean", value: model.mean)
                metric("lab.statistics.median", value: model.median)
                Text(String(format: L10n.text("lab.statistics.quartiles", store.language), number(model.firstQuartile), number(model.thirdQuartile)))
                Text(String(format: L10n.text("lab.statistics.iqr", store.language), number(model.interquartileRange)))
                Text(String(format: L10n.text("lab.statistics.fences", store.language), number(model.lowerFence), number(model.upperFence)))
            }
            .font(.callout.monospacedDigit())

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.text("lab.statistics.slider", store.language))
                    Spacer()
                    Text(number(finalMeasurement))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $finalMeasurement, in: 6...24, step: 0.5)
                    .accessibilityLabel(Text(L10n.text("lab.statistics.slider", store.language)))
                    .accessibilityValue(Text(number(finalMeasurement)))
                    .accessibilityIdentifier("statistics.final-measurement-slider")
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text("lab.statistics.question", store.language))
                    .font(.headline)

                ForEach(Array(answerOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Button {
                        submitAnswer(displayIndex)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: selectedAnswer == displayIndex ? "checkmark.circle.fill" : "circle")
                            Text(L10n.text(optionKeys[originalIndex], store.language))
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 11))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedAnswer != nil)
                    .accessibilityAddTraits(selectedAnswer == displayIndex ? .isSelected : [])
                }

                if let selectedAnswer {
                    let correct = answerOrder.isCorrect(displayedIndex: selectedAnswer)
                    Label(
                        L10n.text(correct ? "lab.statistics.correct" : "lab.statistics.retry", store.language),
                        systemImage: correct ? "checkmark.circle.fill" : "arrow.uturn.backward.circle"
                    )
                    .foregroundStyle(correct ? Color.green : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)

                    if correct {
                        Text(L10n.text("lab.statistics.explanation", store.language))
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Button(L10n.text("lab.statistics.tryAgain", store.language), action: retry)
                            .buttonStyle(.bordered)
                    }
                }
            }

            Text(L10n.text("lab.statistics.limits", store.language))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(
                            colors: [
                                ColiDevVisualSystem.subjectColor("Mathematics").opacity(0.13),
                                Color.cyan.opacity(0.035),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("statistics.practice-lab")
        .animation(
            reduceMotion ? nil : .easeInOut(duration: ColiDevVisualSystem.routineTransitionDuration),
            value: finalMeasurement
        )
        .onChange(of: finalMeasurement) { _ in
            selectedAnswer = nil
            answerOrder = QuizAnswerOrder(optionCount: optionKeys.count, answerOriginalIndex: correctAnswerIndex)
        }
    }

    private func metric(_ key: String, value: Double) -> some View {
        Text(String(format: L10n.text(key, store.language), number(value)))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(9)
            .background(Color.secondary.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
    }

    private func number(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: store.language == .ru ? "ru_RU" : "en_US_POSIX")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func submitAnswer(_ displayIndex: Int) {
        guard selectedAnswer == nil else { return }
        let correct = answerOrder.isCorrect(displayedIndex: displayIndex)
        attemptCount += 1
        if firstTryCorrect == nil { firstTryCorrect = correct }
        selectedAnswer = displayIndex
        store.recordStudyAssessment(
            lessonID: "mathematics.descriptive_statistics_and_potential_outliers",
            evidence: StudyAssessmentEvidence(
                taskType: "interactive_prediction",
                attempts: attemptCount,
                firstTryCorrect: firstTryCorrect ?? correct,
                hintsUsed: 0
            )
        )
    }

    private func retry() {
        answerOrder = QuizAnswerOrder(optionCount: optionKeys.count, answerOriginalIndex: correctAnswerIndex)
        selectedAnswer = nil
    }
}

private struct StatisticsDistributionChart: View {
    let model: DescriptiveStatistics
    let language: AppLanguage

    private let minimumValue = 0.0
    private let maximumValue = 25.0

    var body: some View {
        Canvas { context, size in
            let left: CGFloat = 18
            let right: CGFloat = size.width - 18
            let plotWidth = max(1, right - left)
            let baseline = size.height * 0.7
            let xPosition: (Double) -> CGFloat = { value in
                left + CGFloat((value - minimumValue) / (maximumValue - minimumValue)) * plotWidth
            }

            var axis = Path()
            axis.move(to: CGPoint(x: left, y: baseline))
            axis.addLine(to: CGPoint(x: right, y: baseline))
            context.stroke(axis, with: .color(.secondary.opacity(0.45)), lineWidth: 1)

            for tick in stride(from: 0.0, through: 25.0, by: 5.0) {
                let x = xPosition(tick)
                var tickMark = Path()
                tickMark.move(to: CGPoint(x: x, y: baseline - 4))
                tickMark.addLine(to: CGPoint(x: x, y: baseline + 4))
                context.stroke(tickMark, with: .color(.secondary.opacity(0.4)), lineWidth: 1)
                context.draw(
                    context.resolve(Text("\(Int(tick))").font(.caption2).foregroundColor(.secondary)),
                    at: CGPoint(x: x, y: min(size.height - 8, baseline + 16))
                )
            }

            for fence in [model.lowerFence, model.upperFence] where (minimumValue...maximumValue).contains(fence) {
                var fenceLine = Path()
                fenceLine.move(to: CGPoint(x: xPosition(fence), y: 8))
                fenceLine.addLine(to: CGPoint(x: xPosition(fence), y: baseline))
                context.stroke(fenceLine, with: .color(.orange.opacity(0.72)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
            }

            var repeatedValueRows: [Double: Int] = [:]
            for value in model.sortedValues {
                let row = repeatedValueRows[value, default: 0]
                repeatedValueRows[value] = row + 1
                let point = CGPoint(x: xPosition(value), y: baseline - 13 - CGFloat(row) * 16)
                let marker = Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12))
                let isPotentialOutlier = value < model.lowerFence || value > model.upperFence
                context.fill(marker, with: .color(isPotentialOutlier ? .red : ColiDevVisualSystem.subjectColor("Mathematics")))
            }
        }
        .padding(.horizontal, 4)
        .background(Color.secondary.opacity(0.045), in: RoundedRectangle(cornerRadius: 13))
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.text("lab.statistics.plot", language)))
        .accessibilityValue(Text(String(format: L10n.text("lab.statistics.accessibility", language),
                                        String(model.potentialOutlierValues.count),
                                        number(model.lowerFence),
                                        number(model.upperFence))))
    }

    private func number(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: language == .ru ? "ru_RU" : "en_US_POSIX")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
