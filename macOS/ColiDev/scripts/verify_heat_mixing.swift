import Foundation

@main
enum HeatMixingVerification {
    static func main() {
        expect(HeatMixingModel.waterSpecificHeat, equals: 4186, tolerance: 0, "specific heat of water")
        expect(HeatMixingModel.finalTemperature(coldMass: 1, coldTemperature: 20, hotMass: 1, hotTemperature: 80), equals: 50, tolerance: 1e-12, "equal masses meet halfway")
        expect(HeatMixingModel.finalTemperature(coldMass: 2, coldTemperature: 20, hotMass: 1, hotTemperature: 80), equals: 40, tolerance: 1e-12, "more cold water pulls the result down")
        expect(HeatMixingModel.finalTemperature(coldMass: 1, coldTemperature: 30, hotMass: 1, hotTemperature: 30), equals: 30, tolerance: 0, "equal temperatures stay put")

        for (coldMass, cold, hotMass, hot) in [(1.0, 20.0, 1.0, 80.0), (2.0, 20.0, 1.0, 80.0), (0.5, 5.0, 3.0, 95.0)] {
            let final = HeatMixingModel.finalTemperature(coldMass: coldMass, coldTemperature: cold, hotMass: hotMass, hotTemperature: hot)
            precondition(final >= cold && final <= hot, "the mixture lies between the two starting temperatures")
            let gained = HeatMixingModel.heat(mass: coldMass, from: cold, to: final)
            let lost = HeatMixingModel.heat(mass: hotMass, from: hot, to: final)
            expect(gained + lost, equals: 0, tolerance: 1e-6, "heat lost by the hot water equals heat gained by the cold water")
        }

        expect(HeatMixingModel.heat(mass: 1, from: 20, to: 50), equals: 125_580, tolerance: 1e-6, "Q = mcΔT for 1 kg warmed by 30 °C")
        print("Heat mixing model checks passed.")
    }

    private static func expect(_ actual: Double, equals expected: Double, tolerance: Double, _ name: String) {
        precondition(actual.isFinite && abs(actual - expected) <= tolerance, "\(name): expected \(expected), got \(actual)")
    }
}
