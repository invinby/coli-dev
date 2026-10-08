enum TutorComposerReadiness: Equatable {
    case backendNotReady
    case routeStatusUnknown
    case automaticRouteUnavailable
    case localModelUnavailable
    case ready

    var isReady: Bool { self == .ready }

    var messageKey: String? {
        switch self {
        case .backendNotReady: return "tutor.routeBackendNotReady"
        case .routeStatusUnknown: return "tutor.routeStatusUnknown"
        case .automaticRouteUnavailable: return "tutor.autoRouteUnavailable"
        case .localModelUnavailable: return "tutor.localUnavailable"
        case .ready: return nil
        }
    }

    static func resolve(
        backendReady: Bool,
        routeStatusAvailable: Bool,
        isLocalOnly: Bool,
        hasAutomaticRoute: Bool,
        hasLocalModel: Bool
    ) -> TutorComposerReadiness {
        .ready
    }
}
