import Foundation

struct DescriptiveStatistics: Equatable {
    let sortedValues: [Double]
    let mean: Double
    let median: Double
    let firstQuartile: Double
    let thirdQuartile: Double
    let interquartileRange: Double
    let lowerFence: Double
    let upperFence: Double
    let potentialOutlierValues: [Double]

    init?(values: [Double]) {
        guard values.count >= 2, values.allSatisfy(\.isFinite) else { return nil }

        let sorted = values.sorted()
        let middle = sorted.count / 2
        let lowerHalf = Array(sorted[..<middle])
        let upperStart = sorted.count.isMultiple(of: 2) ? middle : middle + 1
        let upperHalf = Array(sorted[upperStart...])
        let median = Self.median(of: sorted)
        let firstQuartile = Self.median(of: lowerHalf)
        let thirdQuartile = Self.median(of: upperHalf)
        let interquartileRange = thirdQuartile - firstQuartile
        let lowerFence = firstQuartile - 1.5 * interquartileRange
        let upperFence = thirdQuartile + 1.5 * interquartileRange
        let mean = sorted.reduce(0.0) { $0 + $1 / Double(sorted.count) }

        guard median.isFinite,
              firstQuartile.isFinite,
              thirdQuartile.isFinite,
              interquartileRange.isFinite,
              lowerFence.isFinite,
              upperFence.isFinite,
              mean.isFinite else { return nil }

        self.sortedValues = sorted
        self.mean = mean
        self.median = median
        self.firstQuartile = firstQuartile
        self.thirdQuartile = thirdQuartile
        self.interquartileRange = interquartileRange
        self.lowerFence = lowerFence
        self.upperFence = upperFence
        self.potentialOutlierValues = sorted.filter { $0 < lowerFence || $0 > upperFence }
    }

    private static func median(of orderedValues: [Double]) -> Double {
        let middle = orderedValues.count / 2
        if orderedValues.count.isMultiple(of: 2) {
            return orderedValues[middle - 1] / 2 + orderedValues[middle] / 2
        }
        return orderedValues[middle]
    }
}
