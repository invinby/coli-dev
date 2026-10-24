import Foundation

@main
enum NeuronSignalVerification {
    static func main() {
        precondition(NeuronSignalModel.restingPotential == -70)
        precondition(NeuronSignalModel.thresholdPotential == -55)
        precondition(NeuronSignalModel.peakPotential == 40)
        precondition(NeuronSignalModel.undershootPotential < NeuronSignalModel.restingPotential)

        precondition(NeuronSignalModel.membranePotential(afterDepolarization: 10) == -60)
        precondition(!NeuronSignalModel.firesActionPotential(afterDepolarization: 10), "-60 mV stays below threshold")
        precondition(!NeuronSignalModel.firesActionPotential(afterDepolarization: 14))
        precondition(NeuronSignalModel.firesActionPotential(afterDepolarization: 15), "-55 mV reaches threshold")
        precondition(NeuronSignalModel.firesActionPotential(afterDepolarization: 30))

        // All-or-none: every stimulus that reaches threshold gives the same peak.
        precondition(NeuronSignalModel.highestPotential(afterDepolarization: 15) == NeuronSignalModel.peakPotential)
        precondition(NeuronSignalModel.highestPotential(afterDepolarization: 30) == NeuronSignalModel.peakPotential)
        precondition(NeuronSignalModel.highestPotential(afterDepolarization: 10) == -60)

        precondition(NeuronSignalModel.membranePotential(afterDepolarization: -5) == -70, "stimulus is clamped at 0")
        precondition(NeuronSignalModel.membranePotential(afterDepolarization: 99) == -40, "stimulus is clamped at 30")

        for depolarization in stride(from: 0.0, through: 30.0, by: 1.0) {
            let trace = NeuronSignalModel.trace(afterDepolarization: depolarization)
            precondition(trace.first?.millivolts == NeuronSignalModel.restingPotential)
            precondition(trace.last?.millivolts == NeuronSignalModel.restingPotential)
            precondition(zip(trace, trace.dropFirst()).allSatisfy { $0.0.milliseconds < $0.1.milliseconds }, "time increases")
            let highest = trace.map { $0.millivolts }.max() ?? NeuronSignalModel.restingPotential
            if NeuronSignalModel.firesActionPotential(afterDepolarization: depolarization) {
                precondition(highest == NeuronSignalModel.peakPotential)
                precondition(trace.contains { $0.millivolts < NeuronSignalModel.restingPotential }, "undershoot follows the spike")
            } else {
                precondition(highest < NeuronSignalModel.thresholdPotential)
                precondition(!trace.contains { $0.millivolts < NeuronSignalModel.restingPotential })
            }
        }
        print("Neuron signal model checks passed.")
    }
}
