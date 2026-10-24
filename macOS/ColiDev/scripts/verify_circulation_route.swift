import Foundation

@main
enum CirculationRouteVerification {
    static func main() {
        precondition(CirculationAnimal.allCases == [.fish, .amphibian, .mammal])
        precondition(CirculationRouteModel.passOptions == [1, 2, 3])

        precondition(CirculationRouteModel.heartPassesPerFullRoute(for: .fish) == 1, "fish have a single circuit")
        precondition(CirculationRouteModel.heartPassesPerFullRoute(for: .amphibian) == 2, "amphibians have double circulation")
        precondition(CirculationRouteModel.heartPassesPerFullRoute(for: .mammal) == 2, "mammals have pulmonary and systemic circuits")

        precondition(CirculationRouteModel.heartChambers(for: .fish) == HeartChambers(atria: 1, ventricles: 1))
        precondition(CirculationRouteModel.heartChambers(for: .amphibian) == HeartChambers(atria: 2, ventricles: 1))
        precondition(CirculationRouteModel.heartChambers(for: .mammal) == HeartChambers(atria: 2, ventricles: 2))

        precondition(!CirculationRouteModel.flowsMixInVentricle(.fish), "a single circuit carries oxygen-poor blood through the heart")
        precondition(CirculationRouteModel.flowsMixInVentricle(.amphibian), "one ventricle serves both circuits")
        precondition(!CirculationRouteModel.flowsMixInVentricle(.mammal), "four chambers keep the circuits separate")

        for animal in CirculationAnimal.allCases {
            let correct = CirculationRouteModel.passOptions.filter { CirculationRouteModel.isCorrect(passes: $0, for: animal) }
            precondition(correct == [CirculationRouteModel.heartPassesPerFullRoute(for: animal)], "exactly one option is correct for \(animal)")
        }
        print("Circulation route model checks passed.")
    }
}
