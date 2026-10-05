import Foundation
import SwiftUI
import AppKit
import SceneKit
import WebKit
import UniformTypeIdentifiers

struct SubjectOverviewView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var levels: [CurriculumLevel] = []

    let subject: Subject
    let openCourseLesson: (String) -> Void
    let startLesson: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text("roadmap.eyebrow", store.language))
                        .font(.caption.weight(.semibold))
                        .tracking(1.3)
                        .foregroundStyle(subject.tint)
                    Text(subject.title(in: store.language))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(subject.subtitle(in: store.language))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(L10n.text("roadmap.title", store.language))
                        .font(.title2.weight(.semibold))
                        .padding(.top, 6)
                    Text(L10n.text("roadmap.description", store.language))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(action: startLesson) {
                        Label {
                            Text(L10n.text("roadmap.start", store.language))
                        } icon: {
                            Image(systemName: "play.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(subject.tint)
                    .padding(.top, 4)
                }
                .padding(.top, 26)

                if levels.isEmpty {
                    Label {
                        Text(L10n.text("roadmap.unavailable", store.language))
                    } icon: {
                        Image(systemName: "doc.questionmark")
                    }
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                } else {
                    ForEach(levels) { level in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(level.title.value(in: store.language))
                                    .font(.title2.weight(.semibold))
                                Spacer()
                                Text(L10n.text("roadmap.topicCount", store.language) + "\(level.topics.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(level.topics) { topic in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(topic.name.value(in: store.language))
                                        .font(.headline)
                                    Text(topic.learningOutcome.value(in: store.language))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if let lessonResource = topic.lessonResource {
                                        Button { openCourseLesson(lessonResource) } label: {
                                            Label(
                                                L10n.text("roadmap.openFullLesson", store.language),
                                                systemImage: store.isComplete(lessonID: "\(subject.rawValue).\(lessonResource)")
                                                    ? "checkmark.circle.fill"
                                                    : "book.closed"
                                            )
                                        }
                                        .buttonStyle(.borderless)
                                        .padding(.top, 3)
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.background, in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.quaternary, lineWidth: 1))
                            }
                        }
                        .padding(18)
                        .background(subject.tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 32)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(Text(subject.title(in: store.language)))
        .onAppear { levels = CurriculumCatalog.roadmap(for: subject) }
    }
}

private struct CurriculumLessonDocument {
    let title: String
    let objective: String
    let theory: String
    let practice: String
    let answer: String
    let checkQuestion: String
    let checkOptions: [String]
    let checkAnswerIndex: Int?
    let limitations: String
    let sources: String

    static func load(subject: Subject, resource: String, language: AppLanguage) -> CurriculumLessonDocument? {
        guard let raw = CurriculumCatalog.lessonMarkdown(for: subject, resource: resource) else { return nil }
        var lines = raw.components(separatedBy: .newlines)
        if lines.first?.trimmingCharacters(in: .whitespaces) == "---",
           let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) {
            lines = Array(lines.dropFirst(end + 1))
        }
        guard let titleLine = lines.first(where: { $0.hasPrefix("# ") }) else { return nil }
        let titleValue = String(titleLine.dropFirst(2))
        let titleParts = titleValue.components(separatedBy: " / ")
        let title = language == .ru ? titleParts.first ?? titleValue : titleParts.last ?? titleValue

        let languageHeader = language == .ru ? "## Русский" : "## English"
        guard let languageStart = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == languageHeader }) else {
            return nil
        }
        let languageLines = Array(lines.dropFirst(languageStart + 1))
            .prefix(while: { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("## ") })
        let section = languageLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let objective = extract(section, headings: language == .ru ? ["Цель"] : ["Goal"])
        let theory = extract(section, headings: language == .ru ? ["Идея и механизм"] : ["Idea and mechanism"])
        var practice = extract(section, headings: language == .ru
            ? ["Исследуй и потренируйся"]
            : ["Explore and practise", "Explore and practice"])
        let checkQuestion = extract(section, headings: language == .ru ? ["Вопрос"] : ["Question"])
        let checkOptions = parseOptions(extract(section, headings: language == .ru ? ["Варианты"] : ["Options"]))
        let checkAnswer = Int(extract(section, headings: language == .ru ? ["Ответ"] : ["Answer"]).trimmingCharacters(in: .whitespacesAndNewlines))
        let checkAnswerIndex = checkAnswer.map { $0 - 1 }.flatMap { checkOptions.indices.contains($0) ? $0 : nil }
        let answer = extract(section, headings: language == .ru ? ["Разбор"] : ["Explanation"])
        let limitations = extract(section, headings: language == .ru
            ? ["Границы модели", "Границы правила", "Границы вывода", "Границы и безопасный запуск"]
            : ["Limits", "Limits of the inference", "Limits and safe execution"])
        let sourceLines = lines.drop { $0.trimmingCharacters(in: .whitespaces) != "## Sources" }.dropFirst()
        let sources = sourceLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return CurriculumLessonDocument(
            title: title,
            objective: objective,
            theory: theory,
            practice: practice,
            answer: answer,
            checkQuestion: checkQuestion,
            checkOptions: checkOptions,
            checkAnswerIndex: checkAnswerIndex,
            limitations: limitations,
            sources: sources
        )
    }

    var tutorContext: LessonContent {
        LessonContent(
            title: title,
            objective: objective,
            explanation: theory,
            mechanism: practice,
            example: answer,
            limitations: limitations,
            question: "",
            options: [],
            answerIndex: 0,
            feedback: answer
        )
    }

    func notebookSource(subject: Subject, language: AppLanguage) -> String {
        let subjectLabel = subject.title(in: language)
        let goalHeading = language == .ru ? "Цель" : "Learning goal"
        let theoryHeading = language == .ru ? "Теория и механизм" : "Theory and mechanism"
        let practiceHeading = language == .ru ? "Практика" : "Practice"
        let checkHeading = language == .ru ? "Проверка понимания" : "Knowledge check"
        let answerHeading = language == .ru ? "Правильный ответ и разбор" : "Correct answer and explanation"
        let limitsHeading = language == .ru ? "Ограничения" : "Limitations"
        let sourcesHeading = language == .ru ? "Источники" : "Sources"
        let origin = language == .ru ? "Экспортировано из ColiDev" : "Exported from ColiDev"

        var sections = [
            "# \(title)",
            "**\(language == .ru ? "Предмет" : "Subject"): \(subjectLabel)**",
            "*\(origin)*",
            "## \(goalHeading)\n\(objective)",
            "## \(theoryHeading)\n\(theory)",
        ]
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
            let answerLabel = language == .ru ? "Правильный вариант" : "Correct option"
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

    private static func extract(_ markdown: String, headings: [String]) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.hasPrefix("### ") && headings.contains(String(trimmed.dropFirst(4)))
        }) else { return "" }
        let body = lines.dropFirst(start + 1).prefix(while: {
            !$0.trimmingCharacters(in: .whitespaces).hasPrefix("### ")
        })
        return body.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseOptions(_ markdown: String) -> [String] {
        markdown.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") {
                return String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            }
            guard let range = trimmed.range(of: "^\\d+[.)]\\s+", options: .regularExpression) else { return nil }
            return String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
    }
}

