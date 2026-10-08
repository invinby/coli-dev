import Foundation

@main
enum NotebookLessonExportVerification {
    static func main() {
        let english = NotebookLessonExport(
            title: "Cell cycle",
            subjectLabel: "Biology",
            isRussian: false,
            sourceCheckedOn: "2026-10-08",
            objective: "Trace DNA replication.",
            theory: "DNA is copied during S phase.",
            practice: "Follow the stages.",
            answer: "DNA synthesis occurs during S phase.",
            checkQuestion: "When is DNA copied?",
            checkOptions: ["During S phase"],
            checkAnswerIndex: 0,
            limitations: "This is a simplified model.",
            sources: "- OpenStax Biology 2e"
        ).markdown

        precondition(
            english.contains("**Sources in this lesson last editorially reviewed:** 2026-10-08"),
            "English NotebookLM exports must include the lesson's editorial source-review date. / В экспорт NotebookLM на английском должна попадать дата редакторской проверки источников урока."
        )
        precondition(
            english.range(of: "Sources in this lesson last editorially reviewed")!.lowerBound
                < english.range(of: "## Sources")!.lowerBound,
            "The review date must appear before the source list. / Дата проверки должна стоять перед списком источников."
        )
        precondition(
            english.contains("- OpenStax Biology 2e"),
            "NotebookLM export must preserve the lesson's citations. / Экспорт NotebookLM должен сохранять ссылки урока."
        )

        let russian = NotebookLessonExport(
            title: "Клеточный цикл",
            subjectLabel: "Биология",
            isRussian: true,
            sourceCheckedOn: "2026-10-08",
            objective: "Проследить копирование ДНК.",
            theory: "ДНК копируется в S-фазе.",
            practice: "Проследить стадии.",
            answer: "Синтез ДНК происходит в S-фазе.",
            checkQuestion: "Когда копируется ДНК?",
            checkOptions: ["В S-фазе"],
            checkAnswerIndex: 0,
            limitations: "Это упрощённая модель.",
            sources: "- OpenStax Biology 2e"
        ).markdown

        precondition(
            russian.contains("**Дата редакторской проверки источников урока:** 2026-10-08"),
            "Russian NotebookLM exports must include the lesson's editorial source-review date. / В экспорт NotebookLM на русском должна попадать дата редакторской проверки источников урока."
        )

        let undated = NotebookLessonExport(
            title: "Topic",
            subjectLabel: "Mathematics",
            isRussian: false,
            sourceCheckedOn: nil,
            objective: "Understand the topic.",
            theory: "",
            practice: "",
            answer: "",
            checkQuestion: "",
            checkOptions: [],
            checkAnswerIndex: nil,
            limitations: "",
            sources: ""
        ).markdown
        precondition(
            !undated.contains("editorially reviewed"),
            "An unknown review date must not be invented. / Нельзя выдумывать отсутствующую дату проверки."
        )

        print("NotebookLM lesson export provenance checks passed. / Проверки источников и даты в экспорте NotebookLM прошли.")
    }
}
