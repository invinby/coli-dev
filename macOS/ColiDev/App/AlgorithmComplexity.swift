import Foundation

enum AlgorithmComplexityPractice {
    static let sampleSizes = [16, 64, 256, 1024]

    static func linearSearchWorstCaseComparisons(for itemCount: Int) -> Int {
        max(0, itemCount)
    }

    static func binarySearchWorstCaseComparisons(for itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }
        return Int(ceil(log2(Double(itemCount) + 1)))
    }

    static func binarySearchApplies(isSorted: Bool) -> Bool {
        isSorted
    }
}
