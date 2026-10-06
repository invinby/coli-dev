import Foundation

@main
enum AlgorithmComplexityVerification {
    static func main() {
        let expectedBinaryBounds = [5, 7, 9, 11]
        precondition(AlgorithmComplexityPractice.sampleSizes.count == expectedBinaryBounds.count)
        for (index, itemCount) in AlgorithmComplexityPractice.sampleSizes.enumerated() {
            let linear = AlgorithmComplexityPractice.linearSearchWorstCaseComparisons(for: itemCount)
            let binary = AlgorithmComplexityPractice.binarySearchWorstCaseComparisons(for: itemCount)
            precondition(linear == itemCount, "linear search can inspect every item")
            precondition(binary == expectedBinaryBounds[index], "binary upper bound should be ceil(log2(n + 1))")
            precondition(binary < linear, "binary search should use fewer comparisons for the displayed sizes")
        }
        precondition(AlgorithmComplexityPractice.binarySearchWorstCaseComparisons(for: 0) == 0)
        precondition(AlgorithmComplexityPractice.binarySearchApplies(isSorted: true))
        precondition(!AlgorithmComplexityPractice.binarySearchApplies(isSorted: false))
        print("Algorithm complexity checks passed.")
    }
}
