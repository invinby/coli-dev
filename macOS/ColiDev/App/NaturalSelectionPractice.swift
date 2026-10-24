import Foundation

struct NaturalSelectionPopulation: Equatable {
    var traitMean: Double
    var traitSpread: Double
    var generation: Int
}

enum NaturalSelectionTrend: Int, CaseIterable {
    case decrease = 0
    case noChange = 1
    case increase = 2

    var explanationKey: String {
        switch self {
        case .decrease: return "lab.naturalSelection.explanation.decrease"
        case .noChange: return "lab.naturalSelection.explanation.noChange"
        case .increase: return "lab.naturalSelection.explanation.increase"
        }
    }
}

enum NaturalSelectionPractice {
    static func expectedTrend(
        population: NaturalSelectionPopulation,
        environmentOptimum: Double,
        selectionStrength: Double,
        heritability: Double
    ) -> NaturalSelectionTrend {
        guard selectionStrength > 0, heritability > 0 else { return .noChange }

        let difference = environmentOptimum - population.traitMean
        guard abs(difference) > 0.000_001 else { return .noChange }
        return difference > 0 ? .increase : .decrease
    }

    static func advanceGeneration(
        from population: NaturalSelectionPopulation,
        environmentOptimum: Double,
        selectionStrength: Double,
        heritability: Double
    ) -> NaturalSelectionPopulation {
        let strength = min(1, max(0, selectionStrength))
        let inheritance = min(1, max(0, heritability))
        let selectionEffect = strength * inheritance
        let response = (environmentOptimum - population.traitMean) * selectionEffect
        let nextMean = min(100, max(0, population.traitMean + response))
        let nextSpread = selectionEffect > 0
            ? max(6, population.traitSpread * (1 - strength * 0.12))
            : population.traitSpread

        return NaturalSelectionPopulation(
            traitMean: nextMean,
            traitSpread: nextSpread,
            generation: population.generation + 1
        )
    }

    static func makePredictionAttempt(for trend: NaturalSelectionTrend) -> InteractivePredictionAttempt {
        guard let attempt = InteractivePredictionAttempt(
            optionCount: NaturalSelectionTrend.allCases.count,
            answerOriginalIndex: trend.rawValue,
            itemID: "biology.zoology.natural_selection.trait_mean_direction"
        ) else {
            preconditionFailure("Natural selection prediction must have at least one answer option.")
        }
        return attempt
    }
}
