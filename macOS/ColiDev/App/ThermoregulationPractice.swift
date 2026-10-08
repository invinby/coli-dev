import Foundation

struct ThermalExposureRange: Equatable, Identifiable {
    let id: String
    let minimumCelsius: Double
    let maximumCelsius: Double
}

enum ThermoregulationPractice {
    // EN: Values reported for the Coats Island study site; they are not a species-wide forecast.
    // RU: Значения опубликованы для площадки у острова Коутс; это не прогноз для всего вида.
    static let ambientAirRange = ThermalExposureRange(
        id: "ambient-air",
        minimumCelsius: 3.4,
        maximumCelsius: 24.7
    )
    static let operativeTemperatureRange = ThermalExposureRange(
        id: "operative-temperature",
        minimumCelsius: 5.5,
        maximumCelsius: 46.5
    )
    static let chartMaximumCelsius = 50.0
    static let studyHeatStressThresholdCelsius = 21.2
    static let heatStressDayPercentage = 61
    static let heatStressDayRange = 24...85

    static let correctThresholdInterpretationAnswer = 0

    static func isCorrectThresholdInterpretationAnswer(_ answer: Int) -> Bool {
        answer == correctThresholdInterpretationAnswer
    }
}
