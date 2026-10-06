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

enum PondFoodWebNodeKind: String, Equatable {
    case producer
    case consumer
    case decomposer
    case matter
}

struct PondFoodWebNode: Identifiable, Equatable {
    let id: String
    let x: CGFloat
    let y: CGFloat
    let kind: PondFoodWebNodeKind
}

enum PondFoodWebLinkKind: String, Equatable {
    case feeding
    case matterCycle
}

struct PondFoodWebLink: Identifiable, Equatable {
    let from: String
    let to: String
    let kind: PondFoodWebLinkKind

    var id: String { "\(from)_\(to)" }
}

enum PondFoodWebModel {
    static let nodes: [PondFoodWebNode] = [
        .init(id: "algae", x: 0.10, y: 0.17, kind: .producer),
        .init(id: "zooplankton", x: 0.39, y: 0.12, kind: .consumer),
        .init(id: "snails", x: 0.39, y: 0.39, kind: .consumer),
        .init(id: "smallFish", x: 0.67, y: 0.27, kind: .consumer),
        .init(id: "heron", x: 0.91, y: 0.15, kind: .consumer),
        .init(id: "detritus", x: 0.10, y: 0.76, kind: .matter),
        .init(id: "decomposers", x: 0.42, y: 0.77, kind: .decomposer),
        .init(id: "nutrients", x: 0.10, y: 0.49, kind: .matter)
    ]

    static let links: [PondFoodWebLink] = [
        .init(from: "algae", to: "zooplankton", kind: .feeding),
        .init(from: "algae", to: "snails", kind: .feeding),
        .init(from: "zooplankton", to: "smallFish", kind: .feeding),
        .init(from: "snails", to: "smallFish", kind: .feeding),
        .init(from: "smallFish", to: "heron", kind: .feeding),
        .init(from: "algae", to: "detritus", kind: .feeding),
        .init(from: "snails", to: "detritus", kind: .feeding),
        .init(from: "smallFish", to: "detritus", kind: .feeding),
        .init(from: "heron", to: "detritus", kind: .feeding),
        .init(from: "detritus", to: "decomposers", kind: .feeding),
        .init(from: "decomposers", to: "nutrients", kind: .matterCycle),
        .init(from: "nutrients", to: "algae", kind: .matterCycle)
    ]

    static func visibleLinks(excluding nodeID: String) -> [PondFoodWebLink] {
        guard nodeID != "none" else { return links }
        return links.filter { $0.from != nodeID && $0.to != nodeID }
    }

    static func incomingLinks(to nodeID: String, excluding removedNodeID: String) -> [PondFoodWebLink] {
        visibleLinks(excluding: removedNodeID).filter { $0.to == nodeID }
    }

    static func outgoingLinks(from nodeID: String, excluding removedNodeID: String) -> [PondFoodWebLink] {
        visibleLinks(excluding: removedNodeID).filter { $0.from == nodeID }
    }

    static func directConsumers(of nodeID: String) -> [String] {
        links.compactMap { link in
            guard link.from == nodeID,
                  nodes.first(where: { $0.id == link.to })?.kind == .consumer else { return nil }
            return link.to
        }
    }
}
