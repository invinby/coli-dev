import Foundation

/// Mixing two portions of water in an insulated container, following OpenStax College Physics 2e,
/// section 14.2: Q = mcΔT, and the heat lost by the hot water equals the heat gained by the cold water.
enum HeatMixingModel {
    /// Specific heat of water in J/(kg·°C) from OpenStax College Physics 2e, Table 14.1.
    static let waterSpecificHeat = 4186.0
    static let massRange: ClosedRange<Double> = 0.5...3.0
    static let temperatureRange: ClosedRange<Double> = 0...100

    static func finalTemperature(coldMass: Double, coldTemperature: Double, hotMass: Double, hotTemperature: Double) -> Double {
        let totalMass = coldMass + hotMass
        guard totalMass > 0 else { return coldTemperature }
        return (coldMass * coldTemperature + hotMass * hotTemperature) / totalMass
    }

    /// Q = mcΔT in joules; positive when the water warms, negative when it cools.
    static func heat(mass: Double, from start: Double, to end: Double) -> Double {
        mass * waterSpecificHeat * (end - start)
    }
}
