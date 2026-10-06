import Foundation

@main
enum ThermoregulationVerification {
    static func main() {
        precondition(ThermoregulationModel.recommendedResponse(for: .ectotherm, in: .cool) == .externalHeat)
        precondition(ThermoregulationModel.recommendedResponse(for: .ectotherm, in: .mild) == .observe)
        precondition(ThermoregulationModel.recommendedResponse(for: .ectotherm, in: .hot) == .coolerMicrohabitat)
        precondition(ThermoregulationModel.recommendedResponse(for: .endotherm, in: .cool) == .conserveHeat)
        precondition(ThermoregulationModel.recommendedResponse(for: .endotherm, in: .mild) == .observe)
        precondition(ThermoregulationModel.recommendedResponse(for: .endotherm, in: .hot) == .dissipateHeat)
        precondition(ThermoregulationModel.isCorrect(.ectotherm, environment: .cool, response: .externalHeat))
        precondition(!ThermoregulationModel.isCorrect(.ectotherm, environment: .cool, response: .conserveHeat))
        print("Thermoregulation model checks passed.")
    }
}
