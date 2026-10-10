import Foundation

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

    var markdown: String {
        let goalHeading = isRussian ? "Цель" : "Learning goal"
        let theoryHeading = isRussian ? "Теория и механизм" : "Theory and mechanism"
        let practiceHeading = isRussian ? "Практика" : "Practice"
        let checkHeading = isRussian ? "Проверка понимания" : "Knowledge check"
        let answerHeading = isRussian ? "Правильный ответ и разбор" : "Correct answer and explanation"
        let limitsHeading = isRussian ? "Ограничения" : "Limitations"
        let sourcesHeading = isRussian ? "Источники" : "Sources"
        let origin = isRussian ? "Экспортировано из ColiDev" : "Exported from ColiDev"

        var sections = [
            "# \(title)",
            "**\(isRussian ? "Предмет" : "Subject"): \(subjectLabel)**",
            "*\(origin)*",
        ]
        if let sourceReviewLine {
            sections.append(sourceReviewLine)
        }
        sections.append("## \(goalHeading)\n\(objective)")
        sections.append("## \(theoryHeading)\n\(theory)")

        if !practice.isEmpty {
            sections.append("## \(practiceHeading)\n\(practice)")
        }
        if !checkQuestion.isEmpty {
            var check = "## \(checkHeading)\n\(checkQuestion)"
            for (index, option) in checkOptions.enumerated() {
                check += "\n\n\(index + 1). \(option)"
            }
            sections.append(check)
        }
        if let checkAnswerIndex {
            let answerLabel = isRussian ? "Правильный вариант" : "Correct option"
            sections.append("## \(answerHeading)\n\(answerLabel): \(checkAnswerIndex + 1).\n\n\(answer)")
        } else if !answer.isEmpty {
            sections.append("## \(answerHeading)\n\(answer)")
        }
        if !limitations.isEmpty {
            sections.append("## \(limitsHeading)\n\(limitations)")
        }
        if !sources.isEmpty {
            sections.append("## \(sourcesHeading)\n\(sources)")
        }
        return sections.joined(separator: "\n\n") + "\n"
    }

    private var sourceReviewLine: String? {
        guard let date = sourceCheckedOn?.trimmingCharacters(in: .whitespacesAndNewlines),
              date.range(of: "^\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression) != nil else {
            return nil
        }
        let label = isRussian
            ? "Дата редакторской проверки источников урока"
            : "Sources in this lesson last editorially reviewed"
        return "**\(label):** \(date)"
    }
}
