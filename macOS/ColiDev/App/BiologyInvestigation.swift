import Foundation

enum BiologyStudyFactor: String, CaseIterable, Equatable, Hashable {
    case lightExposure
    case waterAmount
    case plantType
}

enum BiologyStudyOutcome: String, CaseIterable, Equatable, Hashable {
    case heightChange
    case leafCount
    case soilMoisture
}

enum BiologyStudyControl: String, CaseIterable, Equatable, Hashable {
    case waterAmount
    case seedType
    case potAndSoil
    case temperatureAndDuration
}

enum BiologyStudyIssue: String, CaseIterable, Equatable, Hashable {
    case changeFactor
    case measuredOutcome
    case waterAmount
    case seedType
    case potAndSoil
    case temperatureAndDuration
    case replication
}

struct BiologyExperimentDesign: Equatable {
    var factorToChange: BiologyStudyFactor = .lightExposure
    var outcomeToMeasure: BiologyStudyOutcome = .heightChange
    var controls: Set<BiologyStudyControl> = Set(BiologyStudyControl.allCases)
    var plantsPerGroup = 3

    var issues: [BiologyStudyIssue] {
        var result: [BiologyStudyIssue] = []
        if factorToChange != .lightExposure { result.append(.changeFactor) }
        if outcomeToMeasure != .heightChange { result.append(.measuredOutcome) }
        if !controls.contains(.waterAmount) { result.append(.waterAmount) }
        if !controls.contains(.seedType) { result.append(.seedType) }
        if !controls.contains(.potAndSoil) { result.append(.potAndSoil) }
        if !controls.contains(.temperatureAndDuration) { result.append(.temperatureAndDuration) }
        if plantsPerGroup < 3 { result.append(.replication) }
        return result
    }

    var isReadyToCollectData: Bool { issues.isEmpty }
}
