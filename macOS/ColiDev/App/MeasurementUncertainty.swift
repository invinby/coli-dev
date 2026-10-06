import Foundation

enum MeasurementSeries: String, CaseIterable, Identifiable {
    case a
    case b

    var id: String { rawValue }
    var titleKey: String { "lab.physics.measurement.series.\(rawValue)" }
    var readingsInTenthsOfCentimetre: [Int] {
        switch self {
        case .a: [99, 100, 101]
        case .b: [103, 103, 104]
        }
    }
}

enum MeasurementCriterion: String, CaseIterable, Identifiable {
    case accuracy
    case precision

    var id: String { rawValue }
    var titleKey: String { "lab.physics.measurement.criterion.\(rawValue)" }
}

enum MeasurementUncertaintyModel {
    static let referenceInTenthsOfCentimetre = 100

    static func meanInTenths(of series: MeasurementSeries) -> Double {
        let readings = series.readingsInTenthsOfCentimetre
        guard !readings.isEmpty else { return 0 }
        return Double(readings.reduce(0, +)) / Double(readings.count)
    }

    static func spreadInTenths(of series: MeasurementSeries) -> Int {
        let readings = series.readingsInTenthsOfCentimetre
        guard let lowest = readings.min(), let highest = readings.max() else { return 0 }
        return highest - lowest
    }

    static func bestSeries(for criterion: MeasurementCriterion) -> MeasurementSeries? {
        let series = MeasurementSeries.allCases
        guard series.count == 2 else { return nil }

        switch criterion {
        case .accuracy:
            let ordered = series.sorted {
                abs(meanInTenths(of: $0) - Double(referenceInTenthsOfCentimetre))
                    < abs(meanInTenths(of: $1) - Double(referenceInTenthsOfCentimetre))
            }
            guard let first = ordered.first, let second = ordered.last else { return nil }
            let firstError = abs(meanInTenths(of: first) - Double(referenceInTenthsOfCentimetre))
            let secondError = abs(meanInTenths(of: second) - Double(referenceInTenthsOfCentimetre))
            return firstError == secondError ? nil : first
        case .precision:
            let ordered = series.sorted { spreadInTenths(of: $0) < spreadInTenths(of: $1) }
            guard let first = ordered.first, let second = ordered.last else { return nil }
            return spreadInTenths(of: first) == spreadInTenths(of: second) ? nil : first
        }
    }

    static func isCorrect(_ answer: MeasurementSeries, for criterion: MeasurementCriterion) -> Bool {
        answer == bestSeries(for: criterion)
    }

    static func halfSmallestDivisionMillimetres(_ division: Int) -> Double? {
        guard (1...1_000).contains(division) else { return nil }
        return Double(division) / 2
    }
}
