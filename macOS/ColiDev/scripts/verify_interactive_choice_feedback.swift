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
