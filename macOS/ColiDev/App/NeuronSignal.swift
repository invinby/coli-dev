import Foundation

struct MembraneTracePoint: Equatable {
    let milliseconds: Double
    let millivolts: Double
}

/// A simplified all-or-none action potential for the biology neuron lesson.
/// Resting potential, threshold, and peak follow the typical values in OpenStax Biology 2e, section 35.2;
/// real neurons vary by type and species, and the time axis and undershoot depth here are illustrative.
enum NeuronSignalModel {
    static let restingPotential = -70.0
    static let thresholdPotential = -55.0
    static let peakPotential = 40.0
    static let undershootPotential = -75.0
    static let stimulusRange: ClosedRange<Double> = 0...30

    static func membranePotential(afterDepolarization depolarization: Double) -> Double {
        restingPotential + min(max(depolarization, stimulusRange.lowerBound), stimulusRange.upperBound)
    }

    static func firesActionPotential(afterDepolarization depolarization: Double) -> Bool {
        membranePotential(afterDepolarization: depolarization) >= thresholdPotential
    }

    static func highestPotential(afterDepolarization depolarization: Double) -> Double {
        firesActionPotential(afterDepolarization: depolarization)
            ? peakPotential
            : membranePotential(afterDepolarization: depolarization)
    }

    static func trace(afterDepolarization depolarization: Double) -> [MembraneTracePoint] {
        var points = [
            MembraneTracePoint(milliseconds: 0, millivolts: restingPotential),
            MembraneTracePoint(milliseconds: 1, millivolts: restingPotential),
            MembraneTracePoint(milliseconds: 1.5, millivolts: membranePotential(afterDepolarization: depolarization))
        ]
        if firesActionPotential(afterDepolarization: depolarization) {
            points += [
                MembraneTracePoint(milliseconds: 2.5, millivolts: peakPotential),
                MembraneTracePoint(milliseconds: 3.5, millivolts: restingPotential),
                MembraneTracePoint(milliseconds: 4.5, millivolts: undershootPotential),
                MembraneTracePoint(milliseconds: 6.5, millivolts: restingPotential)
            ]
        } else {
            points.append(MembraneTracePoint(milliseconds: 4, millivolts: restingPotential))
        }
        points.append(MembraneTracePoint(milliseconds: 8, millivolts: restingPotential))
        return points
    }
}
