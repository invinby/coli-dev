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

struct CurriculumLevelCoverage: Identifiable {
    let level: CurriculumText
    let topicCount: Int
    let linkedLessonCount: Int

    var id: String { level.english }
}

struct CurriculumLessonStructureIssue: Identifiable {
    let resource: String
    let missingRussianSections: [String]
    let missingEnglishSections: [String]
    let missingSources: Bool

    var id: String { resource }
}

struct SubjectCurriculumCoverage: Identifiable {
    let subject: Subject
    let levels: [CurriculumLevelCoverage]
    let bundledLessonCount: Int
    let bilingualLessonCount: Int
    let sourceCitedLessonCount: Int
    let structurallyCompleteLessonCount: Int
    let lessonStructureIssues: [CurriculumLessonStructureIssue]

    var topicCount: Int { levels.reduce(0) { $0 + $1.topicCount } }
    var linkedLessonCount: Int { levels.reduce(0) { $0 + $1.linkedLessonCount } }
    var id: String { subject.rawValue }
}

enum CurriculumCatalog {
    static func coverage(for subject: Subject) -> SubjectCurriculumCoverage {
        let levels = roadmap(for: subject)
        let lessonFiles = lessonFiles(for: subject)
        let lessonContents = lessonFiles.compactMap { url -> (String, String)? in
            guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return (url.deletingPathExtension().lastPathComponent, contents)
        }
        let lessonAudits = lessonContents.map { resource, contents in
            auditLesson(resource: resource, markdown: contents)
        }
        let bundledResources = Set(lessonContents.map(\.0))
        let levelCoverage = levels.map { level in
            let linked = level.topics.filter { topic in
                guard let resource = topic.lessonResource,
                      bundledResources.contains(resource),
                      let content = lessonContents.first(where: { $0.0 == resource })?.1 else { return false }
                return hasBilingualAssessment(content)
            }.count
            return CurriculumLevelCoverage(
                level: level.title,
                topicCount: level.topics.count,
                linkedLessonCount: linked
            )
        }
        return SubjectCurriculumCoverage(
            subject: subject,
            levels: levelCoverage,
            bundledLessonCount: lessonContents.count,
            bilingualLessonCount: lessonContents.filter { hasBilingualAssessment($0.1) }.count,
            sourceCitedLessonCount: lessonContents.filter { hasLinkedSource($0.1) }.count,
            structurallyCompleteLessonCount: lessonAudits.filter(\.isComplete).count,
            lessonStructureIssues: lessonAudits.filter { !$0.isComplete }.map(\.issue)
        )
    }

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
              let lessonURL = lessonFiles(for: subject).first(where: {
                  $0.deletingPathExtension().lastPathComponent == resource
              }) else { return nil }
        return try? String(contentsOf: lessonURL, encoding: .utf8)
    }

    private static func lessonFiles(for subject: Subject) -> [URL] {
        guard let resourcesURL = Bundle.main.resourceURL else { return [] }
        let lessonsURL = resourcesURL
            .appendingPathComponent("02_Areas", isDirectory: true)
            .appendingPathComponent(subject.rawValue.capitalized, isDirectory: true)
            .appendingPathComponent("lessons", isDirectory: true)
        return (try? FileManager.default.contentsOfDirectory(
            at: lessonsURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ))?.filter { $0.pathExtension.caseInsensitiveCompare("md") == .orderedSame }
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
            ?? []
    }

    private static func hasBilingualAssessment(_ markdown: String) -> Bool {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        return normalized.contains("## Русский")
            && normalized.contains("## English")
            && normalized.contains("### Вопрос")
            && normalized.contains("### Варианты")
            && normalized.contains("### Ответ")
            && normalized.contains("### Разбор")
            && normalized.contains("### Question")
            && normalized.contains("### Options")
            && normalized.contains("### Answer")
            && normalized.contains("### Explanation")
    }

    private static func hasLinkedSource(_ markdown: String) -> Bool {
        guard let sourceSection = markdown.range(of: "## Sources") else { return false }
        let sources = markdown[sourceSection.upperBound...]
        return sources.contains("https://")
    }

    private struct LessonAudit {
        let issue: CurriculumLessonStructureIssue
        let isComplete: Bool
    }

    private static func auditLesson(resource: String, markdown: String) -> LessonAudit {
        let russianRequired: [(String, [String])] = [
            ("management.courseSectionGoal", ["Цель"]),
            ("management.courseSectionTheory", ["Идея и механизм"]),
            ("management.courseSectionPractice", ["Исследуй и потренируйся", "Исследуй 3D-модель", "Исследуй в тренажёре"]),
            ("management.courseSectionQuestion", ["Вопрос"]),
            ("management.courseSectionOptions", ["Варианты"]),
            ("management.courseSectionAnswer", ["Ответ"]),
            ("management.courseSectionExplanation", ["Разбор"]),
            ("management.courseSectionLimits", ["Границы модели", "Границы правила", "Границы вывода", "Границы и безопасный запуск"])
        ]
        let englishRequired: [(String, [String])] = [
            ("management.courseSectionGoal", ["Goal"]),
            ("management.courseSectionTheory", ["Idea and mechanism"]),
            ("management.courseSectionPractice", ["Explore and practise", "Explore and practice", "Explore the 3D model", "Explore the lab"]),
            ("management.courseSectionQuestion", ["Question"]),
            ("management.courseSectionOptions", ["Options"]),
            ("management.courseSectionAnswer", ["Answer"]),
            ("management.courseSectionExplanation", ["Explanation"]),
            ("management.courseSectionLimits", ["Limits", "Limits of the inference", "Limits and safe execution"])
        ]

        let russianText = languageBody(in: markdown, heading: "## Русский")
        let englishText = languageBody(in: markdown, heading: "## English")
        let missingRussian = russianRequired.compactMap { key, headings in
            hasNonEmptySection(in: russianText, headings: headings) ? nil : key
        }
        let missingEnglish = englishRequired.compactMap { key, headings in
            hasNonEmptySection(in: englishText, headings: headings) ? nil : key
        }
        let missingSources = !hasLinkedSource(markdown)
        let issue = CurriculumLessonStructureIssue(
            resource: resource,
            missingRussianSections: missingRussian,
            missingEnglishSections: missingEnglish,
            missingSources: missingSources
        )
        return LessonAudit(
            issue: issue,
            isComplete: missingRussian.isEmpty && missingEnglish.isEmpty && !missingSources
        )
    }

    private static func languageBody(in markdown: String, heading: String) -> String {
        let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        guard let start = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == heading }) else {
            return ""
        }
        return lines.dropFirst(start + 1)
            .prefix(while: { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("## ") })
            .joined(separator: "\n")
    }

    private static func hasNonEmptySection(in body: String, headings: [String]) -> Bool {
        let lines = body.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.hasPrefix("### ") && headings.contains(String(trimmed.dropFirst(4)))
        }) else { return false }
        return lines.dropFirst(start + 1)
            .prefix(while: { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("### ") })
            .contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
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
