import Foundation

@main
enum ThermoregulationPracticeVerification {
    static func main() {
        let expectedHeatStressDayRange = 24...85
        precondition(ThermoregulationPractice.chartMaximumCelsius == 50)
        precondition(ThermoregulationPractice.ambientAirRange.minimumCelsius == 3.4)
        precondition(ThermoregulationPractice.ambientAirRange.maximumCelsius == 24.7)
        precondition(ThermoregulationPractice.operativeTemperatureRange.minimumCelsius == 5.5)
        precondition(ThermoregulationPractice.operativeTemperatureRange.maximumCelsius == 46.5)
        precondition(ThermoregulationPractice.studyHeatStressThresholdCelsius == 21.2)
        precondition(ThermoregulationPractice.heatStressDayPercentage == 61)
        precondition(ThermoregulationPractice.heatStressDayRange == expectedHeatStressDayRange)
        precondition(ThermoregulationPractice.isCorrectThresholdInterpretationAnswer(0))
        precondition(!ThermoregulationPractice.isCorrectThresholdInterpretationAnswer(1))
        precondition(!ThermoregulationPractice.isCorrectThresholdInterpretationAnswer(2))
        print("Thermoregulation field-data model checks passed. / Проверка модели полевых данных терморегуляции пройдена.")
    }
}
