import Foundation

enum AppLanguage {
    case ru
    case en
}

@main
enum InteractiveChoiceFeedbackVerification {
    static func main() {
        let keys = (1...5).map { "lab.routineExplanation\($0)" }
            + (1...4).map { "lab.animalGroupExplanation\($0)" }
            + (1...4).map { "lab.lineageExplanation\($0)" }
            + [
                "lab.stressHint", "lab.stressProgress",
                "lab.stressQuestion0", "lab.stressQuestion1", "lab.stressQuestion2", "lab.stressQuestion3",
                "lab.stressOption.present.0", "lab.stressOption.present.1",
                "lab.stressOption.record.0", "lab.stressOption.record.1",
                "lab.stressTryAgain",
                "lab.stressFeedback0", "lab.stressFeedback1", "lab.stressFeedback2", "lab.stressFeedback3",
                "lab.stressCheck", "lab.stressNext", "lab.stressFinish", "lab.stressComplete", "lab.stressRestart"
            ]
            + [
                "lab.reportedWrong0.0", "lab.reportedWrong0.2",
                "lab.reportedWrong1.1", "lab.reportedWrong1.2",
                "lab.reportedWrong2.0", "lab.reportedWrong2.1",
                "lab.reportedWrong3.0", "lab.reportedWrong3.2"
            ]

        for key in keys {
            let russian = L10n.text(key, .ru)
            let english = L10n.text(key, .en)
            precondition(
                !russian.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && russian != key
                    && english != key
                    && russian != english,
                "Every interactive answer needs distinct Russian and English feedback. / Для каждого ответа нужны отдельные разборы на русском и английском. Missing or incomplete: \(key)"
            )
        }
    }
}
