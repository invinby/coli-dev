struct NotebookLessonExport {
    let title: String
    let subjectLabel: String
    let isRussian: Bool
    let sourceCheckedOn: String?
    let objective: String
    let theory: String
    let practice: String
    let answer: String
    let checkQuestion: String
    let checkOptions: [String]
    let checkAnswerIndex: Int?
    let limitations: String
    let sources: String

    var markdown: String { "" }
}
