import Foundation

@main
enum TutorRouteProbeStateVerification {
    static func main() {
        precondition(!TutorRouteProbeState.idle.hasVerifiedModelResponse)
        precondition(!TutorRouteProbeState.checking.hasVerifiedModelResponse)
        precondition(!TutorRouteProbeState.failed("No response").hasVerifiedModelResponse)
        precondition(
            TutorRouteProbeState.verifiedResponse(
                provider: "Ollama",
                model: "qwen3",
                answer: " \n\t ",
                durationMS: 20
            ) == nil,
            "An empty completion must never count as a verified model response. / Пустой ответ не должен считаться проверенным ответом модели."
        )

        let response = TutorRouteProbeState.verifiedResponse(
            provider: "Ollama",
            model: "qwen3",
            answer: "  Tutor connection works.  ",
            durationMS: 120
        )
        precondition(
            response == .succeeded(
                provider: "Ollama",
                model: "qwen3",
                answer: "Tutor connection works.",
                durationMS: 120
            ) && response?.hasVerifiedModelResponse == true,
            "Only a non-empty model reply can produce a verified state. / Статус проверки должен появляться только после непустого ответа модели."
        )

        let longResponse = TutorRouteProbeState.verifiedResponse(
            provider: "Ollama",
            model: "qwen3",
            answer: String(repeating: "a", count: 400),
            durationMS: -1
        )
        if case .succeeded(_, _, let answer, let durationMS)? = longResponse {
            precondition(answer.count == 300 && durationMS == 0)
        } else {
            preconditionFailure("A non-empty model reply should be accepted. / Непустой ответ модели должен приниматься.")
        }

        print("Tutor route probe state checks passed. / Проверки статуса реального ответа тьютора прошли.")
    }
}
