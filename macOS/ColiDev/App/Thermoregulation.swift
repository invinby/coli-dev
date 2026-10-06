import Foundation

enum ThermalAnimalMode: String, CaseIterable, Identifiable {
    case ectotherm
    case endotherm

    var id: String { rawValue }
    var titleKey: String { "lab.zoology.thermal.mode.\(rawValue)" }
    var heatSourceKey: String { "lab.zoology.thermal.source.\(rawValue)" }
}

enum ThermalEnvironment: String, CaseIterable, Identifiable {
    case cool
    case mild
    case hot

    var id: String { rawValue }
    var titleKey: String { "lab.zoology.thermal.environment.\(rawValue)" }
}

enum ThermoregulatoryResponse: String, CaseIterable, Identifiable {
    case externalHeat
    case coolerMicrohabitat
    case conserveHeat
    case dissipateHeat
    case observe

    var id: String { rawValue }
    var titleKey: String { "lab.zoology.thermal.response.\(rawValue)" }
    var explanationKey: String { "lab.zoology.thermal.effect.\(rawValue)" }
}

enum ThermoregulationModel {
    static func recommendedResponse(
        for animal: ThermalAnimalMode,
        in environment: ThermalEnvironment
    ) -> ThermoregulatoryResponse {
        switch (animal, environment) {
        case (.ectotherm, .cool): .externalHeat
        case (.ectotherm, .mild), (.endotherm, .mild): .observe
        case (.ectotherm, .hot): .coolerMicrohabitat
        case (.endotherm, .cool): .conserveHeat
        case (.endotherm, .hot): .dissipateHeat
        }
    }

    static func isCorrect(
        _ animal: ThermalAnimalMode,
        environment: ThermalEnvironment,
        response: ThermoregulatoryResponse
    ) -> Bool {
        response == recommendedResponse(for: animal, in: environment)
    }
}
