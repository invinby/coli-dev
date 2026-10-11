import Foundation

@main
enum DescriptiveStatisticsVerification {
    static func main() {
        guard let sample = DescriptiveStatistics(values: [4, 5, 5, 6, 6, 20]) else {
            preconditionFailure("Finite sample data must be accepted. / Конечные данные выборки должны приниматься.")
        }
        precondition(close(sample.mean, 46.0 / 6.0), "Mean calculation is wrong. / Среднее вычислено неверно.")
        precondition(close(sample.median, 5.5), "Even-sized median is wrong. / Медиана чётного набора вычислена неверно.")
        precondition(close(sample.firstQuartile, 5), "Lower-half median is wrong. / Медиана нижней половины неверна.")
        precondition(close(sample.thirdQuartile, 6), "Upper-half median is wrong. / Медиана верхней половины неверна.")
        precondition(close(sample.interquartileRange, 1), "IQR calculation is wrong. / Межквартильный размах вычислен неверно.")
        precondition(close(sample.lowerFence, 3.5), "Lower fence calculation is wrong. / Нижняя граница вычислена неверно.")
        precondition(close(sample.upperFence, 7.5), "Upper fence calculation is wrong. / Верхняя граница вычислена неверно.")
        precondition(sample.potentialOutlierValues == [20], "Only the extreme observation should be flagged. / Помечаться должно только крайнее наблюдение.")

        guard let atFence = DescriptiveStatistics(values: [4, 5, 5, 6, 6, 7.5]),
              let beyondFence = DescriptiveStatistics(values: [4, 5, 5, 6, 6, 7.51]) else {
            preconditionFailure("Finite boundary samples must be accepted. / Конечные граничные наборы должны приниматься.")
        }
        precondition(atFence.potentialOutlierValues.isEmpty, "A value exactly on a fence is not beyond it. / Значение ровно на границе не выходит за неё.")
        precondition(beyondFence.potentialOutlierValues == [7.51], "A value beyond the fence should be flagged. / Значение за границей должно быть помечено.")

        guard let oddSample = DescriptiveStatistics(values: [1, 2, 100, 3, 4]) else {
            preconditionFailure("Odd-sized sample data must be accepted. / Нечётный набор должен приниматься.")
        }
        precondition(close(oddSample.median, 3), "Odd-sized median is wrong. / Медиана нечётного набора неверна.")
        precondition(close(oddSample.firstQuartile, 1.5), "Overall median should be excluded from the lower half. / Общая медиана должна исключаться из нижней половины.")
        precondition(close(oddSample.thirdQuartile, 52), "Overall median should be excluded from the upper half. / Общая медиана должна исключаться из верхней половины.")
        precondition(DescriptiveStatistics(values: []).isNone, "Empty data must be rejected. / Пустые данные должны отклоняться.")
        precondition(DescriptiveStatistics(values: [1, .nan]).isNone, "NaN must be rejected. / NaN должен отклоняться.")
        precondition(DescriptiveStatistics(values: [1, .infinity]).isNone, "Infinity must be rejected. / Бесконечность должна отклоняться.")

        print("Descriptive statistics checks passed. / Проверки описательной статистики прошли.")
    }

    private static func close(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 1e-9
    }
}

private extension Optional {
    var isNone: Bool {
        if case .none = self { return true }
        return false
    }
}
