import Foundation

enum AppLanguage {
    case ru
    case en
}

@main
enum IntroLessonCopyVerification {
    static func localizedAnswer(_ lesson: String, language: AppLanguage) -> String {
        let answerIndex = Int(L10n.text("lesson.\(lesson).answer", language))!
        return L10n.text("lesson.\(lesson).option\(answerIndex)", language)
    }

    static func main() {
        let mathQuestionRU = L10n.text("lesson.mathematics.question", .ru)
        let mathQuestionEN = L10n.text("lesson.mathematics.question", .en)
        precondition(
            mathQuestionRU.contains("x увеличится на 1")
                && mathQuestionEN.contains("x increases by 1")
                && localizedAnswer("mathematics", language: .ru).contains("2")
                && localizedAnswer("mathematics", language: .en).contains("2"),
            "The math introduction must check slope as a rate of change in both languages. / Вводный урок математики должен проверять наклон как скорость изменения на обоих языках."
        )

        let physicsQuestionRU = L10n.text("lesson.physics.question", .ru)
        let physicsQuestionEN = L10n.text("lesson.physics.question", .en)
        precondition(
            physicsQuestionRU.localizedCaseInsensitiveContains("равнодействующая")
                && physicsQuestionEN.localizedCaseInsensitiveContains("net force")
                && localizedAnswer("physics", language: .ru).contains("4")
                && localizedAnswer("physics", language: .en).contains("4"),
            "The physics question must identify the net force before applying F = ma. / В задаче по физике нужно назвать равнодействующую до применения F = ma."
        )

        let biologyQuestionRU = L10n.text("lesson.biology.question", .ru)
        let biologyQuestionEN = L10n.text("lesson.biology.question", .en)
        precondition(
            biologyQuestionRU.localizedCaseInsensitiveContains("аэробного")
                && biologyQuestionRU.localizedCaseInsensitiveContains("эукариот")
                && biologyQuestionEN.localizedCaseInsensitiveContains("aerobic")
                && biologyQuestionEN.localizedCaseInsensitiveContains("eukaryotes")
                && localizedAnswer("biology", language: .ru).localizedCaseInsensitiveContains("митохондри")
                && localizedAnswer("biology", language: .en).localizedCaseInsensitiveContains("mitochondrion"),
            "The biology question must narrow the mitochondrial role to aerobic respiration in eukaryotes. / Вопрос по биологии должен ограничивать роль митохондрий аэробным дыханием у эукариот."
        )

        let zoologyLimitationsRU = L10n.text("lesson.zoology.limitations", .ru)
        let zoologyLimitationsEN = L10n.text("lesson.zoology.limitations", .en)
        precondition(
            zoologyLimitationsRU.localizedCaseInsensitiveContains("Некоторые признаки")
                && zoologyLimitationsEN.localizedCaseInsensitiveContains("Some traits"),
            "The adaptation caveat must qualify the trade-off claim in both languages. / Оговорка об адаптации должна смягчать утверждение о компромиссах на обоих языках."
        )

        print("Intro lesson bilingual checks passed. / Двуязычные проверки вводных уроков прошли.")
    }
}
