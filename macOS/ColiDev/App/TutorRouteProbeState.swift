import Foundation

enum TutorRouteProbeState: Equatable {
    case idle
    case checking
    case succeeded(provider: String, model: String, answer: String, durationMS: Int)
    case failed(String)

    var hasVerifiedModelResponse: Bool {
        guard case .succeeded(_, _, let answer, _) = self else { return false }
        return !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func verifiedResponse(
        provider: String,
        model: String,
        answer: String,
        durationMS: Int
    ) -> TutorRouteProbeState? {
        let cleanedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedAnswer.isEmpty else { return nil }
        return .succeeded(
            provider: provider,
            model: model,
            answer: String(cleanedAnswer.prefix(300)),
            durationMS: max(0, durationMS)
        )
    }
}
