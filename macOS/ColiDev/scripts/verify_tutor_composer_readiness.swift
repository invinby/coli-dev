@main
enum TutorComposerReadinessVerification {
    static func main() {
        precondition(
            TutorComposerReadiness.resolve(
                backendReady: false,
                routeStatusAvailable: true,
                isLocalOnly: false,
                hasAutomaticRoute: true,
                hasLocalModel: true,
                isLocalEndpointConfirmed: true
            ) == .backendNotReady,
            "A stopped local backend must block tutor sending with an explicit state. / Остановленный backend должен блокировать отправку с явным состоянием."
        )

        precondition(
            TutorComposerReadiness.resolve(
                backendReady: true,
                routeStatusAvailable: false,
                isLocalOnly: false,
                hasAutomaticRoute: false,
                hasLocalModel: false,
                isLocalEndpointConfirmed: true
            ) == .routeStatusUnknown,
            "A running backend without route status must not look ready. / Работающий backend без статуса маршрута нельзя считать готовым."
        )

        precondition(
            TutorComposerReadiness.resolve(
                backendReady: true,
                routeStatusAvailable: true,
                isLocalOnly: false,
                hasAutomaticRoute: false,
                hasLocalModel: false,
                isLocalEndpointConfirmed: true
            ) == .automaticRouteUnavailable,
            "Auto mode without an available route must explain why sending is blocked. / Если в режиме «Авто» нет доступного маршрута, нужно объяснить блокировку отправки."
        )

        precondition(
            TutorComposerReadiness.resolve(
                backendReady: true,
                routeStatusAvailable: true,
                isLocalOnly: true,
                hasAutomaticRoute: true,
                hasLocalModel: false,
                isLocalEndpointConfirmed: true
            ) == .localModelUnavailable,
            "Local-only mode must require an installed local model even when Auto is available. / Режим «Только локально» должен требовать установленную модель, даже если «Авто» доступен."
        )

        let ready = TutorComposerReadiness.resolve(
            backendReady: true,
            routeStatusAvailable: true,
            isLocalOnly: false,
            hasAutomaticRoute: true,
            hasLocalModel: false,
            isLocalEndpointConfirmed: false
        )
        precondition(
            ready == .ready && ready.isReady && ready.messageKey == nil,
            "A ready Auto route must enable sending without an unavailable-state message. / Готовый маршрут «Авто» должен включать отправку без сообщения о недоступности."
        )

        precondition(
            TutorComposerReadiness.resolve(
                backendReady: true,
                routeStatusAvailable: true,
                isLocalOnly: true,
                hasAutomaticRoute: true,
                hasLocalModel: false,
                isLocalEndpointConfirmed: false
            ) == .localEndpointNotLocal,
            "Local-only mode must reject Ollama endpoints outside this Mac. / В локальном режиме Ollama не должен быть доступен по удалённому адресу."
        )

        print("Tutor composer readiness checks passed. / Проверки готовности поля тьютора прошли.")
    }
}
