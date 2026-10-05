import Foundation

struct CurriculumText {
    let russian: String
    let english: String

    func value(in language: AppLanguage) -> String {
        language == .ru ? russian : english
    }
}

struct CurriculumTopic: Identifiable {
    let name: CurriculumText
    let learningOutcome: CurriculumText
    let lessonResource: String?

    var id: String { "\(name.russian)|\(name.english)" }
}

struct CurriculumLevel: Identifiable {
    let title: CurriculumText
    let topics: [CurriculumTopic]

    var id: String { title.english }
}

enum CurriculumCatalog {
    static func roadmap(for subject: Subject) -> [CurriculumLevel] {
        guard
            let resourcesURL = Bundle.main.resourceURL,
            let markdown = try? String(contentsOf: resourcesURL
                .appendingPathComponent("02_Areas", isDirectory: true)
                .appendingPathComponent(subject.rawValue.capitalized, isDirectory: true)
                .appendingPathComponent("curriculum.md"), encoding: .utf8)
        else {
            return []
        }
        return parse(markdown)
    }

    static func lessonMarkdown(for subject: Subject, resource: String) -> String? {
        guard resource.range(of: "^[a-z0-9_-]{1,80}$", options: .regularExpression) != nil,
              let resourcesURL = Bundle.main.resourceURL else { return nil }
        let lessonURL = resourcesURL
            .appendingPathComponent("02_Areas", isDirectory: true)
            .appendingPathComponent(subject.rawValue.capitalized, isDirectory: true)
            .appendingPathComponent("lessons", isDirectory: true)
            .appendingPathComponent(resource)
            .appendingPathExtension("md")
        return try? String(contentsOf: lessonURL, encoding: .utf8)
    }

    private static func parse(_ markdown: String) -> [CurriculumLevel] {
        var levels: [(title: CurriculumText, topics: [CurriculumTopic])] = []
        var activeLevelIndex: Int?

        for rawLine in markdown.split(whereSeparator: \.isNewline) {
            let line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("## ") {
                let title = localized(String(line.dropFirst(3)))
                let levelName = title.english.lowercased()
                guard ["foundations", "intermediate", "advanced"].contains(levelName) else {
                    activeLevelIndex = nil
                    continue
                }
                levels.append((title, []))
                activeLevelIndex = levels.count - 1
                continue
            }
            guard line.hasPrefix("|"), let activeLevelIndex else { continue }
            let columns = line.split(separator: "|").map {
                String($0).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard columns.count >= 2 else { continue }
            if columns[0].contains("Модуль") || columns[0].contains("Module") || columns[0].allSatisfy({ $0 == "-" || $0 == ":" }) {
                continue
            }
            levels[activeLevelIndex].topics.append(
                CurriculumTopic(
                    name: localized(columns[0]),
                    learningOutcome: localized(columns[1]),
                    lessonResource: columns.count >= 3 && columns[2].hasPrefix("lesson:")
                        ? String(columns[2].dropFirst("lesson:".count))
                        : nil
                )
            )
        }
        return levels.map { CurriculumLevel(title: $0.title, topics: $0.topics) }
    }

    private static func localized(_ value: String) -> CurriculumText {
        guard let separator = value.range(of: " / ") else {
            return CurriculumText(russian: value, english: value)
        }
        return CurriculumText(
            russian: String(value[..<separator.lowerBound]),
            english: String(value[separator.upperBound...])
        )
    }
}