struct CurriculumModuleView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var document: CurriculumLessonDocument?
    @State private var showingTutor = false
    @State private var learnerConfirmed = false
    @State private var recallQuality = 4
    @State private var selectedCheckAnswer: Int?
    @State private var isExportingNotebookSource = false
    @State private var notebookExportDocument: NotebookLMSourceFile?
    @State private var notebookExportFilename = "ColiDev-lesson.md"
    @State private var notebookExportStatus: String?

    let subject: Subject
    let resource: String

    private var lessonID: String { "\(subject.rawValue).\(resource)" }
    private var isComplete: Bool { store.isComplete(lessonID: lessonID) }
    private var isReviewDue: Bool { store.isReviewDue(lessonID: lessonID) }
    private var hasPendingReview: Bool { store.hasPendingReview(lessonID: lessonID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let document {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.text("session.lesson", store.language))
                            .font(.caption.weight(.semibold))
                            .tracking(1.3)
                            .foregroundStyle(subject.tint)
                        Text(document.title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subject.title(in: store.language) + " · " + L10n.text("roadmap.fullModule", store.language))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    Button { showingTutor = true } label: {
                        Label(L10n.text("tutor.title", store.language), systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)

                    ModuleTextCard(title: L10n.text("session.goal", store.language), text: document.objective, tint: subject.tint)
                    ModuleTextCard(title: L10n.text("session.theory", store.language), text: document.theory, tint: subject.tint)
                    if !document.practice.isEmpty {
                        ModuleTextCard(title: L10n.text("session.lab", store.language), text: document.practice, tint: subject.tint)
                    }
                    PracticeLab(subject: subject, moduleResource: resource)

                    if !document.checkQuestion.isEmpty, !document.checkOptions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.text("module.check", store.language))
                                .font(.title2.weight(.semibold))
                            Text(document.checkQuestion)
                                .font(.headline)
                            ForEach(document.checkOptions.indices, id: \.self) { index in
                                Button {
                                    selectedCheckAnswer = index
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: selectedCheckAnswer == index ? "largecircle.fill.circle" : "circle")
                                        Text(document.checkOptions[index])
                                            .multilineTextAlignment(.leading)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(11)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.background, in: RoundedRectangle(cornerRadius: 11))
                                    .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(.quaternary, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                            if let selectedCheckAnswer {
                                let isCorrect = selectedCheckAnswer == document.checkAnswerIndex
                                Label(
                                    L10n.text(isCorrect ? "module.correct" : "module.incorrect", store.language),
                                    systemImage: isCorrect ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                                )
                                .foregroundStyle(isCorrect ? Color.green : Color.orange)
                                if isCorrect, !document.answer.isEmpty {
                                    Text((try? AttributedString(markdown: document.answer)) ?? AttributedString(document.answer))
                                        .textSelection(.enabled)
                                        .padding(.top, 2)
                                }
                            }
                        }
                        .padding(18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }

                    if !document.limitations.isEmpty {
                        ModuleTextCard(title: L10n.text("session.limitations", store.language), text: document.limitations, tint: subject.tint)
                    }
                    if !document.sources.isEmpty {
                        ModuleTextCard(title: L10n.text("module.sources", store.language), text: document.sources, tint: subject.tint)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.text("module.notebookTitle", store.language))
                            .font(.headline)
                        HStack(spacing: 12) {
                            Button {
                                notebookExportDocument = NotebookLMSourceFile(
                                    text: document.notebookSource(subject: subject, language: store.language)
                                )
                                notebookExportFilename = "ColiDev-\(subject.rawValue)-\(resource)-\(store.language.rawValue).md"
                                notebookExportStatus = nil
                                isExportingNotebookSource = true
                            } label: {
                                Label(L10n.text("module.notebookExport", store.language), systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                if let url = URL(string: "https://notebooklm.google.com") {
                                    if !NSWorkspace.shared.open(url) {
                                        notebookExportStatus = L10n.text("module.notebookOpenFailed", store.language)
                                    }
                                }
                            } label: {
                                Label(L10n.text("module.notebookOpen", store.language), systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(.bordered)
                        }
                        Text(L10n.text("module.notebookPrivacy", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let notebookExportStatus {
                            Text(notebookExportStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("session.listen", store.language)).font(.headline)
                        Toggle(L10n.text("session.doneCheck", store.language), isOn: $learnerConfirmed)
                            .toggleStyle(.checkbox)
                        Picker(L10n.text("session.recallQuality", store.language), selection: $recallQuality) {
                            Text(L10n.text("session.recallHard", store.language)).tag(2)
                            Text(L10n.text("session.recallGood", store.language)).tag(4)
                            Text(L10n.text("session.recallEasy", store.language)).tag(5)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

                    Button {
                        if isComplete {
                            store.recordReview(lessonID: lessonID, quality: recallQuality)
                        } else {
                            store.markComplete(lessonID: lessonID, quality: recallQuality)
                        }
                    } label: {
                        let title = hasPendingReview
                            ? "session.reviewSaved"
                            : (isComplete
                                ? (isReviewDue ? "session.recordReview" : "session.completed")
                                : "session.complete")
                        Label(L10n.text(title, store.language), systemImage: isComplete ? "checkmark.circle.fill" : "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        !learnerConfirmed
                            || selectedCheckAnswer != document.checkAnswerIndex
                            || hasPendingReview
                            || (isComplete && !isReviewDue)
                    )
                    .padding(.bottom, 32)
                } else {
                    Label(L10n.text("module.unavailable", store.language), systemImage: "doc.questionmark")
                        .foregroundStyle(.secondary)
                        .padding(24)
                }
            }
            .padding(.horizontal, 34)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(Text(document?.title ?? L10n.text("module.title", store.language)))
        .onAppear { loadDocument() }
        .onChange(of: store.language) { _ in loadDocument() }
        .fileExporter(
            isPresented: $isExportingNotebookSource,
            document: notebookExportDocument,
            contentType: NotebookLMFileType.markdown,
            defaultFilename: notebookExportFilename
        ) { result in
            switch result {
            case .success(let url):
                notebookExportStatus = String(
                    format: L10n.text("module.notebookExported", store.language),
                    url.lastPathComponent
                )
            case .failure(let error):
                if (error as? CocoaError)?.code == .userCancelled {
                    notebookExportStatus = nil
                } else {
                    notebookExportStatus = L10n.text("module.notebookExportFailed", store.language)
                }
            }
        }
        .sheet(isPresented: $showingTutor) {
            if let document {
                TutorChatView(subject: subject, lesson: document.tutorContext, language: store.language, mode: store.aiMode)
                    .environmentObject(store)
                    .frame(minWidth: 680, minHeight: 520)
            }
        }
    }

    private func loadDocument() {
        document = CurriculumLessonDocument.load(subject: subject, resource: resource, language: store.language)
        learnerConfirmed = isComplete
    }
}

private struct NotebookLMSourceFile: FileDocument {
    static var readableContentTypes: [UTType] { [NotebookLMFileType.markdown] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

private enum NotebookLMFileType {
    static let markdown = UTType(filenameExtension: "md") ?? .plainText
}

private struct ModuleTextCard: View {
    let title: String
    let text: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
            Text((try? AttributedString(markdown: text)) ?? AttributedString(text))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct LessonSessionView: View {
    @EnvironmentObject private var store: LearningStore
    let subject: Subject
    let showRoadmap: () -> Void

    @State private var selectedAnswer: Int?
    @State private var learnerConfirmed = false
    @State private var reflection = ""
    @State private var showingTutor = false

    private var content: LessonContent {
        LearningCatalog.lesson(for: subject, language: store.language)
    }

    private var answerIsCorrect: Bool {
        selectedAnswer == content.answerIndex
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("session.lesson", store.language))
                        .font(.caption.weight(.semibold))
                        .tracking(1.3)
                        .foregroundStyle(subject.tint)
                    Text(content.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subject.title(in: store.language) + " · " + subject.subtitle(in: store.language))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Button(action: showRoadmap) {
                        Label(L10n.text("roadmap.open", store.language), systemImage: "list.bullet.rectangle")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.top, 24)

                Button { showingTutor = true } label: {
                    Label(L10n.text("tutor.title", store.language), systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("session.goal", store.language))
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Text(content.objective)
                        .font(.title3.weight(.medium))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(subject.tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))

                LessonConceptCard(
                    title: L10n.text("session.theory", store.language),
                    text: content.explanation,
                    symbol: "text.book.closed",
                    tint: subject.tint
                )
                LessonConceptCard(
                    title: L10n.text("session.mechanism", store.language),
                    text: content.mechanism,
                    symbol: "gearshape.2",
                    tint: subject.tint
                )
                LessonConceptCard(
                    title: L10n.text("session.example", store.language),
                    text: content.example,
                    symbol: "lightbulb",
                    tint: subject.tint
                )
                LessonConceptCard(
                    title: L10n.text("session.limitations", store.language),
                    text: content.limitations,
                    symbol: "scope",
                    tint: subject.tint
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text("session.lab", store.language))
                        .font(.title2.weight(.semibold))
                    Text(L10n.text("session.labHint", store.language))
                        .foregroundStyle(.secondary)
                    PracticeLab(subject: subject)
                }

                quizCard

                if selectedAnswer == content.answerIndex || store.isComplete(subject) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("session.listen", store.language))
                            .font(.headline)
                        TextField(L10n.text("session.reflectionPlaceholder", store.language), text: $reflection, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                        Toggle(L10n.text("session.doneCheck", store.language), isOn: $learnerConfirmed)
                            .toggleStyle(.checkbox)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

                    Button {
                        if store.isComplete(subject) {
                            store.recordReview(for: subject)
                        } else {
                            store.markComplete(subject)
                        }
                    } label: {
                        let title = store.hasPendingReview(subject)
                            ? "session.reviewSaved"
                            : (store.isComplete(subject)
                                ? (store.isReviewDue(subject) ? "session.recordReview" : "session.completed")
                                : "session.complete")
                        Label {
                            Text(L10n.text(title, store.language))
                        } icon: {
                            Image(systemName: store.isComplete(subject) ? "checkmark.circle.fill" : "checkmark")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        !learnerConfirmed
                            || store.hasPendingReview(subject)
                            || (store.isComplete(subject) && !store.isReviewDue(subject))
                    )
                    .padding(.bottom, 32)
                }
            }
            .padding(.horizontal, 34)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { learnerConfirmed = store.isComplete(subject) }
        .navigationTitle(Text(subject.title(in: store.language)))
        .sheet(isPresented: $showingTutor) {
            TutorChatView(subject: subject, lesson: content, language: store.language, mode: store.aiMode)
                .environmentObject(store)
                .frame(minWidth: 680, minHeight: 520)
        }
    }

    private var quizCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("session.check", store.language))
                .font(.title2.weight(.semibold))
            Text(content.question)
                .font(.headline)
            ForEach(content.options.indices, id: \.self) { index in
                Button {
                    selectedAnswer = index
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedAnswer == index ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selectedAnswer == index ? subject.tint : Color.secondary)
                        Text(content.options[index])
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            if selectedAnswer != nil {
                Label { Text(answerIsCorrect ? content.feedback : L10n.text("session.wrong", store.language)) } icon: { Image(systemName: answerIsCorrect ? "checkmark.circle.fill" : "arrow.counterclockwise.circle") }
                .font(.callout)
                .foregroundStyle(answerIsCorrect ? Color.green : Color.orange)
                .padding(.top, 4)
                if !answerIsCorrect {
                    Button { self.selectedAnswer = nil } label: { Text(L10n.text("session.retry", store.language)) }
                        .buttonStyle(.link)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct LessonConceptCard: View {
    let title: String
    let text: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.body)
                .lineSpacing(5)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

private struct PracticeLab: View {
    let subject: Subject
    let moduleResource: String?

    init(subject: Subject, moduleResource: String? = nil) {
        self.subject = subject
        self.moduleResource = moduleResource
    }

    @ViewBuilder
    var body: some View {
        if subject == .mathematics, moduleResource == "domain_and_range" {
            DomainRangeLab()
        } else if subject == .english, moduleResource == "present_simple_and_continuous" {
            TenseContrastLab()
        } else if subject == .english, moduleResource == "present_perfect_simple_continuous" {
            PresentPerfectAspectLab()
        } else if subject == .biology, moduleResource == "passive_transport_osmosis" {
            OsmosisLab()
        } else if subject == .biology, moduleResource == "mendelian_inheritance" {
            PunnettLab()
        } else if subject == .physics, moduleResource == "work_and_kinetic_energy" {
            KineticEnergyLab()
        } else {
            switch subject {
        case .mathematics:
            SlopeLab()
        case .english:
            SentenceLab()
        case .physics:
            ForceLab()
        case .biology:
            CellLab()
        case .zoology:
            AdaptationLab()
        case .programming:
            ConditionalLab()
            }
        }
    }
}

private struct DomainRangeLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var selectedScenario = 0
    @State private var bound = 4.0

    private var integerBound: Int { Int(bound) }
    private var inputLowerBound: Double {
        selectedScenario == 1 ? -bound : 0
    }
    private var inputUpperBound: Double {
        selectedScenario == 2 ? bound * bound : bound
    }
    private var outputUpperBound: Double {
        switch selectedScenario {
        case 0: return 2 + 3 * bound
        case 1: return bound * bound
        default: return bound
        }
    }
    private var equation: String {
        switch selectedScenario {
        case 0: return "C(k) = 2 + 3k"
        case 1: return "f(x) = x²"
        default: return "g(x) = √x"
        }
    }
    private var inputInterval: String {
        switch selectedScenario {
        case 0: return "0 ≤ k ≤ \(integerBound)"
        case 1: return "−\(integerBound) ≤ x ≤ \(integerBound)"
        default: return "0 ≤ x ≤ \(integerBound * integerBound)"
        }
    }
    private var outputInterval: String {
        switch selectedScenario {
        case 0: return "2 ≤ C(k) ≤ \(2 + 3 * integerBound)"
        case 1: return "0 ≤ f(x) ≤ \(integerBound * integerBound)"
        default: return "0 ≤ g(x) ≤ \(integerBound)"
        }
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.domainHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)

            Picker("", selection: $selectedScenario) {
                Text(L10n.text("lab.domainTaxi", store.language)).tag(0)
                Text(L10n.text("lab.domainSquare", store.language)).tag(1)
                Text(L10n.text("lab.domainRoot", store.language)).tag(2)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text(L10n.text("session.lab", store.language)))

            Text(equation)
                .font(.system(.headline, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(L10n.text("lab.domainInput", store.language)): \(inputInterval)")
                Text("\(L10n.text("lab.domainOutput", store.language)): \(outputInterval)")
            }
            .font(.callout.monospacedDigit())
            .foregroundStyle(.secondary)

            Canvas { context, size in
                guard size.width > 0, size.height > 0, inputUpperBound > inputLowerBound else { return }

                var grid = Path()
                for step in 0...4 {
                    let fraction = CGFloat(step) / 4
                    let x = size.width * fraction
                    let y = size.height * fraction
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(.secondary.opacity(0.14)), lineWidth: 1)

                var axes = Path()
                axes.move(to: CGPoint(x: 0, y: size.height))
                axes.addLine(to: CGPoint(x: size.width, y: size.height))
                let zeroXFraction = (0 - inputLowerBound) / (inputUpperBound - inputLowerBound)
                let zeroX = CGFloat(zeroXFraction) * size.width
                axes.move(to: CGPoint(x: zeroX, y: 0))
                axes.addLine(to: CGPoint(x: zeroX, y: size.height))
                context.stroke(axes, with: .color(.secondary.opacity(0.55)), lineWidth: 1)

                var curve = Path()
                for sample in 0...80 {
                    let fraction = Double(sample) / 80
                    let input = inputLowerBound + fraction * (inputUpperBound - inputLowerBound)
                    let output: Double
                    switch selectedScenario {
                    case 0: output = 2 + 3 * input
                    case 1: output = input * input
                    default: output = input.squareRoot()
                    }
                    let yFraction = min(max(output / outputUpperBound, 0), 1)
                    let point = CGPoint(
                        x: CGFloat(fraction) * size.width,
                        y: size.height * (1 - CGFloat(yFraction))
                    )
                    if sample == 0 {
                        curve.move(to: point)
                    } else {
                        curve.addLine(to: point)
                    }
                }
                context.stroke(curve, with: .color(.indigo), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            .frame(height: 150)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(String(
                format: L10n.text("lab.domainGraphLabel", store.language),
                inputInterval,
                outputInterval
            )))

            HStack {
                Text("\(L10n.text("lab.domainBound", store.language)): N = \(integerBound)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Spacer()
                Text("1…8")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            Slider(value: $bound, in: 1...8, step: 1)
                .accessibilityLabel(Text(L10n.text("lab.domainBound", store.language)))
        }
    }
}

private struct TenseContrastLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var scenario = 0
    @State private var selectedAnswer: Int?

    private var correctAnswer: Int { scenario }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.tensePrompt", store.language))
                .font(.headline)
            Picker("", selection: $scenario) {
                Text(L10n.text("lab.tenseScenario0", store.language)).tag(0)
                Text(L10n.text("lab.tenseScenario1", store.language)).tag(1)
            }
            .pickerStyle(.segmented)
            .onChange(of: scenario) { _ in selectedAnswer = nil }

            HStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { option in
                    Button {
                        selectedAnswer = option
                    } label: {
                        Text(L10n.text("lab.tenseOption\(scenario)\(option)", store.language))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(
                                selectedAnswer == option
                                    ? (option == correctAnswer ? Color.green.opacity(0.16) : Color.orange.opacity(0.16))
                                    : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selectedAnswer {
                Label(
                    L10n.text(selectedAnswer == correctAnswer ? "lab.tenseCorrect" : "lab.tenseIncorrect", store.language),
                    systemImage: selectedAnswer == correctAnswer ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                )
                .foregroundStyle(selectedAnswer == correctAnswer ? Color.green : Color.orange)
            }
        }
    }
}

private struct PresentPerfectAspectLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var scenario = 0
    @State private var selectedAnswer: Int?

    private let correctAnswers = [1, 1, 0]

    var body: some View {
        LabCard {
            Text(L10n.text("lab.perfectPrompt", store.language))
                .font(.headline)

            Picker(L10n.text("lab.perfectSituation", store.language), selection: $scenario) {
                ForEach(0..<3, id: \.self) { index in
                    Text(L10n.text("lab.perfectScenario\(index)", store.language)).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: scenario) { _ in selectedAnswer = nil }

            Text(L10n.text("lab.perfectSentence\(scenario)", store.language))
                .font(.title3.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { option in
                    Button {
                        selectedAnswer = option
                    } label: {
                        Text(L10n.text("lab.perfectOption\(scenario)\(option)", store.language))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(answerColor(for: option), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selectedAnswer {
                let isCorrect = selectedAnswer == correctAnswers[scenario]
                Label(
                    L10n.text("lab.perfectFeedback\(scenario)\(isCorrect ? 1 : 0)", store.language),
                    systemImage: isCorrect ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                )
                .foregroundStyle(isCorrect ? Color.green : Color.orange)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func answerColor(for option: Int) -> Color {
        guard let selectedAnswer, selectedAnswer == option else {
            return Color.secondary.opacity(0.08)
        }
        return option == correctAnswers[scenario] ? Color.green.opacity(0.16) : Color.orange.opacity(0.16)
    }
}

private struct OsmosisLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var insideConcentration = 4.0
    @State private var outsideConcentration = 6.0

    private var netFlowKey: String {
        if outsideConcentration > insideConcentration { return "lab.osmosisWaterEnters" }
        if insideConcentration > outsideConcentration { return "lab.osmosisWaterLeaves" }
        return "lab.osmosisBalanced"
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.osmosisHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack(alignment: .center, spacing: 14) {
                concentrationDisplay(
                    title: L10n.text("lab.osmosisOutside", store.language),
                    value: outsideConcentration
                )
                Image(systemName: outsideConcentration == insideConcentration
                    ? "arrow.left.and.right"
                    : (outsideConcentration > insideConcentration ? "arrow.right" : "arrow.left"))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.12))
                        .frame(width: 118, height: 118)
                    Circle()
                        .strokeBorder(Color.cyan.opacity(0.75), lineWidth: 3)
                        .frame(width: 118, height: 118)
                    VStack(spacing: 5) {
                        Text(L10n.text("lab.osmosisInside", store.language))
                            .font(.caption.weight(.semibold))
                        Text("\(insideConcentration, specifier: "%.0f")")
                            .font(.title2.monospacedDigit().weight(.bold))
                        soluteDots(insideConcentration)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(L10n.text("lab.osmosisInside", store.language) + ", \(Int(insideConcentration))"))
            }
            .frame(maxWidth: .infinity)

            concentrationSlider(title: L10n.text("lab.osmosisOutside", store.language), value: $outsideConcentration)
            concentrationSlider(title: L10n.text("lab.osmosisInside", store.language), value: $insideConcentration)

            Label(L10n.text(netFlowKey, store.language), systemImage: "drop.fill")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.blue)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func concentrationDisplay(title: String, value: Double) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
            Text("\(value, specifier: "%.0f")")
                .font(.title2.monospacedDigit().weight(.bold))
            soluteDots(value)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func soluteDots(_ value: Double) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<Int(value), id: \.self) { _ in
                Circle().fill(Color.purple.opacity(0.78)).frame(width: 6, height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    private func concentrationSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(0)))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: 0...10, step: 1)
        }
    }
}

private struct LabCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct SlopeLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var slope = 1.5

    var body: some View {
        LabCard {
            HStack {
                Label("y = ax", systemImage: "function")
                    .font(.system(.headline, design: .monospaced))
                Spacer()
                Text("a = \(slope, specifier: "%.1f")")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Canvas { context, size in
                var grid = Path()
                for step in 0...4 {
                    let x = size.width * CGFloat(step) / 4
                    let y = size.height * CGFloat(step) / 4
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(.secondary.opacity(0.14)), lineWidth: 1)
                var axis = Path()
                axis.move(to: CGPoint(x: 0, y: size.height / 2))
                axis.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                context.stroke(axis, with: .color(.secondary.opacity(0.55)), lineWidth: 1)
                var line = Path()
                for step in 0...60 {
                    let unitX = CGFloat(step) / 60
                    let xValue = (unitX * 2) - 1
                    let yValue = CGFloat(slope) * xValue
                    let point = CGPoint(x: unitX * size.width, y: size.height / 2 - yValue * size.height / 2.4)
                    if step == 0 { line.move(to: point) } else { line.addLine(to: point) }
                }
                context.stroke(line, with: .color(.indigo), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            .frame(height: 150)
            Slider(value: $slope, in: 0.5...3.0, step: 0.5)
            HStack(spacing: 4) {
                Text(L10n.text("lab.slope", store.language))
                Text(":")
                Text(slope, format: .number.precision(.fractionLength(1)))
            }
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SentenceLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var selectedWords: [Int] = []
    private let wordOrder = [3, 2, 0, 1]

    var body: some View {
        LabCard {
            Text(L10n.text("lab.buildSentence", store.language))
                .font(.headline)
            HStack {
                ForEach(wordOrder, id: \.self) { index in
                    Button { selectedWords.append(index) } label: { Text(L10n.text("english.word\(index)", store.language)) }
                    .buttonStyle(.bordered)
                    .disabled(selectedWords.contains(index))
                }
            }
            Text(selectedWords.map { L10n.text("english.word\($0)", store.language) }.joined(separator: " "))
                .font(.title3.weight(.medium))
                .frame(minHeight: 32, alignment: .leading)
            HStack {
                Label { Text(L10n.text("practice.words", store.language)) } icon: { Image(systemName: "textformat") }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button { selectedWords.removeAll() } label: { Text(L10n.text("lab.clear", store.language)) }
                    .buttonStyle(.link)
            }
        }
    }
}

private struct ForceLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var force = 12.0
    @State private var mass = 3.0

    private var acceleration: Double { force / mass }

    var body: some View {
        LabCard {
            Force3DVisualization(force: force, mass: mass)
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel(Text(L10n.text("lab.force3DHint", store.language)))
            Text(L10n.text("lab.force3DHint", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .center, spacing: 20) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.blue)
                    .frame(width: 80, height: 80)
                    .background(.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 5) {
                    Text("F = ma")
                        .font(.system(.title2, design: .monospaced, weight: .bold))
                    Text("a = \(acceleration, specifier: "%.1f") m/s²")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            valueSlider(title: L10n.text("lab.force", store.language), value: $force, range: 1...30, suffix: " N")
            valueSlider(title: L10n.text("lab.mass", store.language), value: $mass, range: 1...10, suffix: " kg")
            HStack(spacing: 4) {
                Text(L10n.text("lab.acceleration", store.language))
                Text(":")
                Text(acceleration, format: .number.precision(.fractionLength(2)))
                Text("m/s²")
            }
                .font(.callout.weight(.medium))
        }
    }

    private func valueSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue, specifier: "%.0f")\(suffix)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 1)
        }
    }
}

private struct Force3DVisualization: View {
    let force: Double
    let mass: Double
    @State private var scene: SCNScene

    init(force: Double, mass: Double) {
        self.force = force
        self.mass = mass
        _scene = State(initialValue: Self.makeScene(force: force, mass: mass))
    }

    var body: some View {
        SceneView(scene: scene, options: [.allowsCameraControl])
            .background(Color(nsColor: .windowBackgroundColor))
            .onChange(of: force) { _ in updateScene() }
            .onChange(of: mass) { _ in updateScene() }
    }

    private static func makeScene(force: Double, mass: Double) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor.windowBackgroundColor

        let box = SCNBox(width: 1, height: 0.72, length: 0.72, chamferRadius: 0.08)
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = NSColor.systemBlue
        boxMaterial.metalness.contents = 0.08
        boxMaterial.roughness.contents = 0.42
        box.materials = [boxMaterial]
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "mass-block"
        scene.rootNode.addChildNode(boxNode)

        let ground = SCNBox(width: 4.5, height: 0.06, length: 2.6, chamferRadius: 0.02)
        ground.firstMaterial?.diffuse.contents = NSColor.tertiaryLabelColor
        let groundNode = SCNNode(geometry: ground)
        groundNode.position = SCNVector3(0, -0.04, 0)
        scene.rootNode.addChildNode(groundNode)

        let arrowColor = NSColor.systemOrange

        let shaft = SCNCylinder(radius: 0.045, height: 1)
        shaft.firstMaterial?.diffuse.contents = arrowColor
        let shaftNode = SCNNode(geometry: shaft)
        shaftNode.name = "force-shaft"
        scene.rootNode.addChildNode(shaftNode)

        let arrowHead = SCNCone(topRadius: 0, bottomRadius: 0.14, height: 0.28)
        arrowHead.firstMaterial?.diffuse.contents = arrowColor
        let arrowHeadNode = SCNNode(geometry: arrowHead)
        arrowHeadNode.name = "force-head"
        scene.rootNode.addChildNode(arrowHeadNode)

        let camera = SCNCamera()
        camera.fieldOfView = 48
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(2.5, 2.0, 4.7)
        cameraNode.look(at: SCNVector3(0.1, 0.45, 0))
        scene.rootNode.addChildNode(cameraNode)

        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 850
        let keyLightNode = SCNNode()
        keyLightNode.light = keyLight
        keyLightNode.eulerAngles = SCNVector3(-0.75, 0.7, 0)
        scene.rootNode.addChildNode(keyLightNode)

        scene.lightingEnvironment.intensity = 0.7
        update(scene: scene, force: force, mass: mass)
        return scene
    }

    private func updateScene() {
        Self.update(scene: scene, force: force, mass: mass)
    }

    private static func update(scene: SCNScene, force: Double, mass: Double) {
        let massScale = CGFloat(0.75 + mass * 0.05)
        let arrowLength = CGFloat(0.55 + force / 30)
        let arrowBaseX = -0.65 + 0.58 * massScale
        let arrowY = 0.36 * massScale

        if let box = scene.rootNode.childNode(withName: "mass-block", recursively: false) {
            box.scale = SCNVector3(Float(massScale), Float(massScale), Float(massScale))
            box.position = SCNVector3(-0.65, Float(arrowY), 0)
        }
        if let shaft = scene.rootNode.childNode(withName: "force-shaft", recursively: false) {
            let geometry = SCNCylinder(radius: 0.045, height: arrowLength)
            geometry.firstMaterial?.diffuse.contents = NSColor.systemOrange
            shaft.geometry = geometry
            shaft.eulerAngles.z = -.pi / 2
            shaft.position = SCNVector3(Float(arrowBaseX + arrowLength / 2), Float(arrowY), 0)
        }
        if let head = scene.rootNode.childNode(withName: "force-head", recursively: false) {
            head.eulerAngles.z = -.pi / 2
            head.position = SCNVector3(Float(arrowBaseX + arrowLength + 0.12), Float(arrowY), 0)
        }
    }
}

private struct KineticEnergyLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var mass = 2.0
    @State private var initialSpeed = 3.0
    @State private var netWork = 20.0

    private var initialEnergy: Double { 0.5 * mass * initialSpeed * initialSpeed }
    private var proposedFinalEnergy: Double { initialEnergy + netWork }
    private var finalEnergy: Double { max(0, proposedFinalEnergy) }
    private var finalSpeed: Double { sqrt(2 * finalEnergy / mass) }
    private var stopsBeforeWorkCompletes: Bool { proposedFinalEnergy < 0 }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.energyHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)

            Energy3DVisualization(mass: mass, speed: finalSpeed)
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel(Text(L10n.text("lab.energy3DHint", store.language)))
            Text(L10n.text("lab.energy3DHint", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 14) {
                energyReadout(title: L10n.text("lab.energyInitial", store.language), value: initialEnergy, unit: "J")
                Image(systemName: "arrow.right")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                energyReadout(title: L10n.text("lab.energyFinal", store.language), value: finalEnergy, unit: "J")
                Spacer(minLength: 0)
                energyReadout(title: L10n.text("lab.energyFinalSpeed", store.language), value: finalSpeed, unit: "m/s")
            }

            valueSlider(title: L10n.text("lab.mass", store.language), value: $mass, range: 1...8, suffix: " kg")
            valueSlider(title: L10n.text("lab.energyInitialSpeed", store.language), value: $initialSpeed, range: 0...12, suffix: " m/s")
            valueSlider(title: L10n.text("lab.energyNetWork", store.language), value: $netWork, range: -80...120, suffix: " J")

            if stopsBeforeWorkCompletes {
                Label(L10n.text("lab.energyStops", store.language), systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func energyReadout(title: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value, specifier: "%.1f") \(unit)")
                .font(.callout.monospacedDigit().weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }

    private func valueSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue, specifier: "%.0f")\(suffix)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 1)
                .accessibilityLabel(Text(title))
        }
    }
}

private struct Energy3DVisualization: View {
    let mass: Double
    let speed: Double
    @State private var scene: SCNScene

    init(mass: Double, speed: Double) {
        self.mass = mass
        self.speed = speed
        _scene = State(initialValue: Self.makeScene(mass: mass, speed: speed))
    }

    var body: some View {
        SceneView(scene: scene, options: [.allowsCameraControl])
            .background(Color(nsColor: .windowBackgroundColor))
            .onChange(of: mass) { _ in updateScene() }
            .onChange(of: speed) { _ in updateScene() }
    }

    private static func makeScene(mass: Double, speed: Double) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor.windowBackgroundColor

        let cartGeometry = SCNBox(width: 0.78, height: 0.46, length: 0.62, chamferRadius: 0.08)
        let cartMaterial = SCNMaterial()
        cartMaterial.diffuse.contents = NSColor.systemBlue
        cartMaterial.metalness.contents = 0.08
        cartMaterial.roughness.contents = 0.4
        cartGeometry.materials = [cartMaterial]
        let cart = SCNNode(geometry: cartGeometry)
        cart.name = "energy-cart"
        let wheelXPositions: [Float] = [-0.25, 0.25]
        let wheelZPositions: [Float] = [-0.34, 0.34]
        for x in wheelXPositions {
            for z in wheelZPositions {
                let wheel = SCNCylinder(radius: 0.12, height: 0.1)
                wheel.firstMaterial?.diffuse.contents = NSColor.darkGray
                let wheelNode = SCNNode(geometry: wheel)
                wheelNode.eulerAngles.x = .pi / 2
                wheelNode.position = SCNVector3(x, -0.26, z)
                cart.addChildNode(wheelNode)
            }
        }
        scene.rootNode.addChildNode(cart)

        let track = SCNBox(width: 3.8, height: 0.07, length: 1.8, chamferRadius: 0.02)
        track.firstMaterial?.diffuse.contents = NSColor.tertiaryLabelColor
        let trackNode = SCNNode(geometry: track)
        trackNode.position = SCNVector3(0, -0.08, 0)
        scene.rootNode.addChildNode(trackNode)

        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 46
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(2.7, 1.9, 4.8)
        cameraNode.look(at: SCNVector3(0, 0.25, 0))
        scene.rootNode.addChildNode(cameraNode)

        let light = SCNLight()
        light.type = .omni
        light.intensity = 850
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0, 4, 4)
        scene.rootNode.addChildNode(lightNode)

        update(scene: scene, mass: mass, speed: speed)
        return scene
    }

    private func updateScene() {
        Self.update(scene: scene, mass: mass, speed: speed)
    }

    private static func update(scene: SCNScene, mass: Double, speed: Double) {
        guard let cart = scene.rootNode.childNode(withName: "energy-cart", recursively: false) else { return }
        let scale = Float(0.82 + mass * 0.035)
        let start = SCNVector3(-1.15, 0.23 * scale, 0)
        cart.removeAction(forKey: "motion")
        cart.scale = SCNVector3(scale, scale, scale)
        cart.position = start

        guard speed > 0 else { return }
        let finish = SCNVector3(1.15, 0.23 * scale, 0)
        let travel = SCNAction.move(to: finish, duration: max(0.12, 2.3 / speed))
        let reset = SCNAction.run { node in node.position = start }
        cart.runAction(.repeatForever(.sequence([travel, reset])), forKey: "motion")
    }
}

private struct PunnettLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var selectedCross = 0

    private var parentGenotypes: (String, String) {
        switch selectedCross {
        case 1: return ("Aa", "aa")
        case 2: return ("AA", "aa")
        default: return ("Aa", "Aa")
        }
    }

    private var firstParentGametes: [String] { parentGenotypes.0.map { String($0) } }
    private var secondParentGametes: [String] { parentGenotypes.1.map { String($0) } }

    private var genotypeCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for secondGamete in secondParentGametes {
            for firstGamete in firstParentGametes {
                counts[offspringGenotype(firstGamete, secondGamete), default: 0] += 1
            }
        }
        return counts
    }

    private var probabilitySummary: String {
        genotypeCounts.keys.sorted().map { genotype in
            "\(genotype): \(genotypeCounts[genotype, default: 0] * 25)%"
        }.joined(separator: " · ")
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.geneticsHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)

            Picker(L10n.text("lab.geneticsCross", store.language), selection: $selectedCross) {
                Text(L10n.text("lab.geneticsCross0", store.language)).tag(0)
                Text(L10n.text("lab.geneticsCross1", store.language)).tag(1)
                Text(L10n.text("lab.geneticsCross2", store.language)).tag(2)
            }
            .pickerStyle(.menu)

            HStack(alignment: .top, spacing: 18) {
                Text("\(L10n.text("lab.geneticsParent1", store.language)): \(parentGenotypes.0)")
                Text("\(L10n.text("lab.geneticsParent2", store.language)): \(parentGenotypes.1)")
            }
            .font(.callout.monospacedDigit().weight(.medium))

            VStack(spacing: 7) {
                HStack(spacing: 7) {
                    Color.clear.frame(width: 54, height: 34)
                    ForEach(firstParentGametes.indices, id: \.self) { column in
                        Text(firstParentGametes[column])
                            .font(.headline.monospaced())
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                ForEach(secondParentGametes.indices, id: \.self) { row in
                    HStack(spacing: 7) {
                        Text(secondParentGametes[row])
                            .font(.headline.monospaced())
                            .frame(width: 54, height: 54)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        ForEach(firstParentGametes.indices, id: \.self) { column in
                            let genotype = offspringGenotype(
                                firstParentGametes[column],
                                secondParentGametes[row]
                            )
                            Text(genotype)
                                .font(.title3.monospaced().weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(Color.indigo.opacity(0.11), in: RoundedRectangle(cornerRadius: 8))
                                .accessibilityLabel(Text(
                                    "\(L10n.text("lab.geneticsOffspring", store.language)): \(genotype)"
                                ))
                        }
                    }
                }
            }

            LabeledContent(L10n.text("lab.geneticsOutcomes", store.language)) {
                Text(probabilitySummary)
                    .font(.callout.monospacedDigit().weight(.medium))
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func offspringGenotype(_ firstAllele: String, _ secondAllele: String) -> String {
        String((Array(firstAllele + secondAllele)).sorted { first, second in
            if first.isUppercase != second.isUppercase { return first.isUppercase }
            return first < second
        })
    }
}

private struct CellLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var selected = "mitochondria"
    private let parts = ["nucleus", "membrane", "mitochondria"]

    var body: some View {
        LabCard {
            HStack(spacing: 18) {
                ZStack {
                    Ellipse().fill(.green.opacity(0.12)).overlay(Ellipse().stroke(.green.opacity(0.5), lineWidth: 2))
                    Circle().fill(.purple.opacity(0.6)).frame(width: 36, height: 36)
                    Capsule().fill(.orange.opacity(0.8)).frame(width: 35, height: 14).rotationEffect(.degrees(-30)).offset(x: 34, y: 24)
                    Capsule().fill(.orange.opacity(0.8)).frame(width: 30, height: 12).rotationEffect(.degrees(30)).offset(x: -36, y: -20)
                    Text("DNA").font(.system(size: 8, weight: .bold)).foregroundStyle(.white)
                }
                .frame(width: 140, height: 100)
                .accessibilityLabel(Text(L10n.text("lab.cellDiagram", store.language)))
                VStack(alignment: .leading, spacing: 8) {
                    Picker(selection: $selected, label: Text(L10n.text("lab.cellPart", store.language))) {
                        ForEach(parts, id: \.self) { part in
                            Text(L10n.text("biology.\(part)", store.language)).tag(part)
                        }
                    }
                    .labelsHidden()
                    Text(L10n.text("lab.function", store.language))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(L10n.text("biology.\(selected).function", store.language))
                        .font(.callout)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct AdaptationLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var animal = "penguin"

    var body: some View {
        LabCard {
            HStack(spacing: 18) {
                Image(systemName: animal == "penguin" ? "bird.fill" : "sun.max.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(animal == "penguin" ? .blue : .orange)
                    .frame(width: 82, height: 82)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 8) {
                    Picker(selection: $animal, label: Text(L10n.text("lab.animal", store.language))) {
                        Text(L10n.text("zoology.penguin", store.language)).tag("penguin")
                        Text(L10n.text("zoology.camel", store.language)).tag("camel")
                    }
                    .labelsHidden()
                    Text(L10n.text("lab.adaptation", store.language))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(L10n.text("zoology.\(animal).feature", store.language))
                        .font(.callout)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct ConditionalLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var score = 7.0

    var body: some View {
        LabCard {
            Text("if score >= 5:")
                .font(.system(.body, design: .monospaced).weight(.semibold))
            HStack {
                Text(L10n.text("lab.score", store.language))
                Spacer()
                Text("score = \(score, specifier: "%.0f")")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $score, in: 0...10, step: 1)
            Label { Text(L10n.text(score >= 5 ? "lab.pass" : "lab.fail", store.language)) } icon: { Image(systemName: score >= 5 ? "checkmark.circle.fill" : "xmark.circle.fill") }
            .foregroundStyle(score >= 5 ? Color.green : Color.orange)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}


private struct TutorChatView: View {
    @EnvironmentObject private var store: LearningStore
    @EnvironmentObject private var backendSupervisor: LocalBackendSupervisor
    @StateObject private var chat: TutorChatModel
    @State private var draft = ""
    @State private var useWebSearch = false
    @State private var includeLocalSourcesInWebSearch = false
    @State private var hasConfirmedGoogleSearchAge = false
    @State private var showGoogleSearchAgeConfirmation = false
    let language: AppLanguage

    init(subject: Subject, lesson: LessonContent, language: AppLanguage, mode: AIRoutingMode) {
        self.language = language
        _chat = StateObject(wrappedValue: TutorChatModel(subject: subject, lesson: lesson, language: language, mode: mode))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("tutor.title", language)).font(.title2.weight(.semibold))
                    Text(L10n.text("tutor.subtitle", language)).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if store.isCheckingAI && store.aiHealth == nil {
                    ProgressView().controlSize(.small)
                } else if let health = store.aiHealth {
                    VStack(alignment: .trailing, spacing: 4) {
                        Label(L10n.text("settings.aiConnected", language), systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(.green)
                        Text(routeDescription(for: health))
                            .font(.caption2).foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    Label(L10n.text("settings.aiOffline", language), systemImage: "wifi.slash")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(20)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if chat.messages.isEmpty {
                            Text(L10n.text("tutor.empty", language))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 220)
                        }
                        ForEach(chat.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                        if let error = chat.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.callout).foregroundStyle(.orange)
                        }
                    }
                    .padding(20)
                }
                .onChange(of: chat.messages.count) { _ in
                    if let last = chat.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
                .onChange(of: chat.messages.last?.text) { _ in
                    if let last = chat.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text(chat.mode == .localOnly ? "tutor.localPrivacy" : "tutor.privacy", language))
                    .font(.caption).foregroundStyle(.secondary)
                if chat.mode == .automatic {
                    Toggle(isOn: Binding(
                        get: { useWebSearch },
                        set: { enabled in
                            guard enabled else {
                                useWebSearch = false
                                includeLocalSourcesInWebSearch = false
                                return
                            }
                            if hasConfirmedGoogleSearchAge {
                                useWebSearch = true
                            } else {
                                showGoogleSearchAgeConfirmation = true
                            }
                        }
                    )) {
                        Label(L10n.text("tutor.webSearchToggle", language), systemImage: "globe")
                    }
                    .toggleStyle(.checkbox)
                    .disabled(chat.isSending)
                    .alert(L10n.text("tutor.webSearchAgeTitle", language), isPresented: $showGoogleSearchAgeConfirmation) {
                        Button(L10n.text("tutor.webSearchCancel", language), role: .cancel) {}
                        Button(L10n.text("tutor.webSearchAgeConfirm", language)) {
                            hasConfirmedGoogleSearchAge = true
                            useWebSearch = true
                        }
                    } message: {
                        Text(L10n.text("tutor.webSearchAgeMessage", language))
                    }
                    if useWebSearch {
                        Toggle(isOn: $includeLocalSourcesInWebSearch) {
                            Label(L10n.text("tutor.webSearchIncludeLocalSources", language), systemImage: "folder")
                        }
                        .toggleStyle(.checkbox)
                        .disabled(chat.isSending)
                        Text(L10n.text(
                            includeLocalSourcesInWebSearch
                                ? "tutor.webSearchPrivacyWithLocalSources"
                                : "tutor.webSearchPrivacy",
                            language
                        ))
                            .font(.caption2).foregroundStyle(.secondary)
                        if store.aiHealth?.geminiKeyConfigured != true {
                            Label(L10n.text("tutor.webSearchNeedsGeminiKey", language), systemImage: "exclamationmark.triangle.fill")
                                .font(.caption).foregroundStyle(.orange)
                        } else if store.aiHealth?.hasGroundedSearch != true {
                            Label(L10n.text("tutor.webSearchUnavailable", language), systemImage: "exclamationmark.triangle.fill")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                } else {
                    Label(L10n.text("tutor.webSearchAutoOnly", language), systemImage: "wifi.slash")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                if store.aiHealth == nil {
                    Text(L10n.text("tutor.unavailable", language))
                        .font(.caption.monospaced()).foregroundStyle(.secondary)
                } else if chat.mode == .localOnly && store.aiHealth?.hasLocalModel != true {
                    let key = store.aiHealth?.isOllamaEndpointLocal == true
                        ? "tutor.localUnavailable"
                        : "tutor.localEndpointBlocked"
                    Text(L10n.text(key, language))
                        .font(.caption).foregroundStyle(.orange)
                }
                HStack(alignment: .bottom, spacing: 10) {
                    TextField(L10n.text("tutor.placeholder", language), text: $draft, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .onSubmit(send)
                        .disabled(chat.isSending || !canSend)
                    if chat.isSending {
                        Button(action: chat.cancel) {
                            Label(L10n.text("tutor.stop", language), systemImage: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button(action: send) {
                            Label(L10n.text("tutor.send", language), systemImage: "arrow.up.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !canSend)
                    }
                }
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .task {
            guard await backendSupervisor.ensureRunning() else { return }
            await store.refreshAIStatus()
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: TutorMessage) -> some View {
        HStack {
            if message.role == .learner { Spacer(minLength: 50) }
            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text(message.role == .learner ? "tutor.learner" : "tutor.assistant", language))
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                if message.isGoogleGrounded {
                    Text((try? AttributedString(markdown: message.text)) ?? AttributedString(message.text))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(message.text.isEmpty && chat.isSending ? "…" : message.text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if message.role == .tutor, !message.isGoogleGrounded,
                   let label = chat.completionLabel, message.id == chat.messages.last?.id {
                    Text(label).font(.caption2).foregroundStyle(.tertiary)
                }
                if message.role == .tutor, !message.citationWarnings.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Label(
                            String(
                                format: L10n.text("tutor.missingCitation", language),
                                message.citationWarnings.joined(separator: ", ")
                            ),
                            systemImage: "exclamationmark.triangle"
                        )
                        Text(L10n.text("tutor.citationValidationLimit", language))
                    }
                    .font(.caption2)
                    .foregroundStyle(.orange)
                }
                if message.role == .tutor,
                   message.isGoogleGrounded,
                   let suggestions = message.googleSearchSuggestions {
                    GoogleSearchSuggestionsView(html: suggestions)
                        .frame(height: 54)
                        .accessibilityLabel(L10n.text("tutor.googleSearchSuggestions", language))
                }
                if message.role == .tutor, let source = message.sources.first {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(L10n.text("tutor.sources", language), systemImage: "books.vertical")
                            .font(.caption.weight(.semibold))
                        Text("\(L10n.text("tutor.retrievedAt", language)): \(source.displayRetrievedAt)")
                            .font(.caption2).foregroundStyle(.secondary)
                        ForEach(message.sources) { item in
                            VStack(alignment: .leading, spacing: 3) {
                                if item.sourceType == "google_grounding",
                                   let path = item.path,
                                   let url = URL(string: path),
                                   ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                                    Link("[\(item.id)] \(item.title)", destination: url)
                                        .font(.caption.weight(.medium))
                                } else {
                                    Text("[\(item.id)] \(item.title)")
                                        .font(.caption.weight(.medium))
                                        .textSelection(.enabled)
                                }
                                if let path = item.path, path != item.title, item.sourceType != "google_grounding" {
                                    Text(path)
                                        .font(.caption2).foregroundStyle(.tertiary)
                                        .textSelection(.enabled)
                                }
                                if let location = item.location {
                                    Text("\(L10n.text("tutor.location", language)): \(location)")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                if let modifiedAt = item.displayModifiedAt {
                                    Text("\(L10n.text("tutor.fileModifiedAt", language)): \(modifiedAt)")
                                        .font(.caption2).foregroundStyle(.secondary)
                                } else if item.sourceType == "obsidian" {
                                    Text(L10n.text("tutor.modifiedDateUnavailable", language))
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                if let sourceCheckedAt = item.sourceCheckedAt {
                                    Text("\(L10n.text("tutor.sourceReviewDate", language)): \(sourceCheckedAt)")
                                        .font(.caption2).foregroundStyle(.secondary)
                                    Text(L10n.text("tutor.sourceCheckCaveat", language))
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                if let intervalDays = item.sourceReviewIntervalDays {
                                    Text("\(L10n.text("tutor.sourceReviewInterval", language)): \(intervalDays)")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                if let dueOn = item.sourceReviewDueOn {
                                    let isDue = item.sourceReviewStatus == "due"
                                    Text("\(L10n.text(isDue ? "tutor.sourceReviewDue" : "tutor.sourceReviewNext", language)): \(dueOn)")
                                        .font(.caption2)
                                        .foregroundStyle(isDue ? Color.orange : Color.secondary)
                                    Text(L10n.text("tutor.sourceReviewScheduleCaveat", language))
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                if !item.excerpt.isEmpty {
                                    Text(item.excerpt)
                                        .font(.caption2).foregroundStyle(.secondary)
                                        .lineLimit(4)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                    .padding(9)
                    .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
                }
            }
            .padding(12)
            .background(message.role == .learner ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
            if message.role == .tutor { Spacer(minLength: 50) }
        }
    }

    private var canSend: Bool {
        guard backendSupervisor.isReady, let health = store.aiHealth else { return false }
        if useWebSearch { return chat.mode == .automatic && health.hasGroundedSearch }
        return chat.mode == .automatic ? health.hasAutomaticRoute : health.hasLocalModel
    }

    private func routeDescription(for health: OrchestratorHealth) -> String {
        if store.aiMode == .localOnly {
            return L10n.text(health.hasLocalModel ? "settings.aiLocalRoute" : "settings.aiNoLocal", language)
        }
        if health.hasCloudSession { return L10n.text("settings.aiOnlineRoute", language) }
        if health.hasLocalModel { return L10n.text("settings.aiLocalRoute", language) }
        return L10n.text("settings.aiNoRoute", language)
    }

    private func send() {
        guard canSend, !chat.isSending else { return }
        let message = draft
        Task {
            guard await backendSupervisor.ensureRunning() else { return }
            await store.refreshAIStatus()
            guard canSend, !chat.isSending else { return }
            draft = ""
            chat.send(
                message,
                useWebSearch: useWebSearch,
                groundingAgeConfirmed: hasConfirmedGoogleSearchAge,
                includeLocalSourcesInWebSearch: includeLocalSourcesInWebSearch
            )
        }
    }
}

private struct GoogleSearchSuggestionsView: NSViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.underPageBackgroundColor = .clear
        view.navigationDelegate = context.coordinator
        context.coordinator.load(html, into: view)
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        context.coordinator.load(html, into: view)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private var loadedHTML: String?

        func load(_ html: String, into view: WKWebView) {
            guard loadedHTML != html else { return }
            loadedHTML = html
            view.loadHTMLString(html, baseURL: nil)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated else {
                decisionHandler(.allow)
                return
            }
            guard let url = navigationAction.request.url,
                  ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
                decisionHandler(.cancel)
                return
            }
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}
