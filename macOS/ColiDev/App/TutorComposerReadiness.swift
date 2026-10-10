enum TutorComposerReadiness: Equatable {
    case backendNotReady
    case routeStatusUnknown
    case automaticRouteUnavailable
    case localModelUnavailable
    case localEndpointNotLocal
    case ready

    var isReady: Bool { self == .ready }

    var messageKey: String? {
        switch self {
        case .backendNotReady: return "tutor.routeBackendNotReady"
        case .routeStatusUnknown: return "tutor.routeStatusUnknown"
        case .automaticRouteUnavailable: return "tutor.autoRouteUnavailable"
        case .localModelUnavailable: return "tutor.localUnavailable"
        case .localEndpointNotLocal: return "tutor.localEndpointBlocked"
        case .ready: return nil
        }
    }

    static func resolve(
        backendReady: Bool,
        routeStatusAvailable: Bool,
        isLocalOnly: Bool,
        hasAutomaticRoute: Bool,
        hasLocalModel: Bool,
        isLocalEndpointConfirmed: Bool
    ) -> TutorComposerReadiness {
        guard backendReady else { return .backendNotReady }
        guard routeStatusAvailable else { return .routeStatusUnknown }

        if isLocalOnly {
            guard isLocalEndpointConfirmed else { return .localEndpointNotLocal }
            guard hasLocalModel else { return .localModelUnavailable }
            return .ready
        }

        guard hasAutomaticRoute else { return .automaticRouteUnavailable }
        return .ready
    }
}
