import Foundation

@main
enum MeasurementUncertaintyVerification {
    static func main() {
        precondition(MeasurementUncertaintyModel.referenceInTenthsOfCentimetre == 100)
        precondition(MeasurementUncertaintyModel.meanInTenths(of: .a) == 100)
        precondition(abs(MeasurementUncertaintyModel.meanInTenths(of: .b) - (310.0 / 3.0)) < 0.000_001)
        precondition(MeasurementUncertaintyModel.spreadInTenths(of: .a) == 2)
        precondition(MeasurementUncertaintyModel.spreadInTenths(of: .b) == 1)
        precondition(MeasurementUncertaintyModel.bestSeries(for: .accuracy) == .a)
        precondition(MeasurementUncertaintyModel.bestSeries(for: .precision) == .b)
        precondition(MeasurementUncertaintyModel.isCorrect(.a, for: .accuracy))
        precondition(!MeasurementUncertaintyModel.isCorrect(.b, for: .accuracy))
        precondition(MeasurementUncertaintyModel.halfSmallestDivisionMillimetres(10) == 5)
        precondition(MeasurementUncertaintyModel.halfSmallestDivisionMillimetres(1) == 0.5)
        precondition(MeasurementUncertaintyModel.halfSmallestDivisionMillimetres(0) == nil)
        precondition(MeasurementUncertaintyModel.halfSmallestDivisionMillimetres(1_001) == nil)
        print("Physics measurement uncertainty model checks passed.")
    }
}
