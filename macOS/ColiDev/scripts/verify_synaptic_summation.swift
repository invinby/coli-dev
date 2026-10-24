import Foundation

@main
enum SynapticSummationVerification {
    static func main() {
        precondition(SynapticSummationModel.restingPotential == -70)
        precondition(SynapticSummationModel.thresholdPotential == -55)

        precondition(SynapticSummationModel.membranePotential(excitatory: 0, inhibitory: 0) == -70)
        precondition(SynapticSummationModel.membranePotential(excitatory: 5, inhibitory: 2) == -58, "lesson question: 5 excitatory and 2 inhibitory inputs")
        precondition(!SynapticSummationModel.reachesThreshold(excitatory: 5, inhibitory: 2), "-58 mV stays below threshold")
        precondition(SynapticSummationModel.membranePotential(excitatory: 4, inhibitory: 0) == -54)
        precondition(SynapticSummationModel.reachesThreshold(excitatory: 4, inhibitory: 0), "four excitatory inputs reach threshold")
        precondition(!SynapticSummationModel.reachesThreshold(excitatory: 3, inhibitory: 0), "three excitatory inputs fall short")
        precondition(SynapticSummationModel.reachesThreshold(excitatory: 6, inhibitory: 2), "the net change decides, not the number of inputs alone")
        precondition(!SynapticSummationModel.reachesThreshold(excitatory: 6, inhibitory: 3), "inhibition can cancel excitation")

        precondition(SynapticSummationModel.excitatoryInputsNeeded(inhibitory: 0) == 4)
        precondition(SynapticSummationModel.excitatoryInputsNeeded(inhibitory: 2) == 6)
        precondition(SynapticSummationModel.excitatoryInputsNeeded(inhibitory: 3) == nil, "six inputs cannot outweigh three inhibitory ones")

        precondition(SynapticSummationModel.membranePotential(excitatory: 99, inhibitory: -5) == -46, "inputs are clamped to 0...6")
        for excitatory in SynapticSummationModel.inputRange {
            for inhibitory in SynapticSummationModel.inputRange {
                let fires = SynapticSummationModel.reachesThreshold(excitatory: excitatory, inhibitory: inhibitory)
                precondition(fires == (excitatory - inhibitory >= 4), "threshold rule for \(excitatory)/\(inhibitory)")
            }
        }
        print("Synaptic summation model checks passed.")
    }
}
