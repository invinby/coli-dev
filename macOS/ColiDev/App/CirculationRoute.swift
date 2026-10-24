import Foundation

enum CirculationAnimal: String, CaseIterable, Identifiable {
    case fish
    case amphibian
    case mammal

    var id: String { rawValue }
    var titleKey: String { "lab.circulation.animal.\(rawValue)" }
    var routeKey: String { "lab.circulation.route.\(rawValue)" }
    var heartKey: String { "lab.circulation.heart.\(rawValue)" }
    var exchangeKey: String { "lab.circulation.exchange.\(rawValue)" }
    var explanationKey: String { "lab.circulation.explain.\(rawValue)" }
}

struct HeartChambers: Equatable {
    let atria: Int
    let ventricles: Int
}

/// Typical vertebrate circulation patterns from OpenStax Biology 2e, section 40.1; individual species vary.
enum CirculationRouteModel {
    static let passOptions = [1, 2, 3]

    static func heartPassesPerFullRoute(for animal: CirculationAnimal) -> Int {
        switch animal {
        case .fish: 1
        case .amphibian, .mammal: 2
        }
    }

    static func heartChambers(for animal: CirculationAnimal) -> HeartChambers {
        switch animal {
        case .fish: HeartChambers(atria: 1, ventricles: 1)
        case .amphibian: HeartChambers(atria: 2, ventricles: 1)
        case .mammal: HeartChambers(atria: 2, ventricles: 2)
        }
    }

    /// Oxygen-rich and oxygen-poor blood partly mix only where one ventricle serves both circuits.
    static func flowsMixInVentricle(_ animal: CirculationAnimal) -> Bool {
        heartPassesPerFullRoute(for: animal) == 2 && heartChambers(for: animal).ventricles == 1
    }

    static func isCorrect(passes: Int, for animal: CirculationAnimal) -> Bool {
        passes == heartPassesPerFullRoute(for: animal)
    }
}
