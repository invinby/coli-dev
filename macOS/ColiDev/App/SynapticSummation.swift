import Foundation

/// Summation of excitatory and inhibitory inputs at the axon hillock for the biology synapse lesson.
/// Resting potential and threshold follow OpenStax Biology 2e, section 35.2; the ±4 mV size of one
/// postsynaptic potential is an illustrative value, because real EPSPs and IPSPs vary.
enum SynapticSummationModel {
    static let restingPotential = -70.0
    static let thresholdPotential = -55.0
    static let excitatoryStep = 4.0
    static let inhibitoryStep = 4.0
    static let inputRange = 0...6

    static func clampedInputs(_ count: Int) -> Int {
        min(max(count, inputRange.lowerBound), inputRange.upperBound)
    }

    static func membranePotential(excitatory: Int, inhibitory: Int) -> Double {
        restingPotential
            + Double(clampedInputs(excitatory)) * excitatoryStep
            - Double(clampedInputs(inhibitory)) * inhibitoryStep
    }

    static func reachesThreshold(excitatory: Int, inhibitory: Int) -> Bool {
        membranePotential(excitatory: excitatory, inhibitory: inhibitory) >= thresholdPotential
    }

    /// The smallest number of excitatory inputs that reaches threshold with the given inhibition, if any.
    static func excitatoryInputsNeeded(inhibitory: Int) -> Int? {
        inputRange.first { reachesThreshold(excitatory: $0, inhibitory: inhibitory) }
    }
}
