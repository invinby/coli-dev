import Foundation
import Combine
import SwiftUI
import AppKit
import SceneKit
import WebKit
import UniformTypeIdentifiers

struct SubjectOverviewView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var levels: [CurriculumLevel] = []
    @State private var showingCustomTopicEditor = false
    @State private var customTopicParentID: UUID?
    @State private var pendingCustomTopicID: UUID?
    @State private var showingCustomTopicDelete = false

    let subject: Subject
    let openCourseLesson: (String) -> Void
    let openCustomTopic: (UUID) -> Void
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

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(L10n.text("custom.myTopics", store.language)).font(.title2.weight(.semibold))
                        Spacer()
                        Button {
                            customTopicParentID = nil
                            showingCustomTopicEditor = true
                        } label: {
                            Label(L10n.text("custom.addTopic", store.language), systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                    }
                    if store.customCurriculum.topics(builtInSubjectID: subject.rawValue).isEmpty {
                        Text(L10n.text("custom.addToBuiltInHint", store.language))
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        ForEach(store.customCurriculum.topics(builtInSubjectID: subject.rawValue)) { topic in
                            CustomTopicBranch(
                                topic: topic,
                                language: store.language,
                                open: { openCustomTopic($0) },
                                addChild: { customTopicParentID = $0; showingCustomTopicEditor = true },
                                delete: { pendingCustomTopicID = $0; showingCustomTopicDelete = true }
                            )
                        }
                    }
                }
                .padding(18)
                .background(subject.tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 32)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(Text(subject.title(in: store.language)))
        .onAppear { levels = CurriculumCatalog.roadmap(for: subject) }
        .sheet(isPresented: $showingCustomTopicEditor) {
            CustomTopicEditor(builtInSubject: subject, parentTopicID: customTopicParentID) {}
                .environmentObject(store)
        }
        .confirmationDialog(
            L10n.text("custom.deleteTopic", store.language),
            isPresented: $showingCustomTopicDelete,
            titleVisibility: .visible
        ) {
            Button(L10n.text("custom.deleteTopic", store.language), role: .destructive) {
                if let pendingCustomTopicID {
                    store.removeCustomTopic(builtInSubject: subject, topicID: pendingCustomTopicID)
                }
                pendingCustomTopicID = nil
            }
            Button(L10n.text("common.cancel", store.language), role: .cancel) { pendingCustomTopicID = nil }
        } message: {
            Text(L10n.text("custom.confirmDeleteTopic", store.language))
        }
    }
}

private struct CurriculumLessonDocument {
    let title: String
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

    static func load(subject: Subject, resource: String, language: AppLanguage) -> CurriculumLessonDocument? {
        guard let raw = CurriculumCatalog.lessonMarkdown(for: subject, resource: resource) else { return nil }
        let sourceCheckedOn = raw.components(separatedBy: .newlines)
            .first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("source_checked:") })?
            .split(separator: ":", maxSplits: 1)
            .last
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) }
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
            sourceCheckedOn: sourceCheckedOn,
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
    @State private var reflection = ""
    @State private var recallQuality = 4
    @State private var checkAttempt: CurriculumCheckAttempt?
    @State private var sourceInventory: TrustedSourceInventory?
    @State private var sourceInventoryUnavailable = false
    @State private var isLoadingSourceInventory = false
    @State private var isExportingNotebookSource = false
    @State private var notebookExportDocument: NotebookLMSourceFile?
    @State private var notebookExportFilename = "ColiDev-lesson.md"
    @State private var notebookExportStatus: String?
    @State private var isSavingObsidianNote = false
    @State private var obsidianSaveStatus: String?

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

                    LessonSourceFreshnessCard(
                        inventory: sourceInventory,
                        unavailable: sourceInventoryUnavailable,
                        isLoading: isLoadingSourceInventory,
                        lessonPath: "02_Areas/\(subject.rawValue.capitalized)/lessons/\(resource).md",
                        authorCheckedOn: document.sourceCheckedOn,
                        language: store.language,
                        onRetry: { Task { await loadSourceInventory() } }
                    )

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
                            if let checkAttempt {
                                ForEach(Array(checkAttempt.choiceOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayedIndex, originalIndex in
                                    Button {
                                        selectCheckAnswer(displayedIndex: displayedIndex)
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: checkAttempt.selectedOriginalIndex == originalIndex
                                                ? "largecircle.fill.circle"
                                                : "circle")
                                            Text(document.checkOptions[originalIndex])
                                                .multilineTextAlignment(.leading)
                                            Spacer(minLength: 0)
                                        }
                                        .padding(11)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(.background, in: RoundedRectangle(cornerRadius: 11))
                                        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(.quaternary, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(checkAttempt.hasAnswered)
                                }

                                if checkAttempt.hasAnswered {
                                    let isCorrect = checkAttempt.isCorrect
                                    Label(
                                        L10n.text(isCorrect ? "module.correct" : "module.incorrect", store.language),
                                        systemImage: isCorrect ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                                    )
                                    .foregroundStyle(isCorrect ? Color.green : Color.orange)

                                    if !isCorrect {
                                        Text(String(
                                            format: L10n.text("module.correctOption", store.language),
                                            document.checkOptions[checkAttempt.answerOriginalIndex]
                                        ))
                                            .font(.callout.weight(.medium))
                                    }

                                    if !document.answer.isEmpty {
                                        Text((try? AttributedString(markdown: document.answer)) ?? AttributedString(document.answer))
                                            .textSelection(.enabled)
                                            .padding(.top, 2)
                                    } else {
                                        Text(L10n.text("module.explanationUnavailable", store.language))
                                            .font(.callout)
                                            .foregroundStyle(.orange)
                                    }

                                    if checkAttempt.canRetry {
                                        Button(action: retryKnowledgeCheck) {
                                            Label(L10n.text("module.tryAgain", store.language), systemImage: "arrow.counterclockwise")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            } else {
                                Label(L10n.text("module.quizUnavailable", store.language), systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        Label(L10n.text("module.quizUnavailable", store.language), systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }

                    if !document.limitations.isEmpty {
                        ModuleTextCard(title: L10n.text("session.limitations", store.language), text: document.limitations, tint: subject.tint)
                    }
                    if !document.sources.isEmpty {
                        ModuleTextCard(title: L10n.text("module.sources", store.language), text: document.sources, tint: subject.tint)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.text("module.obsidianTitle", store.language))
                            .font(.headline)
                        Button(action: saveLessonToObsidian) {
                            if isSavingObsidianNote {
                                Label(L10n.text("module.obsidianSaving", store.language), systemImage: "arrow.triangle.2.circlepath")
                            } else {
                                Label(L10n.text("module.obsidianSave", store.language), systemImage: "externaldrive.badge.plus")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isSavingObsidianNote
                                || store.providerSecretStatuses["obsidian"]?.configured != true
                                || store.aiHealth?.isObsidianEndpointLocal != true
                        )
                        Text(L10n.text("module.obsidianPrivacy", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let obsidianSaveStatus {
                            Text(obsidianSaveStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

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
                        StudyReflectionFields(
                            language: store.language,
                            reflection: $reflection,
                            learnerConfirmed: $learnerConfirmed
                        )
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
                            store.recordReview(
                                lessonID: lessonID,
                                quality: recallQuality,
                                reflection: reflection
                            )
                        } else {
                            store.markComplete(
                                lessonID: lessonID,
                                quality: recallQuality,
                                reflection: reflection
                            )
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
                            || checkAttempt?.canComplete != true
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
        .onChange(of: lessonID) { _ in loadDocument() }
        .task(id: lessonID) { await loadSourceInventory() }
        .onChange(of: store.language) { _ in loadDocument() }
        .onChange(of: store.studyProgress[lessonID]?.reflection) { savedReflection in
            if reflection.isEmpty, let savedReflection {
                reflection = savedReflection
            }
        }
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
        let loadedDocument = CurriculumLessonDocument.load(subject: subject, resource: resource, language: store.language)
        document = loadedDocument
        checkAttempt = loadedDocument.flatMap { lesson in
            guard let answerIndex = lesson.checkAnswerIndex else { return nil }
            return CurriculumCheckAttempt(optionCount: lesson.checkOptions.count, answerOriginalIndex: answerIndex)
        }
        learnerConfirmed = isComplete
        if reflection.isEmpty {
            reflection = store.studyProgress[lessonID]?.reflection ?? ""
        }
    }

    private func selectCheckAnswer(displayedIndex: Int) {
        guard var attempt = checkAttempt else { return }
        attempt.select(displayedIndex: displayedIndex)
        checkAttempt = attempt
    }

    private func retryKnowledgeCheck() {
        guard var attempt = checkAttempt else { return }
        attempt.retry()
        checkAttempt = attempt
    }

    @MainActor
    private func loadSourceInventory() async {
        isLoadingSourceInventory = true
        defer { isLoadingSourceInventory = false }
        sourceInventoryUnavailable = false
        do {
            sourceInventory = try await OrchestratorClient.trustedSourceInventory()
        } catch {
            sourceInventory = nil
            sourceInventoryUnavailable = true
        }
    }

    private func saveLessonToObsidian() {
        guard let document, !isSavingObsidianNote else { return }
        let timestampFormatter = DateFormatter()
        timestampFormatter.locale = Locale(identifier: "en_US_POSIX")
        timestampFormatter.timeZone = TimeZone.current
        timestampFormatter.dateFormat = "yyyyMMdd-HHmmssSSS"
        let timestamp = timestampFormatter.string(from: Date())
        let uniqueSuffix = String(UUID().uuidString.prefix(8)).lowercased()
        let path = "ColiDev/Lessons/\(subject.rawValue)/\(resource)-\(timestamp)-\(uniqueSuffix).md"
        let source = document.notebookSource(subject: subject, language: store.language)
        isSavingObsidianNote = true
        obsidianSaveStatus = nil

        Task { @MainActor in
            defer { isSavingObsidianNote = false }
            do {
                try await OrchestratorClient.saveObsidianNote(path: path, content: source)
                obsidianSaveStatus = String(
                    format: L10n.text("module.obsidianSaved", store.language),
                    path
                )
            } catch {
                obsidianSaveStatus = L10n.text("module.obsidianSaveFailed", store.language)
            }
        }
    }
}

private struct LessonSourceFreshnessCard: View {
    let inventory: TrustedSourceInventory?
    let unavailable: Bool
    let isLoading: Bool
    let lessonPath: String
    let authorCheckedOn: String?
    let language: AppLanguage
    let onRetry: () -> Void

    private var matchingSources: [TrustedSourceInventoryItem] {
        let target = lessonPath.lowercased()
        return (inventory?.sources ?? []).filter { source in
            (source.lessonPaths ?? [source.lessonPath]).contains { $0.lowercased() == target }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(L10n.text("module.sourceStatusTitle", language), systemImage: "checkmark.icloud")
                .font(.headline)

            if let authorCheckedOn {
                Text(String(format: L10n.text("module.sourceAuthorDate", language), authorCheckedOn))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(L10n.text("module.sourceAuthorDateMissing", language))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if unavailable {
                HStack {
                    Label(L10n.text("module.sourceMonitorUnavailable", language), systemImage: "wifi.slash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Button(action: onRetry) {
                        if isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Label(L10n.text("management.retry", language), systemImage: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(isLoading)
                }
            } else if inventory != nil, matchingSources.isEmpty {
                Label(L10n.text("module.sourceNotMonitored", language), systemImage: "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if inventory != nil {
                ForEach(matchingSources) { source in
                    VStack(alignment: .leading, spacing: 3) {
                        Label(
                            L10n.text(sourceStateKey(source.state), language),
                            systemImage: sourceStateSymbol(source.state)
                        )
                        .font(.caption.weight(.medium))
                        .foregroundStyle(sourceStateColor(source.state))

                        Text(source.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        if let checkedAt = source.contentCheckedAt ?? source.lastCheckedAt {
                            Text(String(format: L10n.text("module.sourceLastChecked", language), formatDate(checkedAt)))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        if let review = source.lessonReviews?.first(where: {
                            $0.lessonPath.lowercased() == lessonPath.lowercased()
                        }) {
                            Label(
                                L10n.text(editorialStatusKey(review.editorialReviewStatus), language),
                                systemImage: editorialStatusSymbol(review.editorialReviewStatus)
                            )
                            .font(.caption2)
                            .foregroundStyle(editorialStatusColor(review.editorialReviewStatus))
                        }
                    }
                    .padding(.top, 3)
                }
            } else if isLoading {
                ProgressView(L10n.text("module.sourceStatusLoading", language))
                    .controlSize(.small)
            }

            Text(L10n.text("module.sourceStatusCaveat", language))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.055), in: RoundedRectangle(cornerRadius: 14))
    }

    private func sourceStateKey(_ state: String) -> String {
        switch state {
        case "not_checked": return "management.sourceNotChecked"
        case "available_untracked": return "management.sourceAvailable"
        case "content_baseline": return "management.sourceContentBaseline"
        case "unchanged": return "management.sourceUnchanged"
        case "changed": return "management.sourceChanged"
        case "content_unavailable": return "management.sourceContentUnavailable"
        case "content_too_large": return "management.sourceContentTooLarge"
        case "unsupported_content_type": return "management.sourceUnsupportedContent"
        case "redirect_review": return "management.sourceRedirect"
        case "unexpected_not_modified": return "management.sourceUnexpected304"
        case "unavailable": return "management.sourceUnavailable"
        case "network_error": return "management.sourceNetworkError"
        default: return "management.sourceUnknown"
        }
    }

    private func sourceStateSymbol(_ state: String) -> String {
        switch state {
        case "changed", "content_baseline", "content_unavailable", "content_too_large",
             "unsupported_content_type", "redirect_review", "unexpected_not_modified",
             "unavailable", "network_error": return "exclamationmark.triangle.fill"
        case "unchanged": return "checkmark.circle"
        case "available_untracked": return "questionmark.circle"
        default: return "clock"
        }
    }

    private func sourceStateColor(_ state: String) -> Color {
        switch state {
        case "changed", "content_baseline", "content_unavailable", "content_too_large",
             "unsupported_content_type", "redirect_review", "unexpected_not_modified",
             "unavailable", "network_error": return .orange
        default: return .secondary
        }
    }

    private func editorialStatusKey(_ status: String) -> String {
        switch status {
        case "review_due": return "management.editorialReviewDue"
        case "review_scheduled": return "management.editorialReviewScheduled"
        case "review_missing": return "management.editorialReviewMissing"
        case "review_unscheduled": return "management.editorialReviewUnscheduled"
        default: return "management.editorialReviewUnknown"
        }
    }

    private func editorialStatusSymbol(_ status: String) -> String {
        status == "review_due" || status == "review_missing"
            ? "exclamationmark.circle.fill"
            : status == "review_scheduled" ? "calendar" : "calendar.badge.exclamationmark"
    }

    private func editorialStatusColor(_ status: String) -> Color {
        status == "review_due" || status == "review_missing" ? .orange : .secondary
    }

    private func formatDate(_ value: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: value) else { return value }
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
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
    @State private var optionOrder = AnswerChoiceOrder(optionCount: 3)
    @State private var learnerConfirmed = false
    @State private var reflection = ""
    @State private var showingTutor = false

    private var content: LessonContent {
        LearningCatalog.lesson(for: subject, language: store.language)
    }

    private var answerIsCorrect: Bool {
        guard let selectedAnswer else { return false }
        return optionOrder.isCorrect(
            displayedIndex: selectedAnswer,
            answerOriginalIndex: content.answerIndex
        )
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

                if answerIsCorrect || store.isComplete(subject) {
                    StudyReflectionFields(
                        language: store.language,
                        reflection: $reflection,
                        learnerConfirmed: $learnerConfirmed
                    )
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

                    Button {
                        if store.isComplete(subject) {
                            store.recordReview(for: subject, reflection: reflection)
                        } else {
                            store.markComplete(subject, reflection: reflection)
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
        .onAppear {
            learnerConfirmed = store.isComplete(subject)
            reflection = store.studyProgress[subject.lessonID]?.reflection ?? ""
        }
        .onChange(of: store.studyProgress[subject.lessonID]?.reflection) { savedReflection in
            if reflection.isEmpty, let savedReflection {
                reflection = savedReflection
            }
        }
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
            ForEach(Array(optionOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                Button {
                    selectedAnswer = displayIndex
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedAnswer == displayIndex ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selectedAnswer == displayIndex ? subject.tint : Color.secondary)
                        Text(content.options[originalIndex])
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

private struct StudyReflectionFields: View {
    let language: AppLanguage
    @Binding var reflection: String
    @Binding var learnerConfirmed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("session.listen", language))
                .font(.headline)
            TextField(L10n.text("session.reflectionPlaceholder", language), text: $reflection, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
                .onChange(of: reflection) { value in
                    if value.unicodeScalars.count > 500 {
                        reflection = String(String.UnicodeScalarView(value.unicodeScalars.prefix(500)))
                    }
                }
            Text(L10n.text("session.reflectionPrivacy", language))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Toggle(L10n.text("session.doneCheck", language), isOn: $learnerConfirmed)
                .toggleStyle(.checkbox)
        }
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
        if subject == .mathematics, moduleResource == "solving_linear_equations" {
            LinearEquationLab()
        } else if subject == .mathematics, moduleResource == "systems_of_linear_equations" {
            LinearSystemLab()
        } else if subject == .mathematics, moduleResource == "rational_expressions_and_restrictions" {
            RationalExpressionLab()
        } else if subject == .mathematics, moduleResource == "geometry_area_perimeter" {
            GeometryMeasureLab()
        } else if subject == .mathematics, moduleResource == "numbers_fractions_and_percentages" {
            PercentRepresentationLab()
        } else if subject == .mathematics, moduleResource == "domain_and_range" {
            DomainRangeLab()
        } else if subject == .mathematics, moduleResource == "rates_of_change_and_derivative" {
            DerivativeRateLab()
        } else if subject == .english, moduleResource == "present_simple_and_continuous" {
            TenseContrastLab()
        } else if subject == .english, moduleResource == "present_perfect_simple_continuous" {
            PresentPerfectAspectLab()
        } else if subject == .english, moduleResource == "zero_first_second_conditionals" {
            ConditionalsLab()
        } else if subject == .english, moduleResource == "daily_routines_and_collocations" {
            DailyRoutineVocabularyLab()
        } else if subject == .english, moduleResource == "reading_for_gist_and_detail" {
            ReadingStrategyLab()
        } else if subject == .zoology, moduleResource == "animals_as_a_group" {
            AnimalGroupLab()
        } else if subject == .zoology, moduleResource == "major_animal_lineages" {
            AnimalLineageLab()
        } else if subject == .biology, moduleResource == "passive_transport_osmosis" {
            OsmosisLab()
        } else if subject == .biology, moduleResource == "mendelian_inheritance" {
            PunnettLab()
        } else if subject == .biology, moduleResource == "dna_genes_and_traits" {
            GeneRegulationLab()
        } else if subject == .biology, moduleResource == "gene_expression_and_regulation" {
            GeneExpressionLab()
        } else if subject == .biology, moduleResource == "photosynthesis_energy_and_carbon" {
            PhotosynthesisLab()
        } else if subject == .biology, moduleResource == "scientific_method_and_experiments" {
            BiologyInvestigationLab()
        } else if subject == .biology, moduleResource == "eukaryotic_cell_organelles" {
            EukaryoticCellLab()
        } else if subject == .biology, moduleResource == "biomolecules_and_building_blocks" {
            BiomoleculeLab()
        } else if subject == .biology, moduleResource == "natural_selection_and_population_change" {
            NaturalSelectionLab()
        } else if subject == .zoology, moduleResource == "animal_function_and_environment" {
            AnimalFunctionLab()
        } else if subject == .biology, moduleResource == "cell_cycle_and_differentiation" {
            CellCycleLab()
        } else if subject == .biology, moduleResource == "ecosystem_energy_flow" {
            EcosystemEnergyLab()
        } else if subject == .biology, moduleResource == "food_webs_and_matter_cycles" {
            FoodWebLab()
        } else if subject == .physics, moduleResource == "work_and_kinetic_energy" {
            KineticEnergyLab()
        } else if subject == .physics, moduleResource == "measurement_units_and_uncertainty" {
            LengthMeasurementLab()
        } else if subject == .physics, moduleResource == "static_and_kinetic_friction" {
            FrictionLab()
        } else if subject == .physics, moduleResource == "impulse_and_momentum" {
            MomentumCollisionLab()
        } else if subject == .physics, moduleResource == "elastic_collisions" {
            MomentumCollisionLab(initialMode: .elastic)
        } else if subject == .physics, moduleResource == "projectile_motion" {
            ProjectileMotionLab()
        } else if subject == .programming, moduleResource == "collections_and_loops" {
            CollectionsLoopsLab()
        } else if subject == .programming, moduleResource == "conditions_loops_functions" {
            LoopTraceLab()
        } else if subject == .programming, moduleResource == "strings_files_and_exceptions" {
            FileReadingLab()
        } else if subject == .programming, moduleResource == "debugging_tests_and_git" {
            DebuggingLab()
        } else if subject == .programming, moduleResource == "sql_transactions" {
            TransactionLab()
        } else if subject == .programming, moduleResource == "search_and_complexity" {
            AlgorithmComplexityLab()
        } else if subject == .programming, moduleResource == "variables_and_types" {
            VariablesTypesLab()
        } else if subject == .programming, moduleResource == "computational_thinking" {
            AlgorithmicThinkingLab()
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
            if moduleResource == "animals_as_a_group" {
                AnimalGroupLab()
            } else if moduleResource == "symmetry_and_body_plans" {
                SymmetryLab()
            } else {
                AdaptationLab()
            }
        case .programming:
            ConditionalLab()
            }
        }
    }
}

private struct RoutineVocabularyQuestion {
    let promptKey: String
    let optionKeys: [String]
    let answerIndex: Int
}

private struct ReadingStrategyLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var index = 0
    @State private var selection: Int?
    @State private var wasCorrect: Bool?
    @State private var complete = false
    @State private var optionOrders = EnglishReadingPractice.questions.map {
        QuizAnswerOrder(optionCount: 3, answerOriginalIndex: $0.correctOption)
    }

    private let questions = [
        ConditionalPracticeQuestion(id: EnglishReadingPractice.questions[0].id, promptKey: "lab.readingQuestion0", feedbackKey: "lab.readingFeedback0"),
        ConditionalPracticeQuestion(id: EnglishReadingPractice.questions[1].id, promptKey: "lab.readingQuestion1", feedbackKey: "lab.readingFeedback1"),
        ConditionalPracticeQuestion(id: EnglishReadingPractice.questions[2].id, promptKey: "lab.readingQuestion2", feedbackKey: "lab.readingFeedback2")
    ]

    var body: some View {
        LabCard {
            Text(L10n.text("lab.readingHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if complete {
                Label(L10n.text("lab.readingComplete", store.language), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .fixedSize(horizontal: false, vertical: true)
                Button(L10n.text("lab.readingRestart", store.language), systemImage: "arrow.counterclockwise") {
                    reset()
                }
                .buttonStyle(.bordered)
            } else {
                Text(String(format: L10n.text("lab.readingProgress", store.language), index + 1, questions.count))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(index + 1), total: Double(questions.count))
                Text(L10n.text(questions[index].promptKey, store.language))
                    .font(.title3.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(optionOrders[index].displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Button {
                        selection = displayIndex
                        wasCorrect = nil
                    } label: {
                        Label(
                            L10n.text("lab.readingOption\(index * 3 + originalIndex)", store.language),
                            systemImage: selection == displayIndex ? "checkmark.circle.fill" : "circle"
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(selection == displayIndex ? .accentColor : .secondary)
                    .accessibilityAddTraits(selection == displayIndex ? .isSelected : [])
                }

                if let wasCorrect {
                    Label(
                        wasCorrect
                            ? L10n.text(questions[index].feedbackKey, store.language)
                            : L10n.text("lab.readingTryAgain", store.language),
                        systemImage: wasCorrect ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath"
                    )
                    .foregroundStyle(wasCorrect ? Color.green : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    if wasCorrect == true {
                        if index == questions.count - 1 {
                            complete = true
                        } else {
                            index += 1
                            selection = nil
                            wasCorrect = nil
                        }
                    } else if let selection {
                        wasCorrect = optionOrders[index].isCorrect(displayedIndex: selection)
                    }
                } label: {
                    Text(L10n.text(
                        wasCorrect == true
                            ? (index == questions.count - 1 ? "lab.readingFinish" : "lab.readingNext")
                            : "lab.readingCheck",
                        store.language
                    ))
                }
                .buttonStyle(.borderedProminent)
                .disabled(selection == nil && wasCorrect != true)
            }
        }
    }

    private func reset() {
        index = 0
        selection = nil
        wasCorrect = nil
        complete = false
        optionOrders = EnglishReadingPractice.questions.map {
            QuizAnswerOrder(optionCount: 3, answerOriginalIndex: $0.correctOption)
        }
    }
}

private struct DailyRoutineVocabularyLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var questionIndex = 0
    @State private var selectedOption: Int?
    @State private var lastWasCorrect: Bool?
    @State private var isComplete = false
    @State private var optionOrders: [[Int]] = (0..<5).map { _ in Array(0..<3).shuffled() }

    private let questions = [
        RoutineVocabularyQuestion(
            promptKey: "lab.routinePrompt1",
            optionKeys: ["lab.routineGoToBed", "lab.routineHaveBreakfast", "lab.routineHaveDinner"],
            answerIndex: 1
        ),
        RoutineVocabularyQuestion(
            promptKey: "lab.routinePrompt2",
            optionKeys: ["lab.routineHaveDinner", "lab.routineWakeUp", "lab.routineGoToBed"],
            answerIndex: 1
        ),
        RoutineVocabularyQuestion(
            promptKey: "lab.routinePrompt3",
            optionKeys: ["lab.routineHaveLunch", "lab.routineGoToBed", "lab.routineGetDressed"],
            answerIndex: 2
        ),
        RoutineVocabularyQuestion(
            promptKey: "lab.routinePrompt4",
            optionKeys: ["lab.routineHaveBreakfast", "lab.routineWakeUp", "lab.routineHaveLunch"],
            answerIndex: 2
        ),
        RoutineVocabularyQuestion(
            promptKey: "lab.routinePrompt5",
            optionKeys: ["lab.routineWakeUp", "lab.routineGoToBed", "lab.routineGetDressed"],
            answerIndex: 1
        )
    ]

    private var currentQuestion: RoutineVocabularyQuestion { questions[questionIndex] }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.routineHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if isComplete {
                Label(L10n.text("lab.routineComplete", store.language), systemImage: "checkmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.green)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    reset()
                } label: {
                    Label(L10n.text("lab.routineRestart", store.language), systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            } else {
                Text(String(format: L10n.text("lab.routineProgress", store.language), questionIndex + 1, questions.count))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(questionIndex + 1), total: Double(questions.count))
                Text(L10n.text(currentQuestion.promptKey, store.language))
                    .font(.title3.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(optionOrders[questionIndex].enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Button {
                        selectedOption = displayIndex
                        lastWasCorrect = nil
                    } label: {
                        Label(
                            L10n.text(currentQuestion.optionKeys[originalIndex], store.language),
                            systemImage: selectedOption == displayIndex ? "checkmark.circle.fill" : "circle"
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedOption == displayIndex ? .accentColor : .secondary)
                    .accessibilityAddTraits(selectedOption == displayIndex ? .isSelected : [])
                }

                if let lastWasCorrect {
                    Label(
                        L10n.text(lastWasCorrect ? "lab.routineCorrect" : "lab.routineIncorrect", store.language),
                        systemImage: lastWasCorrect ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath"
                    )
                    .font(.callout)
                    .foregroundStyle(lastWasCorrect ? Color.green : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    advanceOrCheck()
                } label: {
                    Text(checkButtonTitle)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedOption == nil && lastWasCorrect != true)
            }
        }
    }

    private var checkButtonTitle: String {
        guard lastWasCorrect == true else { return L10n.text("lab.routineCheck", store.language) }
        return questionIndex == questions.count - 1
            ? L10n.text("lab.routineFinish", store.language)
            : L10n.text("lab.routineNext", store.language)
    }

    private func advanceOrCheck() {
        if lastWasCorrect == true {
            guard questionIndex < questions.count - 1 else {
                isComplete = true
                return
            }
            questionIndex += 1
            selectedOption = nil
            lastWasCorrect = nil
            return
        }

        guard let selectedOption else { return }
        lastWasCorrect = optionOrders[questionIndex][selectedOption] == currentQuestion.answerIndex
    }

    private func reset() {
        questionIndex = 0
        selectedOption = nil
        lastWasCorrect = nil
        isComplete = false
        optionOrders = questions.map { Array($0.optionKeys.indices).shuffled() }
    }
}

private struct AnimalGroupQuestion {
    let promptKey: String
    let options: [String]
    let answerIndex: Int
}

private struct AnimalGroupLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var index = 0
    @State private var selection: Int?
    @State private var wasCorrect: Bool?
    @State private var complete = false
    @State private var optionOrders: [[Int]] = (0..<4).map { _ in Array(0..<3).shuffled() }

    private let questions = [
        AnimalGroupQuestion(promptKey: "lab.animalGroupQ1", options: ["lab.animalGroupQ1A", "lab.animalGroupQ1B", "lab.animalGroupQ1C"], answerIndex: 0),
        AnimalGroupQuestion(promptKey: "lab.animalGroupQ2", options: ["lab.animalGroupQ2A", "lab.animalGroupQ2B", "lab.animalGroupQ2C"], answerIndex: 1),
        AnimalGroupQuestion(promptKey: "lab.animalGroupQ3", options: ["lab.animalGroupQ3A", "lab.animalGroupQ3B", "lab.animalGroupQ3C"], answerIndex: 2),
        AnimalGroupQuestion(promptKey: "lab.animalGroupQ4", options: ["lab.animalGroupQ4A", "lab.animalGroupQ4B", "lab.animalGroupQ4C"], answerIndex: 1)
    ]

    var body: some View {
        LabCard {
            Text(L10n.text("lab.animalGroupHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if complete {
                Label(L10n.text("lab.animalGroupComplete", store.language), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Button(L10n.text("lab.animalGroupRestart", store.language), systemImage: "arrow.counterclockwise") {
                    index = 0
                    selection = nil
                    wasCorrect = nil
                    complete = false
                    optionOrders = questions.map { Array($0.options.indices).shuffled() }
                }
                .buttonStyle(.bordered)
            } else {
                Text(String(format: L10n.text("lab.animalGroupProgress", store.language), index + 1, questions.count))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(index + 1), total: Double(questions.count))
                Text(L10n.text(questions[index].promptKey, store.language))
                    .font(.title3.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(optionOrders[index].enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Button {
                        selection = displayIndex
                        wasCorrect = nil
                    } label: {
                        Label(
                            L10n.text(questions[index].options[originalIndex], store.language),
                            systemImage: selection == displayIndex ? "checkmark.circle.fill" : "circle"
                        )
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(selection == displayIndex ? .accentColor : .secondary)
                    .accessibilityAddTraits(selection == displayIndex ? .isSelected : [])
                }

                if let wasCorrect {
                    Label(
                        L10n.text(wasCorrect ? "lab.animalGroupCorrect" : "lab.animalGroupTryAgain", store.language),
                        systemImage: wasCorrect ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath"
                    )
                    .foregroundStyle(wasCorrect ? Color.green : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    if wasCorrect == true {
                        if index == questions.count - 1 {
                            complete = true
                        } else {
                            index += 1
                            selection = nil
                            wasCorrect = nil
                        }
                    } else if let selection {
                        wasCorrect = optionOrders[index][selection] == questions[index].answerIndex
                    }
                } label: {
                    Text(L10n.text(wasCorrect == true ? (index == questions.count - 1 ? "lab.animalGroupFinish" : "lab.animalGroupNext") : "lab.animalGroupCheck", store.language))
                }
                .buttonStyle(.borderedProminent)
                .disabled(selection == nil && wasCorrect != true)
            }
        }
    }
}

private struct AnimalLineageLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var index = 0
    @State private var selection: Int?
    @State private var wasCorrect: Bool?
    @State private var complete = false
    @State private var optionOrders: [[Int]] = (0..<4).map { _ in Array(0..<3).shuffled() }

    private let questions = [
        AnimalGroupQuestion(promptKey: "lab.lineageQ1", options: ["lab.lineageQ1A", "lab.lineageQ1B", "lab.lineageQ1C"], answerIndex: 1),
        AnimalGroupQuestion(promptKey: "lab.lineageQ2", options: ["lab.lineageQ2A", "lab.lineageQ2B", "lab.lineageQ2C"], answerIndex: 0),
        AnimalGroupQuestion(promptKey: "lab.lineageQ3", options: ["lab.lineageQ3A", "lab.lineageQ3B", "lab.lineageQ3C"], answerIndex: 2),
        AnimalGroupQuestion(promptKey: "lab.lineageQ4", options: ["lab.lineageQ4A", "lab.lineageQ4B", "lab.lineageQ4C"], answerIndex: 1)
    ]

    var body: some View {
        LabCard {
            Text(L10n.text("lab.lineageHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                Label(L10n.text("lab.lineageBilateria", store.language), systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                Text(L10n.text("lab.lineageProtostomes", store.language))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .top, spacing: 12) {
                    lineageBranch(title: "lab.lineageEcdysozoa", members: "lab.lineageArthropodsNematodes")
                    lineageBranch(title: "lab.lineageLophotrochozoa", members: "lab.lineageAnnelidsMolluscs")
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)

            if complete {
                Label(L10n.text("lab.lineageComplete", store.language), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Button(L10n.text("lab.lineageRestart", store.language), systemImage: "arrow.counterclockwise") {
                    index = 0
                    selection = nil
                    wasCorrect = nil
                    complete = false
                    optionOrders = questions.map { Array($0.options.indices).shuffled() }
                }
                .buttonStyle(.bordered)
            } else {
                Text(String(format: L10n.text("lab.lineageProgress", store.language), index + 1, questions.count))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(index + 1), total: Double(questions.count))
                Text(L10n.text(questions[index].promptKey, store.language))
                    .font(.title3.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(optionOrders[index].enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Button {
                        selection = displayIndex
                        wasCorrect = nil
                    } label: {
                        Label(
                            L10n.text(questions[index].options[originalIndex], store.language),
                            systemImage: selection == displayIndex ? "checkmark.circle.fill" : "circle"
                        )
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(selection == displayIndex ? .accentColor : .secondary)
                    .accessibilityAddTraits(selection == displayIndex ? .isSelected : [])
                }

                if let wasCorrect {
                    Label(
                        L10n.text(wasCorrect ? "lab.lineageCorrect" : "lab.lineageTryAgain", store.language),
                        systemImage: wasCorrect ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath"
                    )
                    .foregroundStyle(wasCorrect ? Color.green : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    if wasCorrect == true {
                        if index == questions.count - 1 {
                            complete = true
                        } else {
                            index += 1
                            selection = nil
                            wasCorrect = nil
                        }
                    } else if let selection {
                        wasCorrect = optionOrders[index][selection] == questions[index].answerIndex
                    }
                } label: {
                    Text(L10n.text(wasCorrect == true ? (index == questions.count - 1 ? "lab.lineageFinish" : "lab.lineageNext") : "lab.lineageCheck", store.language))
                }
                .buttonStyle(.borderedProminent)
                .disabled(selection == nil && wasCorrect != true)
            }
        }
    }

    private func lineageBranch(title: String, members: String) -> some View {
        VStack(spacing: 8) {
            Text(L10n.text(title, store.language))
                .font(.callout.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(L10n.text(members, store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .padding(10)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }
}

private struct GeometryMeasureLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var shape = GeometryShape.rectangle
    @State private var base = 6.0
    @State private var height = 4.0

    private var measure: GeometryMeasure {
        GeometryMeasure(base: base, height: height, shape: shape)
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.geometryHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
            Picker(L10n.text("lab.geometryShape", store.language), selection: $shape) {
                Text(L10n.text("lab.geometryRectangle", store.language)).tag(GeometryShape.rectangle)
                Text(L10n.text("lab.geometryTriangle", store.language)).tag(GeometryShape.rightTriangle)
            }
            .pickerStyle(.segmented)

            Canvas { context, size in
                let inset: CGFloat = 24
                let availableWidth = max(size.width - 2 * inset, 0)
                let availableHeight = max(size.height - 2 * inset, 0)
                guard availableWidth > 0, availableHeight > 0 else { return }
                let scale = min(availableWidth / CGFloat(base), availableHeight / CGFloat(height))
                let width = CGFloat(base) * scale
                let drawnHeight = CGFloat(height) * scale
                let left = (size.width - width) / 2
                let bottom = size.height - (size.height - drawnHeight) / 2
                var path = Path()
                if shape == .rectangle {
                    path.addRect(CGRect(x: left, y: bottom - drawnHeight, width: width, height: drawnHeight))
                } else {
                    path.move(to: CGPoint(x: left, y: bottom))
                    path.addLine(to: CGPoint(x: left, y: bottom - drawnHeight))
                    path.addLine(to: CGPoint(x: left + width, y: bottom))
                    path.closeSubpath()
                    var rightAngle = Path()
                    let mark: CGFloat = min(12, scale * 0.2)
                    rightAngle.move(to: CGPoint(x: left, y: bottom - mark))
                    rightAngle.addLine(to: CGPoint(x: left + mark, y: bottom - mark))
                    rightAngle.addLine(to: CGPoint(x: left + mark, y: bottom))
                    context.stroke(rightAngle, with: .color(.secondary), lineWidth: 1.5)
                }
                context.fill(path, with: .color(Color.accentColor.opacity(0.18)))
                context.stroke(path, with: .color(.accentColor), lineWidth: 3)
            }
            .frame(height: 220)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(L10n.text("lab.geometryDiagram", store.language)))
            .accessibilityValue(Text("\(L10n.text(shape == .rectangle ? "lab.geometryRectangle" : "lab.geometryTriangle", store.language)); b = \(base, specifier: "%.1f") m; h = \(height, specifier: "%.1f") m"))

            HStack {
                Text("b = \(base, specifier: "%.1f") m")
                Spacer()
                Text("h = \(height, specifier: "%.1f") m")
            }
            .font(.callout.monospacedDigit())

            slider("lab.geometryBase", value: $base)
            slider("lab.geometryHeight", value: $height)

            HStack(spacing: 20) {
                metric("lab.geometryArea", value: measure.area, unit: "m²")
                metric("lab.geometryPerimeter", value: measure.perimeter, unit: "m")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(L10n.text("lab.geometryScaling", store.language))
                .font(.callout)
            Text(L10n.text("lab.geometryLimits", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func slider(_ key: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L10n.text(key, store.language))
                Spacer()
                Text("\(value.wrappedValue, specifier: "%.1f") m")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: 1...10, step: 0.5)
                .accessibilityLabel(Text(L10n.text(key, store.language)))
                .accessibilityValue(Text("\(value.wrappedValue, specifier: "%.1f") m"))
        }
    }

    private func metric(_ key: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.text(key, store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value, specifier: "%.2f") \(unit)")
                .font(.title3.monospacedDigit())
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PercentRepresentationLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var percent = 35.0
    @State private var whole = 240.0
    @State private var kilometres = 1.5

    private var representation: PercentRepresentation {
        PercentRepresentation(percent: Int(percent.rounded()))
    }

    private var formattedDecimal: String {
        let locale = Locale(identifier: store.language == .ru ? "ru_RU" : "en_US")
        return String(format: "%.2f", locale: locale, representation.decimal)
    }

    private var formattedKilometres: String {
        String(format: "%.1f", locale: Locale(identifier: store.language == .ru ? "ru_RU" : "en_US"), kilometres)
    }

    private var formattedMetres: String {
        String(format: "%.0f", locale: Locale(identifier: store.language == .ru ? "ru_RU" : "en_US"), KilometreConversion(kilometres: kilometres).metres)
    }

    var body: some View {
        LabCard {
            Label(L10n.text("lab.percent.title", store.language), systemImage: "chart.pie.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.orange)

            Text(L10n.text("lab.percent.help", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text("\(representation.percent)%")
                Text("=")
                Text(representation.fractionDescription)
                Text("=")
                Text(formattedDecimal)
            }
            .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.text("lab.percent.representations", store.language)
                .replacingOccurrences(of: "%1", with: "\(representation.percent)%")
                .replacingOccurrences(of: "%2", with: representation.fractionDescription)
                .replacingOccurrences(of: "%3", with: formattedDecimal))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L10n.text("lab.percent.share", store.language))
                    Spacer()
                    Text("\(representation.percent)%")
                        .monospacedDigit()
                }
                Slider(value: $percent, in: 0...100, step: 1)
                    .tint(.orange)
                    .accessibilityLabel(L10n.text("lab.percent.share", store.language))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.16))
                    Capsule()
                        .fill(Color.orange.gradient)
                        .frame(width: geometry.size.width * CGFloat(representation.decimal))
                }
            }
            .frame(height: 18)
            .accessibilityElement()
            .accessibilityLabel(L10n.text("lab.percent.bar", store.language)
                .replacingOccurrences(of: "%@", with: "\(representation.percent)%"))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L10n.text("lab.percent.whole", store.language))
                    Spacer()
                    Text("\(Int(whole))")
                        .monospacedDigit()
                }
                Slider(value: $whole, in: 100...1000, step: 50)
                    .tint(.orange)
                    .accessibilityLabel(L10n.text("lab.percent.whole", store.language))
            }

            Text(String(format: L10n.text("lab.percent.part", store.language), representation.part(of: Int(whole))))
                .font(.headline.monospacedDigit())
                .accessibilityElement(children: .combine)

            Divider()

            Text(L10n.text("lab.percent.unitsTitle", store.language))
                .font(.headline)

            HStack {
                Text(L10n.text("lab.percent.kilometres", store.language))
                Spacer()
                Text(formattedKilometres)
                    .monospacedDigit()
            }
            Slider(value: $kilometres, in: 0...10, step: 0.5)
                .tint(.teal)
                .accessibilityLabel(L10n.text("lab.percent.kilometres", store.language))

            Text(L10n.text("lab.percent.unitEquation", store.language)
                .replacingOccurrences(of: "%1", with: formattedKilometres)
                .replacingOccurrences(of: "%2", with: formattedMetres))
                .font(.headline.monospacedDigit())
                .accessibilityElement(children: .combine)
        }
    }
}

private struct LinearEquationLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var equation = LinearEquation.random()
    @State private var completedSteps = 0
    @State private var didCheckSolution = false
    @State private var feedbackKey: String?
    @State private var feedbackIsCorrect = false

    private var variableTerm: String {
        equation.coefficient == 1 ? "x" : "\(equation.coefficient)x"
    }

    private var initialLeftSide: String {
        let offsetTerm = equation.offset < 0
            ? "− \(abs(equation.offset))"
            : "+ \(equation.offset)"
        return "\(variableTerm) \(offsetTerm)"
    }

    private var visibleLeftSide: String {
        switch completedSteps {
        case 0: initialLeftSide
        case 1: variableTerm
        default: "x"
        }
    }

    private var visibleRightSide: String {
        switch completedSteps {
        case 0: "\(equation.rightSide)"
        case 1: "\(equation.isolatedVariableRightSide)"
        default: "\(equation.valueAfterDivision)"
        }
    }

    private var operationChoices: [LinearEquationOperation] {
        if completedSteps == 0 {
            return [
                .subtract(abs(equation.offset)),
                .add(abs(equation.offset)),
                .divide(equation.coefficient),
            ]
        }
        return [
            .divide(equation.coefficient),
            .multiply(equation.coefficient),
            .add(equation.coefficient),
        ]
    }

    private var progressActionTitle: String {
        didCheckSolution
            ? L10n.text("lab.equation.newExample", store.language)
            : L10n.text("lab.equation.check", store.language)
    }

    private func operationTitle(_ operation: LinearEquationOperation) -> String {
        switch operation {
        case .add(let value):
            return localized("lab.equation.add", value: String(value))
        case .subtract(let value):
            return localized("lab.equation.subtract", value: String(value))
        case .divide(let value):
            return localized("lab.equation.divide", value: String(value))
        case .multiply(let value):
            return localized("lab.equation.multiply", value: String(value))
        }
    }

    private func choose(_ operation: LinearEquationOperation) {
        guard operation.isCorrect(for: equation, at: completedSteps) else {
            feedbackKey = "lab.equation.tryAgain"
            feedbackIsCorrect = false
            return
        }

        completedSteps += 1
        feedbackKey = completedSteps == 1 ? "lab.equation.firstCorrect" : "lab.equation.secondCorrect"
        feedbackIsCorrect = true
    }

    var body: some View {
        LabCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(L10n.text("lab.equation.title", store.language), systemImage: "scalemass")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.indigo)
                Text(L10n.text("lab.equation.help", store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                equationSide(
                    title: L10n.text("lab.equation.left", store.language),
                    expression: visibleLeftSide
                )
                Text("=")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .accessibilityLabel(L10n.text("lab.equation.equals", store.language))
                equationSide(
                    title: L10n.text("lab.equation.right", store.language),
                    expression: visibleRightSide
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(visibleLeftSide) = \(visibleRightSide)")

            Text(L10n.text("lab.equation.operationHint", store.language))
                .font(.callout.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(11)
                .background(Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

            if completedSteps < 2 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("lab.equation.chooseOperation", store.language))
                        .font(.callout.weight(.semibold))
                    ForEach(Array(operationChoices.enumerated()), id: \.offset) { _, operation in
                        Button {
                            choose(operation)
                        } label: {
                            Text(operationTitle(operation))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            if let feedbackKey {
                Label(
                    L10n.text(feedbackKey, store.language),
                    systemImage: feedbackIsCorrect ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                )
                .font(.callout.weight(.medium))
                .foregroundStyle(feedbackIsCorrect ? Color.green : Color.orange)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
            }

            HStack {
                Label(
                    String(
                        format: L10n.text("lab.equation.progress", store.language),
                        min(completedSteps, 2),
                        2
                    ),
                    systemImage: didCheckSolution ? "checkmark.seal.fill" : "equal.circle"
                )
                .font(.callout.weight(.semibold))
                .foregroundStyle(didCheckSolution ? .green : .secondary)
                Spacer()
                if completedSteps == 2 {
                    Button {
                        if !didCheckSolution {
                            didCheckSolution = true
                        } else {
                            equation = .random()
                            completedSteps = 0
                            didCheckSolution = false
                            feedbackKey = nil
                            feedbackIsCorrect = false
                        }
                    } label: {
                        Label(
                            progressActionTitle,
                            systemImage: didCheckSolution ? "shuffle" : "checkmark.circle"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
            }

            if didCheckSolution {
                Label(
                    localized(
                        "lab.equation.substitution",
                        value: "\(equation.coefficient) × \(equation.solution) \(equation.offset < 0 ? "− \(abs(equation.offset))" : "+ \(equation.offset)") = \(equation.rightSide)"
                    ),
                    systemImage: equation.isSolution(equation.solution) ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.callout.weight(.semibold))
                .foregroundStyle(equation.isSolution(equation.solution) ? .green : .red)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func equationSide(title: String, expression: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(expression)
                .font(.system(size: 23, weight: .semibold, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 68)
        .background(Color.indigo.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }

    private func localized(_ key: String, value: String) -> String {
        L10n.text(key, store.language).replacingOccurrences(of: "%@", with: value)
    }
}

private struct RationalExpressionLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var input = 0.0

    private var originalValue: Double? {
        RationalExpressionPractice.originalValue(at: input)
    }

    private var simplifiedValue: Double {
        RationalExpressionPractice.simplifiedValue(at: input)
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.rationalHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("f(x) = (x² − 9) / (x − 3)")
                .font(.title3.monospaced().weight(.semibold))
                .accessibilityLabel(L10n.text("lab.rationalFormula", store.language))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("−5")
                    Spacer()
                    Text(String(format: L10n.text("lab.rationalSelectedInput", store.language), input))
                        .font(.caption.monospacedDigit().weight(.semibold))
                    Spacer()
                    Text("5")
                }
                Slider(value: $input, in: -5...5, step: 0.25)
                    .accessibilityLabel(L10n.text("lab.rationalInput", store.language))
                    .accessibilityValue(String(format: "%.2f", input))
            }

            HStack(alignment: .top, spacing: 12) {
                valueCard(
                    title: L10n.text("lab.rationalOriginal", store.language),
                    value: originalValue.map { String(format: "%.2f", $0) }
                        ?? L10n.text("lab.rationalUndefined", store.language),
                    emphasized: originalValue == nil
                )
                valueCard(
                    title: L10n.text("lab.rationalReduced", store.language),
                    value: String(format: "%.2f", simplifiedValue),
                    emphasized: false
                )
            }

            Label(
                L10n.text(originalValue == nil ? "lab.rationalExcluded" : "lab.rationalDefined", store.language),
                systemImage: originalValue == nil ? "xmark.circle.fill" : "equal.circle.fill"
            )
            .foregroundStyle(originalValue == nil ? Color.orange : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func valueCard(title: String, value: String, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.monospacedDigit().weight(.semibold))
                .foregroundStyle(emphasized ? Color.orange : Color.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private struct DerivativeRateLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var point = 2.0
    @State private var step = 1.0

    private var secantSlope: Double { 2 * point + step }
    private var tangentSlope: Double { 2 * point }

    var body: some View {
        LabCard {
            Text("f(x) = x²")
                .font(.system(.headline, design: .monospaced))

            Text(L10n.text("lab.derivativeHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Canvas { context, size in
                guard size.width > 0, size.height > 0 else { return }
                func location(_ x: Double, _ y: Double) -> CGPoint {
                    CGPoint(
                        x: CGFloat((x + 3) / 6) * size.width,
                        y: CGFloat((9 - y) / 12) * size.height
                    )
                }

                var grid = Path()
                for value in -3...3 {
                    let x = CGFloat(value + 3) / 6 * size.width
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                for value in stride(from: -3, through: 9, by: 2) {
                    let y = CGFloat(9 - value) / 12 * size.height
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(.secondary.opacity(0.16)), lineWidth: 1)

                var axes = Path()
                axes.move(to: location(-3, 0))
                axes.addLine(to: location(3, 0))
                axes.move(to: location(0, -3))
                axes.addLine(to: location(0, 9))
                context.stroke(axes, with: .color(.secondary.opacity(0.7)), lineWidth: 1.5)

                var curve = Path()
                for index in 0...120 {
                    let x = -3.0 + Double(index) * 0.05
                    let p = location(x, x * x)
                    if index == 0 { curve.move(to: p) } else { curve.addLine(to: p) }
                }
                context.stroke(curve, with: .color(.indigo), lineWidth: 2.5)

                var tangent = Path()
                let tangentStart = point - 0.7
                let tangentEnd = point + 0.7
                tangent.move(to: location(tangentStart, tangentSlope * tangentStart - point * point))
                tangent.addLine(to: location(tangentEnd, tangentSlope * tangentEnd - point * point))
                context.stroke(tangent, with: .color(.green), lineWidth: 2.5)

                var secant = Path()
                secant.move(to: location(point, point * point))
                secant.addLine(to: location(point + step, (point + step) * (point + step)))
                context.stroke(secant, with: .color(.orange), lineWidth: 2.5)

                for x in [point, point + step] {
                    let p = location(x, x * x)
                    context.fill(
                        Path(ellipseIn: CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9)),
                        with: .color(.orange)
                    )
                }
            }
            .frame(height: 230)
            .accessibilityLabel(L10n.text("lab.derivativeGraph", store.language))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(L10n.text("lab.derivativePoint", store.language))
                    Spacer()
                    Text(String(format: "x = %.1f", point)).monospacedDigit()
                }
                Slider(value: $point, in: -2.5...0.8, step: 0.1)
                    .accessibilityLabel(Text(L10n.text("lab.derivativePoint", store.language)))

                HStack {
                    Text(L10n.text("lab.derivativeStep", store.language))
                    Spacer()
                    Text(String(format: "h = %.1f", step)).monospacedDigit()
                }
                Slider(value: $step, in: 0.2...2.0, step: 0.1)
                    .accessibilityLabel(Text(L10n.text("lab.derivativeStep", store.language)))
            }

            HStack(spacing: 14) {
                Label(L10n.text("lab.derivativeFunction", store.language), systemImage: "waveform.path")
                    .foregroundStyle(.indigo)
                Label(L10n.text("lab.derivativeSecant", store.language), systemImage: "line.diagonal")
                    .foregroundStyle(.orange)
                Label(L10n.text("lab.derivativeTangent", store.language), systemImage: "line.diagonal")
                    .foregroundStyle(.green)
            }
            .font(.caption)
            .labelStyle(.titleAndIcon)

            VStack(alignment: .leading, spacing: 5) {
                Text(String(format: L10n.text("lab.derivativeSecantValue", store.language), secantSlope))
                Text(String(format: L10n.text("lab.derivativeTangentValue", store.language), tangentSlope))
                    .fontWeight(.semibold)
            }
            .font(.callout.monospacedDigit())
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
    @State private var optionOrder = QuizAnswerOrder(optionCount: 2, answerOriginalIndex: 0)

    var body: some View {
        LabCard {
            Text(L10n.text("lab.tensePrompt", store.language))
                .font(.headline)
            Picker("", selection: $scenario) {
                Text(L10n.text("lab.tenseScenario0", store.language)).tag(0)
                Text(L10n.text("lab.tenseScenario1", store.language)).tag(1)
            }
            .pickerStyle(.segmented)
            .onChange(of: scenario) { newScenario in
                selectedAnswer = nil
                optionOrder = QuizAnswerOrder(optionCount: 2, answerOriginalIndex: newScenario)
            }

            HStack(spacing: 10) {
                ForEach(Array(optionOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Button {
                        selectedAnswer = displayIndex
                    } label: {
                        Text(L10n.text("lab.tenseOption\(scenario)\(originalIndex)", store.language))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(
                                selectedAnswer == displayIndex
                                    ? (optionOrder.isCorrect(displayedIndex: displayIndex) ? Color.green.opacity(0.16) : Color.orange.opacity(0.16))
                                    : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selectedAnswer {
                Label(
                    L10n.text(optionOrder.isCorrect(displayedIndex: selectedAnswer) ? "lab.tenseCorrect" : "lab.tenseIncorrect", store.language),
                    systemImage: optionOrder.isCorrect(displayedIndex: selectedAnswer) ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                )
                .foregroundStyle(optionOrder.isCorrect(displayedIndex: selectedAnswer) ? Color.green : Color.orange)
            }
        }
    }
}

private struct PresentPerfectAspectLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var scenario = 0
    @State private var selectedAnswer: Int?

    private let correctAnswers = [1, 1, 0]
    @State private var optionOrder = QuizAnswerOrder(optionCount: 2, answerOriginalIndex: 1)

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
            .onChange(of: scenario) { newScenario in
                selectedAnswer = nil
                optionOrder = QuizAnswerOrder(optionCount: 2, answerOriginalIndex: correctAnswers[newScenario])
            }

            Text(L10n.text("lab.perfectSentence\(scenario)", store.language))
                .font(.title3.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                ForEach(Array(optionOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Button {
                        selectedAnswer = displayIndex
                    } label: {
                        Text(L10n.text("lab.perfectOption\(scenario)\(originalIndex)", store.language))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(answerColor(forDisplayedIndex: displayIndex), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selectedAnswer {
                let isCorrect = optionOrder.isCorrect(displayedIndex: selectedAnswer)
                Label(
                    L10n.text("lab.perfectFeedback\(scenario)\(isCorrect ? 1 : 0)", store.language),
                    systemImage: isCorrect ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                )
                .foregroundStyle(isCorrect ? Color.green : Color.orange)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func answerColor(forDisplayedIndex displayIndex: Int) -> Color {
        guard let selectedAnswer, selectedAnswer == displayIndex else {
            return Color.secondary.opacity(0.08)
        }
        return optionOrder.isCorrect(displayedIndex: displayIndex) ? Color.green.opacity(0.16) : Color.orange.opacity(0.16)
    }
}

private struct ConditionalPracticeQuestion {
    let id: String
    let promptKey: String
    let feedbackKey: String
}

private struct ConditionalsLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var index = 0
    @State private var selection: Int?
    @State private var wasCorrect: Bool?
    @State private var complete = false
    @State private var optionOrder = QuizAnswerOrder(
        optionCount: EnglishConditionalForm.allCases.count,
        answerOriginalIndex: EnglishConditionalPractice.scenarios[0].correctForm.rawValue
    )

    private let questions = [
        ConditionalPracticeQuestion(id: EnglishConditionalPractice.scenarios[0].id, promptKey: "lab.conditionalScenario0", feedbackKey: "lab.conditionalFeedback0"),
        ConditionalPracticeQuestion(id: EnglishConditionalPractice.scenarios[1].id, promptKey: "lab.conditionalScenario1", feedbackKey: "lab.conditionalFeedback1"),
        ConditionalPracticeQuestion(id: EnglishConditionalPractice.scenarios[2].id, promptKey: "lab.conditionalScenario2", feedbackKey: "lab.conditionalFeedback2")
    ]

    var body: some View {
        LabCard {
            Text(L10n.text("lab.conditionalHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if complete {
                Label(L10n.text("lab.conditionalComplete", store.language), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .fixedSize(horizontal: false, vertical: true)
                Button(L10n.text("lab.conditionalRestart", store.language), systemImage: "arrow.counterclockwise") {
                    reset()
                }
                .buttonStyle(.bordered)
            } else {
                Text(String(format: L10n.text("lab.conditionalProgress", store.language), index + 1, questions.count))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(index + 1), total: Double(questions.count))
                Text(L10n.text(questions[index].promptKey, store.language))
                    .font(.title3.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(optionOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Button {
                        selection = displayIndex
                        wasCorrect = nil
                    } label: {
                        Label(
                            L10n.text("lab.conditionalOption\(originalIndex)", store.language),
                            systemImage: selection == displayIndex ? "checkmark.circle.fill" : "circle"
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(selection == displayIndex ? .accentColor : .secondary)
                    .accessibilityAddTraits(selection == displayIndex ? .isSelected : [])
                }

                if let wasCorrect {
                    Label(
                        wasCorrect
                            ? L10n.text(questions[index].feedbackKey, store.language)
                            : L10n.text("lab.conditionalTryAgain", store.language),
                        systemImage: wasCorrect ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath"
                    )
                    .foregroundStyle(wasCorrect ? Color.green : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    if wasCorrect == true {
                        if index == questions.count - 1 {
                            complete = true
                        } else {
                            index += 1
                            selection = nil
                            wasCorrect = nil
                            optionOrder = QuizAnswerOrder(
                                optionCount: EnglishConditionalForm.allCases.count,
                                answerOriginalIndex: EnglishConditionalPractice.scenarios[index].correctForm.rawValue
                            )
                        }
                    } else if let selection {
                        wasCorrect = optionOrder.isCorrect(displayedIndex: selection)
                    }
                } label: {
                    Text(L10n.text(
                        wasCorrect == true
                            ? (index == questions.count - 1 ? "lab.conditionalFinish" : "lab.conditionalNext")
                            : "lab.conditionalCheck",
                        store.language
                    ))
                }
                .buttonStyle(.borderedProminent)
                .disabled(selection == nil && wasCorrect != true)
            }
        }
    }

    private func reset() {
        index = 0
        selection = nil
        wasCorrect = nil
        complete = false
        optionOrder = QuizAnswerOrder(
            optionCount: EnglishConditionalForm.allCases.count,
            answerOriginalIndex: EnglishConditionalPractice.scenarios[0].correctForm.rawValue
        )
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

private struct BiologyInvestigationLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var design = BiologyExperimentDesign(
        factorToChange: .waterAmount,
        outcomeToMeasure: .leafCount,
        controls: [],
        plantsPerGroup: 1
    )
    @State private var didReviewDesign = false

    var body: some View {
        LabCard {
            VStack(alignment: .leading, spacing: 6) {
                Label(L10n.text("lab.investigation.title", store.language), systemImage: "leaf")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.green)
                Text(L10n.text("lab.investigation.scenario", store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                lightGroup(
                    title: L10n.text("lab.investigation.groupA", store.language),
                    hours: "4"
                )
                Image(systemName: "arrow.left.and.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                lightGroup(
                    title: L10n.text("lab.investigation.groupB", store.language),
                    hours: "8"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Picker(
                    L10n.text("lab.investigation.change", store.language),
                    selection: Binding(
                        get: { design.factorToChange },
                        set: { design.factorToChange = $0; didReviewDesign = false }
                    )
                ) {
                    ForEach(BiologyStudyFactor.allCases, id: \.self) { factor in
                        Text(L10n.text(factorTitleKey(factor), store.language)).tag(factor)
                    }
                }
                .pickerStyle(.menu)

                Picker(
                    L10n.text("lab.investigation.measure", store.language),
                    selection: Binding(
                        get: { design.outcomeToMeasure },
                        set: { design.outcomeToMeasure = $0; didReviewDesign = false }
                    )
                ) {
                    ForEach(BiologyStudyOutcome.allCases, id: \.self) { outcome in
                        Text(L10n.text(outcomeTitleKey(outcome), store.language)).tag(outcome)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("lab.investigation.keepSame", store.language))
                    .font(.callout.weight(.semibold))
                ForEach(BiologyStudyControl.allCases, id: \.self) { control in
                    Toggle(
                        L10n.text(controlTitleKey(control), store.language),
                        isOn: Binding(
                            get: { design.controls.contains(control) },
                            set: { isSelected in
                                if isSelected {
                                    design.controls.insert(control)
                                } else {
                                    design.controls.remove(control)
                                }
                                didReviewDesign = false
                            }
                        )
                    )
                    .toggleStyle(.checkbox)
                }
            }

            Stepper(
                value: Binding(
                    get: { design.plantsPerGroup },
                    set: { design.plantsPerGroup = $0; didReviewDesign = false }
                ),
                in: 1...12
            ) {
                Text(
                    String(
                        format: L10n.text("lab.investigation.replicates", store.language),
                        design.plantsPerGroup
                    )
                )
                .monospacedDigit()
            }

            Button {
                didReviewDesign = true
            } label: {
                Label(
                    L10n.text("lab.investigation.check", store.language),
                    systemImage: "checkmark.magnifyingglass"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            if didReviewDesign {
                if design.isReadyToCollectData {
                    Label(
                        L10n.text("lab.investigation.ready", store.language),
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.green)
                    .fixedSize(horizontal: false, vertical: true)
                    Text(L10n.text("lab.investigation.noResults", store.language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(
                            L10n.text("lab.investigation.review", store.language),
                            systemImage: "exclamationmark.circle"
                        )
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.orange)
                        ForEach(design.issues, id: \.self) { issue in
                            Label(
                                L10n.text(issueTitleKey(issue), store.language),
                                systemImage: "arrow.turn.down.right"
                            )
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func lightGroup(title: String, hours: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: "sun.max.fill")
                .font(.title2)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(title)
                .font(.caption.weight(.medium))
            Text(
                String(
                    format: L10n.text("lab.investigation.hours", store.language),
                    hours
                )
            )
            .font(.callout.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }

    private func factorTitleKey(_ factor: BiologyStudyFactor) -> String {
        switch factor {
        case .lightExposure:
            return "lab.investigation.factor.light"
        case .waterAmount:
            return "lab.investigation.factor.water"
        case .plantType:
            return "lab.investigation.factor.plant"
        }
    }

    private func outcomeTitleKey(_ outcome: BiologyStudyOutcome) -> String {
        switch outcome {
        case .heightChange:
            return "lab.investigation.outcome.height"
        case .leafCount:
            return "lab.investigation.outcome.leaves"
        case .soilMoisture:
            return "lab.investigation.outcome.soil"
        }
    }

    private func controlTitleKey(_ control: BiologyStudyControl) -> String {
        switch control {
        case .waterAmount:
            return "lab.investigation.control.water"
        case .seedType:
            return "lab.investigation.control.seed"
        case .potAndSoil:
            return "lab.investigation.control.pot"
        case .temperatureAndDuration:
            return "lab.investigation.control.conditions"
        }
    }

    private func issueTitleKey(_ issue: BiologyStudyIssue) -> String {
        "lab.investigation.issue.\(issue.rawValue)"
    }
}

private struct PhotosynthesisLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var light = 70.0
    @State private var carbonDioxide = 45.0

    private var rate: Double { min(light, carbonDioxide) }
    private var limitingFactorKey: String {
        if light == carbonDioxide { return "lab.photosynthesisBalanced" }
        return light < carbonDioxide ? "lab.photosynthesisLightLimits" : "lab.photosynthesisCO2Limits"
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.photosynthesisHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack(alignment: .center, spacing: 10) {
                stageCard(
                    symbol: "sun.max.fill",
                    color: .orange,
                    title: L10n.text("lab.photosynthesisLightStage", store.language),
                    detail: L10n.text("lab.photosynthesisEnergyProducts", store.language)
                )
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                stageCard(
                    symbol: "leaf.fill",
                    color: .green,
                    title: L10n.text("lab.photosynthesisCarbonStage", store.language),
                    detail: L10n.text("lab.photosynthesisCarbonProduct", store.language)
                )
            }

            factorSlider(title: L10n.text("lab.photosynthesisLight", store.language), value: $light)
            factorSlider(title: L10n.text("lab.photosynthesisCO2", store.language), value: $carbonDioxide)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.text("lab.photosynthesisRelativeRate", store.language))
                    Spacer()
                    Text("\(Int(rate))%")
                        .monospacedDigit()
                        .fontWeight(.semibold)
                }
                ProgressView(value: rate, total: 100)
                    .tint(.green)
                Label(L10n.text(limitingFactorKey, store.language), systemImage: "exclamationmark.triangle.fill")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.orange)
            }
            .padding(12)
            .background(Color.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func stageCard(symbol: String, color: Color, title: String, detail: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 94)
        .padding(9)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private func factorSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: 0...100, step: 5)
                .accessibilityLabel(Text(title))
        }
    }
}

private struct SymmetryLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var bodyPlan = 1
    @State private var cutAngle = 0.0

    private var interpretationKey: String {
        if bodyPlan == 0 { return "lab.symmetryAsymmetrical" }
        if bodyPlan == 2 { return "lab.symmetryRadial" }
        return cutAngle < 5 ? "lab.symmetryBilateralMatch" : "lab.symmetryBilateralNoMatch"
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.symmetryHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)

            Picker(L10n.text("lab.symmetryPlan", store.language), selection: $bodyPlan) {
                Text(L10n.text("lab.symmetryOptionAsym", store.language)).tag(0)
                Text(L10n.text("lab.symmetryOptionBilateral", store.language)).tag(1)
                Text(L10n.text("lab.symmetryOptionRadial", store.language)).tag(2)
            }
            .pickerStyle(.segmented)

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width * 0.22, size.height * 0.36)
                var body = Path()
                if bodyPlan == 0 {
                    body.move(to: CGPoint(x: center.x - radius * 0.8, y: center.y - radius * 0.45))
                    body.addCurve(to: CGPoint(x: center.x + radius * 0.75, y: center.y - radius * 0.3),
                                  control1: CGPoint(x: center.x - radius * 0.15, y: center.y - radius * 1.05),
                                  control2: CGPoint(x: center.x + radius * 1.15, y: center.y - radius * 0.85))
                    body.addCurve(to: CGPoint(x: center.x + radius * 0.35, y: center.y + radius * 0.75),
                                  control1: CGPoint(x: center.x + radius * 1.0, y: center.y + radius * 0.15),
                                  control2: CGPoint(x: center.x + radius * 0.75, y: center.y + radius * 0.95))
                    body.addCurve(to: CGPoint(x: center.x - radius * 0.8, y: center.y - radius * 0.45),
                                  control1: CGPoint(x: center.x - radius * 0.25, y: center.y + radius * 0.95),
                                  control2: CGPoint(x: center.x - radius * 1.2, y: center.y + radius * 0.25))
                    body.closeSubpath()
                } else {
                    body.addEllipse(in: CGRect(x: center.x - radius * 0.62,
                                               y: center.y - radius,
                                               width: radius * 1.24,
                                               height: radius * 2))
                }
                context.fill(body, with: .color(bodyPlan == 0 ? .teal.opacity(0.5) : .green.opacity(0.28)))
                context.stroke(body, with: .color(bodyPlan == 0 ? .teal : .green), lineWidth: 2)

                var planes = Path()
                let angles = bodyPlan == 2
                    ? stride(from: 0.0, to: 180.0, by: 45.0).map { $0 + cutAngle }
                    : [cutAngle]
                for angle in angles {
                    let radians = angle * .pi / 180
                    let dx = cos(radians) * radius * 1.25
                    let dy = sin(radians) * radius * 1.25
                    planes.move(to: CGPoint(x: center.x - dx, y: center.y - dy))
                    planes.addLine(to: CGPoint(x: center.x + dx, y: center.y + dy))
                }
                context.stroke(planes, with: .color(.orange), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            }
            .frame(height: 180)
            .accessibilityLabel(Text(L10n.text(interpretationKey, store.language)))

            if bodyPlan == 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("lab.symmetryRotatePlane", store.language))
                    Slider(value: $cutAngle, in: 0...90, step: 5)
                        .accessibilityLabel(Text(L10n.text("lab.symmetryRotatePlane", store.language)))
                }
            }

            Label(L10n.text(interpretationKey, store.language), systemImage: "view.2d")
                .font(.callout.weight(.medium))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
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
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var force = 12.0
    @State private var mass = 3.0
    @State private var elapsed = 0.0
    @State private var elapsedAtStart = 0.0
    @State private var startedAt: ContinuousClock.Instant?
    private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private var motion: ForceMotion { ForceMotion(force: force, mass: mass, time: elapsed) }
    private var isRunning: Bool { startedAt != nil }

    var body: some View {
        LabCard {
            Force3DVisualization(force: force, mass: mass, displacement: motion.displacement)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel(Text(L10n.text("lab.force3DHint", store.language)))
            Text(L10n.text("lab.force3DHint", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("F = ma   ·   v = at   ·   x = ½at²")
                .font(.system(.headline, design: .monospaced))
            Text(L10n.text("lab.forceAssumptions", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
            valueSlider(title: L10n.text("lab.force", store.language), value: $force, range: -30...30, suffix: " N")
            valueSlider(title: L10n.text("lab.mass", store.language), value: $mass, range: 1...10, suffix: " kg")
            HStack {
                Button {
                    if isRunning { pause() } else { start() }
                } label: {
                    Label(L10n.text(isRunning ? "lab.motionPause" : "lab.motionPlay", store.language),
                          systemImage: isRunning ? "pause.fill" : "play.fill")
                }
                .disabled(reduceMotion || scenePhase != .active)
                Button(L10n.text("lab.motionStep", store.language)) {
                    elapsed = min(ForceMotion.duration, elapsed + 0.1)
                }
                .disabled(isRunning || motion.hasFinished)
                Button(L10n.text("lab.motionReset", store.language), action: reset)
            }
            ProgressView(value: elapsed, total: ForceMotion.duration)
                .accessibilityLabel(Text(L10n.text("lab.motionTime", store.language)))
                .accessibilityValue(Text("\(elapsed, specifier: "%.1f") / 2 s"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), alignment: .leading)], alignment: .leading, spacing: 12) {
                reading("lab.motionTime", value: elapsed, unit: "s")
                reading("lab.acceleration", value: motion.acceleration, unit: "m/s²")
                reading("lab.motionVelocity", value: motion.velocity, unit: "m/s")
                reading("lab.motionDisplacement", value: motion.displacement, unit: "m")
            }
            if reduceMotion {
                Text(L10n.text("lab.motionReduced", store.language)).font(.caption).foregroundStyle(.secondary)
            }
            if motion.hasFinished {
                Text(L10n.text("lab.motionFinished", store.language)).font(.callout)
            }
            Text(L10n.text("lab.forceExperiment", store.language)).font(.callout)
        }
        .onReceive(timer) { _ in advance() }
        .onChange(of: force) { _ in reset() }
        .onChange(of: mass) { _ in reset() }
        .onChange(of: scenePhase) { phase in if phase != .active { pause() } }
        .onChange(of: reduceMotion) { enabled in if enabled { pause() } }
        .onDisappear(perform: pause)
    }

    private func reading(_ key: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.text(key, store.language)).font(.caption).foregroundStyle(.secondary)
            Text("\(value, specifier: "%.2f") \(unit)").monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private func start() {
        guard !reduceMotion, scenePhase == .active else { return }
        if motion.hasFinished { elapsed = 0 }
        elapsedAtStart = elapsed
        startedAt = ContinuousClock.now
    }

    private func advance() {
        guard let startedAt else { return }
        let duration = startedAt.duration(to: ContinuousClock.now).components
        let seconds = Double(duration.seconds) + Double(duration.attoseconds) / 1e18
        elapsed = min(ForceMotion.duration, elapsedAtStart + max(0, seconds))
        if motion.hasFinished { self.startedAt = nil }
    }

    private func pause() {
        advance()
        startedAt = nil
    }

    private func reset() {
        startedAt = nil
        elapsedAtStart = 0
        elapsed = 0
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

private struct LengthMeasurementLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var length = 12.4
    @State private var uncertainty = 0.2

    private let scaleCentimetres = 32.0

    private var measurement: LengthMeasurement {
        LengthMeasurement(centimetres: length, uncertaintyCentimetres: uncertainty)
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.measurementTitle", store.language))
                .font(.headline)
            Text(L10n.text("lab.measurementHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                let trackWidth = max(geometry.size.width - 12, 0)
                let lowerX = measurement.lowerCentimetres / scaleCentimetres * trackWidth
                let centreX = measurement.centimetres / scaleCentimetres * trackWidth
                let bandWidth = 2 * uncertainty / scaleCentimetres * trackWidth
                ZStack(alignment: .topLeading) {
                    Capsule()
                        .fill(.secondary.opacity(0.5))
                        .frame(width: trackWidth, height: 3)
                        .offset(x: 6, y: 25)
                    Capsule()
                        .fill(Color.accentColor.opacity(0.35))
                        .frame(width: bandWidth, height: 18)
                        .offset(x: 6 + lowerX, y: 17)
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 10)
                        .offset(x: 1 + centreX, y: 21)
                }
            }
            .frame(height: 54)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(L10n.text("lab.measurementBand", store.language)))
            .accessibilityValue(Text(String(format: "%.1f–%.1f cm",
                                                measurement.lowerCentimetres,
                                                measurement.upperCentimetres)))

            HStack {
                Text("0 cm")
                Spacer()
                Text("32 cm")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("lab.measurementLength", store.language))
                Slider(value: $length, in: 3...30, step: 0.1)
                    .accessibilityLabel(Text(L10n.text("lab.measurementLength", store.language)))
                    .accessibilityValue(Text(String(format: "%.1f cm", length)))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("lab.measurementUncertainty", store.language))
                Slider(value: $uncertainty, in: 0.1...2, step: 0.1)
                    .accessibilityLabel(Text(L10n.text("lab.measurementUncertainty", store.language)))
                    .accessibilityValue(Text(String(format: "%.1f cm", uncertainty)))
            }

            Text(String(format: "%.1f ± %.1f cm = %.3f ± %.3f m",
                        length, uncertainty, measurement.metres, measurement.uncertaintyMetres))
                .font(.headline.monospacedDigit())
                .textSelection(.enabled)
            Text(String(format: "%@: %.1f%%",
                        L10n.text("lab.measurementRelative", store.language),
                        measurement.relativeUncertaintyPercent))
                .font(.callout.monospacedDigit())
            Text(L10n.text("lab.measurementLimits", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct FrictionLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var mass = 5.0
    @State private var appliedForce = 15.0
    @State private var staticCoefficient = 0.4
    @State private var kineticCoefficient = 0.3
    @State private var time = 2.0

    private var motion: FrictionMotion {
        FrictionMotion(
            mass: mass,
            appliedForce: appliedForce,
            staticCoefficient: staticCoefficient,
            kineticCoefficient: min(kineticCoefficient, staticCoefficient),
            time: time
        )
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.frictionHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                let width = max(geometry.size.width - 64, 0)
                let travel = min(width, motion.displacement * 16)
                ZStack(alignment: .leading) {
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(.secondary.opacity(0.45))
                            .frame(height: 3)
                    }
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.gradient)
                        .overlay {
                            Image(systemName: "shippingbox.fill")
                                .foregroundStyle(.white)
                        }
                        .frame(width: 54, height: 42)
                        .offset(x: travel, y: 0)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(L10n.text("lab.frictionBlock", store.language)))
                .accessibilityValue(Text(motion.isSliding
                    ? L10n.text("lab.frictionSliding", store.language)
                    : L10n.text("lab.frictionResting", store.language)))
            }
            .frame(height: 64)
            .accessibilityElement(children: .contain)

            HStack(spacing: 14) {
                Label("F = \(appliedForce, specifier: "%.1f") N", systemImage: "arrow.right")
                Label("f = \(motion.frictionForce, specifier: "%.1f") N", systemImage: "arrow.left")
            }
            .font(.callout.monospacedDigit())
            .accessibilityElement(children: .combine)

            Text(L10n.text(motion.isSliding ? "lab.frictionSliding" : "lab.frictionResting", store.language))
                .font(.headline)
                .foregroundStyle(motion.isSliding ? Color.orange : Color.primary)
            Text("\(L10n.text("lab.frictionThreshold", store.language)): \(motion.maximumStaticFriction, specifier: "%.2f") N")
                .font(.callout.monospacedDigit())

            slider("lab.mass", value: $mass, range: 1...10, step: 0.5, unit: " kg")
            slider("lab.frictionPush", value: $appliedForce, range: 0...60, step: 1, unit: " N")
            slider("lab.frictionStaticCoefficient", value: $staticCoefficient, range: 0.1...0.8, step: 0.05, unit: "")
            slider("lab.frictionKineticCoefficient", value: $kineticCoefficient, range: 0.05...staticCoefficient, step: 0.05, unit: "")
            slider("lab.frictionTime", value: $time, range: 0...FrictionMotion.duration, step: 0.1, unit: " s")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)], alignment: .leading, spacing: 12) {
                reading("lab.frictionNormal", value: motion.normalForce, unit: "N")
                reading("lab.frictionForce", value: motion.frictionForce, unit: "N")
                reading("lab.frictionAcceleration", value: motion.acceleration, unit: "m/s²")
                reading("lab.frictionVelocity", value: motion.velocity, unit: "m/s")
                reading("lab.frictionDisplacement", value: motion.displacement, unit: "m")
            }

            Text(L10n.text("lab.frictionPrediction", store.language))
                .font(.callout)
            Text(L10n.text("lab.frictionLimits", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onChange(of: staticCoefficient) { newValue in
            kineticCoefficient = min(kineticCoefficient, newValue)
        }
    }

    private func slider(
        _ titleKey: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L10n.text(titleKey, store.language))
                Spacer(minLength: 8)
                Text("\(value.wrappedValue, specifier: "%.2f")\(unit)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
                .accessibilityLabel(Text(L10n.text(titleKey, store.language)))
                .accessibilityValue(Text("\(value.wrappedValue, specifier: "%.2f")\(unit)"))
        }
    }

    private func reading(_ key: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.text(key, store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value, specifier: "%.2f") \(unit)")
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ProjectileMotionLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var launchSpeed = 20.0
    @State private var angleDegrees = 35.0
    @State private var elapsed = 0.0
    @State private var comparesComplement = true

    private var motion: ProjectileMotion {
        ProjectileMotion(launchSpeed: launchSpeed, angleDegrees: angleDegrees)
    }
    private var complement: ProjectileMotion {
        ProjectileMotion(launchSpeed: launchSpeed, angleDegrees: 90 - angleDegrees)
    }
    private var displayedMaximumRange: Double {
        max(max(motion.horizontalRange, comparesComplement ? complement.horizontalRange : 0), 1) * 1.12
    }
    private var displayedMaximumHeight: Double {
        max(max(motion.maximumHeight, comparesComplement ? complement.maximumHeight : 0), 1) * 1.16
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.projectile.title", store.language))
                .font(.headline)
            Text(L10n.text("lab.projectile.hint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Canvas { context, size in
                guard size.width > 0, size.height > 0 else { return }
                let inset: CGFloat = 12
                func location(_ x: Double, _ y: Double) -> CGPoint {
                    CGPoint(
                        x: inset + CGFloat(x / displayedMaximumRange) * (size.width - 2 * inset),
                        y: size.height - inset - CGFloat(y / displayedMaximumHeight) * (size.height - 2 * inset)
                    )
                }

                var grid = Path()
                for step in 0...4 {
                    let fraction = CGFloat(step) / 4
                    let x = inset + fraction * (size.width - 2 * inset)
                    let y = inset + fraction * (size.height - 2 * inset)
                    grid.move(to: CGPoint(x: x, y: inset))
                    grid.addLine(to: CGPoint(x: x, y: size.height - inset))
                    grid.move(to: CGPoint(x: inset, y: y))
                    grid.addLine(to: CGPoint(x: size.width - inset, y: y))
                }
                context.stroke(grid, with: .color(.secondary.opacity(0.14)), lineWidth: 1)

                func trajectoryPath(for model: ProjectileMotion) -> Path {
                    var path = Path()
                    let samples = 100
                    for index in 0...samples {
                        let t = model.flightTime * Double(index) / Double(samples)
                        let point = model.position(at: t)
                        let plotted = location(point.x, point.y)
                        if index == 0 { path.move(to: plotted) } else { path.addLine(to: plotted) }
                    }
                    return path
                }

                if comparesComplement {
                    context.stroke(
                        trajectoryPath(for: complement),
                        with: .color(.orange.opacity(0.85)),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                }
                context.stroke(trajectoryPath(for: motion), with: .color(.accentColor), lineWidth: 3)
                let current = motion.position(at: elapsed)
                let point = location(current.x, current.y)
                context.fill(Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12)), with: .color(.accentColor))
            }
            .frame(height: 230)
            .accessibilityLabel(Text(L10n.text("lab.projectile.chart", store.language)))

            HStack(spacing: 16) {
                Label(L10n.text("lab.projectile.current", store.language), systemImage: "circle.fill")
                    .foregroundStyle(.tint)
                if comparesComplement {
                    Label("90° − θ", systemImage: "line.diagonal")
                        .foregroundStyle(.orange)
                }
                Spacer()
                Button(L10n.text(comparesComplement ? "lab.projectile.hideCompare" : "lab.projectile.compare", store.language)) {
                    comparesComplement.toggle()
                }
                .buttonStyle(.bordered)
            }
            .font(.caption)

            projectileSlider(title: L10n.text("lab.projectile.speed", store.language), value: $launchSpeed, range: 5...30, suffix: " m/s")
            projectileSlider(title: L10n.text("lab.projectile.angle", store.language), value: $angleDegrees, range: 15...75, suffix: "°")

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("lab.projectile.time", store.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $elapsed, in: 0...max(motion.flightTime, 0.05), step: 0.05)
                    .accessibilityLabel(Text(L10n.text("lab.projectile.time", store.language)))
                Text("t = \(elapsed, specifier: "%.2f") s")
                    .monospacedDigit()
                    .font(.caption)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), alignment: .leading)], alignment: .leading, spacing: 12) {
                projectileReading("lab.projectile.range", value: motion.horizontalRange, unit: "m")
                projectileReading("lab.projectile.height", value: motion.maximumHeight, unit: "m")
                projectileReading("lab.projectile.flight", value: motion.flightTime, unit: "s")
                projectileReading("lab.projectile.position", value: motion.position(at: elapsed).x, unit: "m")
            }
            Text(L10n.text("lab.projectile.compareTask", store.language))
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.text("lab.projectile.limits", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onChange(of: angleDegrees) { _ in elapsed = min(elapsed, motion.flightTime) }
        .onChange(of: launchSpeed) { _ in elapsed = min(elapsed, motion.flightTime) }
    }

    private func projectileSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
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

    private func projectileReading(_ key: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.text(key, store.language)).font(.caption).foregroundStyle(.secondary)
            Text("\(value, specifier: "%.2f") \(unit)").monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct Force3DVisualization: NSViewRepresentable {
    let force: Double
    let mass: Double
    let displacement: Double

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = Self.makeScene()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .windowBackgroundColor
        return view
    }

    func updateNSView(_ view: SCNView, context: Context) {
        guard let scene = view.scene else { return }
        Self.update(scene: scene, force: force, mass: mass, displacement: displacement)
    }

    private static func makeScene() -> SCNScene {
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

        let ground = SCNBox(width: 16, height: 0.06, length: 2.6, chamferRadius: 0.02)
        ground.firstMaterial?.diffuse.contents = NSColor.tertiaryLabelColor
        let groundNode = SCNNode(geometry: ground)
        groundNode.position = SCNVector3(0, -0.04, 0)
        scene.rootNode.addChildNode(groundNode)

        // Fixed spatial scale: one scene unit represents ten metres.
        for metres in stride(from: -60, through: 60, by: 20) {
            let marker = SCNNode(geometry: SCNBox(width: 0.02, height: 0.02, length: 2.5, chamferRadius: 0))
            marker.geometry?.firstMaterial?.diffuse.contents = NSColor.secondaryLabelColor
            marker.position = SCNVector3(Float(metres) / 10, 0.005, 0)
            scene.rootNode.addChildNode(marker)
            let label = SCNText(string: "\(metres) m", extrusionDepth: 0)
            label.font = .monospacedSystemFont(ofSize: 1, weight: .regular)
            label.firstMaterial?.diffuse.contents = NSColor.labelColor
            let labelNode = SCNNode(geometry: label)
            let (minimum, maximum) = labelNode.boundingBox
            labelNode.pivot = SCNMatrix4MakeTranslation((minimum.x + maximum.x) / 2, 0, 0)
            labelNode.scale = SCNVector3(0.3, 0.3, 0.3)
            labelNode.position = SCNVector3(Float(metres) / 10, 0.05, 1.45)
            scene.rootNode.addChildNode(labelNode)
        }

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
        camera.usesOrthographicProjection = true
        camera.projectionDirection = .horizontal
        camera.orthographicScale = 10
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 6, 12)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 850
        let keyLightNode = SCNNode()
        keyLightNode.light = keyLight
        keyLightNode.eulerAngles = SCNVector3(-0.75, 0.7, 0)
        scene.rootNode.addChildNode(keyLightNode)

        scene.lightingEnvironment.intensity = 0.7
        return scene
    }

    private static func update(scene: SCNScene, force: Double, mass: Double, displacement: Double) {
        let massScale = Float(0.75 + mass * 0.05)
        let arrowLength = Float(0.55 + abs(force) / 30)
        let direction: Float = force < 0 ? -1 : 1
        let position = Float(displacement / 10)
        let arrowBaseX = position + direction * 0.58 * massScale
        let arrowY = 0.36 * massScale

        SCNTransaction.begin()
        SCNTransaction.disableActions = true
        if let box = scene.rootNode.childNode(withName: "mass-block", recursively: false) {
            box.scale = SCNVector3(massScale, massScale, massScale)
            box.position = SCNVector3(position, arrowY, 0)
        }
        if let shaft = scene.rootNode.childNode(withName: "force-shaft", recursively: false) {
            shaft.isHidden = force == 0
            shaft.scale = SCNVector3(1, arrowLength, 1)
            shaft.eulerAngles.z = -CGFloat(direction) * .pi / 2
            shaft.position = SCNVector3(arrowBaseX + direction * arrowLength / 2, arrowY, 0)
        }
        if let head = scene.rootNode.childNode(withName: "force-head", recursively: false) {
            head.isHidden = force == 0
            head.eulerAngles.z = -CGFloat(direction) * .pi / 2
            head.position = SCNVector3(arrowBaseX + direction * (arrowLength + 0.14), arrowY, 0)
        }
        SCNTransaction.commit()
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

private struct MomentumCollisionLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var firstMass = 2.0
    @State private var firstVelocity = 4.0
    @State private var secondMass = 2.0
    @State private var secondVelocity = -2.0
    @State private var showingAfter = false
    @State private var prediction: Int?
    @State private var selectedMode: CollisionOutcomeMode

    init(initialMode: CollisionOutcomeMode = .perfectlyInelastic) {
        _selectedMode = State(initialValue: initialMode)
    }

    private var collision: MomentumCollision {
        MomentumCollision(
            firstMass: firstMass,
            firstVelocity: firstVelocity,
            secondMass: secondMass,
            secondVelocity: secondVelocity
        )
    }

    private var correctPrediction: Int {
        if abs(firstFinalVelocity) < 0.05 { return 1 }
        return firstFinalVelocity < 0 ? 0 : 2
    }

    private var elasticCollision: ElasticCollision {
        ElasticCollision(
            firstMass: firstMass,
            firstVelocity: firstVelocity,
            secondMass: secondMass,
            secondVelocity: secondVelocity
        )
    }

    private var firstFinalVelocity: Double {
        selectedMode == .elastic ? elasticCollision.firstFinalVelocity : collision.finalVelocity
    }

    private var secondFinalVelocity: Double {
        selectedMode == .elastic ? elasticCollision.secondFinalVelocity : collision.finalVelocity
    }

    private var momentumBefore: Double {
        selectedMode == .elastic ? elasticCollision.momentumBefore : collision.momentumBefore
    }

    private var momentumAfter: Double {
        selectedMode == .elastic ? elasticCollision.momentumAfter : collision.momentumAfter
    }

    private var kineticEnergyBefore: Double {
        selectedMode == .elastic ? elasticCollision.kineticEnergyBefore : collision.kineticEnergyBefore
    }

    private var kineticEnergyAfter: Double {
        selectedMode == .elastic ? elasticCollision.kineticEnergyAfter : collision.kineticEnergyAfter
    }

    private var kineticEnergyConverted: Double {
        max(0, kineticEnergyBefore - kineticEnergyAfter)
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.momentumHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Canvas { context, size in
                let baseline = size.height * 0.69
                var track = Path()
                track.move(to: CGPoint(x: 18, y: baseline))
                track.addLine(to: CGPoint(x: size.width - 18, y: baseline))
                context.stroke(track, with: .color(.secondary.opacity(0.45)), lineWidth: 2)

                if showingAfter {
                    if selectedMode == .elastic {
                        let firstX = size.width * 0.31
                        let secondX = size.width * 0.69
                        drawBlock(
                            in: &context,
                            centerX: firstX,
                            baseline: baseline,
                            width: CGFloat(min(92, 34 + firstMass * 6)),
                            height: 38,
                            label: String(format: L10n.text("lab.momentumCart", store.language), 1, firstMass),
                            color: .blue
                        )
                        drawBlock(
                            in: &context,
                            centerX: secondX,
                            baseline: baseline,
                            width: CGFloat(min(92, 34 + secondMass * 6)),
                            height: 38,
                            label: String(format: L10n.text("lab.momentumCart", store.language), 2, secondMass),
                            color: .orange
                        )
                        drawVelocityArrow(in: &context, centerX: firstX, baseline: baseline, velocity: firstFinalVelocity, label: nil)
                        drawVelocityArrow(in: &context, centerX: secondX, baseline: baseline, velocity: secondFinalVelocity, label: nil)
                    } else {
                        drawBlock(
                            in: &context,
                            centerX: size.width * 0.5,
                            baseline: baseline,
                            width: CGFloat(min(128, 42 + collision.totalMass * 5)),
                            height: 43,
                            label: String(format: L10n.text("lab.momentumJoinedMass", store.language), collision.totalMass),
                            color: .purple
                        )
                        drawVelocityArrow(
                            in: &context,
                            centerX: size.width * 0.5,
                            baseline: baseline,
                            velocity: collision.finalVelocity,
                            label: String(format: L10n.text("lab.momentumVelocity", store.language), collision.finalVelocity)
                        )
                    }
                } else {
                    let firstX = size.width * 0.28
                    let secondX = size.width * 0.72
                    drawBlock(
                        in: &context,
                        centerX: firstX,
                        baseline: baseline,
                        width: CGFloat(min(92, 34 + firstMass * 6)),
                        height: 38,
                        label: String(format: L10n.text("lab.momentumCart", store.language), 1, firstMass),
                        color: .blue
                    )
                    drawBlock(
                        in: &context,
                        centerX: secondX,
                        baseline: baseline,
                        width: CGFloat(min(92, 34 + secondMass * 6)),
                        height: 38,
                        label: String(format: L10n.text("lab.momentumCart", store.language), 2, secondMass),
                        color: .orange
                    )
                    drawVelocityArrow(in: &context, centerX: firstX, baseline: baseline, velocity: firstVelocity, label: nil)
                    drawVelocityArrow(in: &context, centerX: secondX, baseline: baseline, velocity: secondVelocity, label: nil)
                }
            }
            .frame(height: 160)
            .accessibilityLabel(Text(L10n.text("lab.momentumCanvas", store.language)))

            Picker(L10n.text("lab.momentumStage", store.language), selection: $showingAfter) {
                Text(L10n.text("lab.momentumBefore", store.language)).tag(false)
                Text(L10n.text("lab.momentumAfter", store.language)).tag(true)
            }
            .pickerStyle(.segmented)

            Picker(L10n.text("lab.collisionType", store.language), selection: $selectedMode) {
                Text(L10n.text("lab.collisionInelastic", store.language)).tag(CollisionOutcomeMode.perfectlyInelastic)
                Text(L10n.text("lab.collisionElastic", store.language)).tag(CollisionOutcomeMode.elastic)
            }
            .pickerStyle(.segmented)

            Text(L10n.text(
                selectedMode == .elastic ? "lab.collisionElasticHint" : "lab.collisionInelasticHint",
                store.language
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Text("p = mv   ·   J = Δp = Fₙₑₜ Δt")
                .font(.system(.headline, design: .monospaced))
            valueSlider(title: L10n.text("lab.momentumMassOne", store.language), value: $firstMass, range: 1...8, step: 1, suffix: " kg")
            valueSlider(title: L10n.text("lab.momentumVelocityOne", store.language), value: $firstVelocity, range: -8...8, step: 1, suffix: " m/s")
            valueSlider(title: L10n.text("lab.momentumMassTwo", store.language), value: $secondMass, range: 1...8, step: 1, suffix: " kg")
            valueSlider(title: L10n.text("lab.momentumVelocityTwo", store.language), value: $secondVelocity, range: -8...8, step: 1, suffix: " m/s")

            HStack(alignment: .firstTextBaseline, spacing: 18) {
                readout(title: L10n.text("lab.momentumBeforeValue", store.language), value: momentumBefore, unit: "kg·m/s")
                readout(title: L10n.text("lab.momentumAfterValue", store.language), value: momentumAfter, unit: "kg·m/s")
            }
            HStack(alignment: .firstTextBaseline, spacing: 18) {
                readout(title: L10n.text("lab.momentumEnergyBefore", store.language), value: kineticEnergyBefore, unit: "J")
                readout(title: L10n.text("lab.momentumEnergyAfter", store.language), value: kineticEnergyAfter, unit: "J")
                readout(title: L10n.text("lab.momentumEnergyConverted", store.language), value: kineticEnergyConverted, unit: "J")
            }

            Text(L10n.text(
                selectedMode == .elastic ? "lab.collisionPredictFirst" : "lab.momentumPredict",
                store.language
            ))
                .font(.headline)
            HStack {
                predictionButton(title: L10n.text("lab.momentumLeft", store.language), tag: 0)
                predictionButton(title: L10n.text("lab.momentumRest", store.language), tag: 1)
                predictionButton(title: L10n.text("lab.momentumRight", store.language), tag: 2)
            }
            if let prediction {
                Label(
                    L10n.text(prediction == correctPrediction ? "lab.momentumCorrect" : "lab.momentumTryAgain", store.language),
                    systemImage: prediction == correctPrediction ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                )
                .font(.callout)
                .foregroundStyle(prediction == correctPrediction ? Color.green : Color.orange)
            }
            Text(L10n.text(
                selectedMode == .elastic ? "lab.collisionElasticLimit" : "lab.momentumLimit",
                store.language
            ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onChange(of: firstMass) { _ in prediction = nil }
        .onChange(of: firstVelocity) { _ in prediction = nil }
        .onChange(of: secondMass) { _ in prediction = nil }
        .onChange(of: secondVelocity) { _ in prediction = nil }
        .onChange(of: selectedMode) { _ in prediction = nil }
    }

    private func drawBlock(
        in context: inout GraphicsContext,
        centerX: CGFloat,
        baseline: CGFloat,
        width: CGFloat,
        height: CGFloat,
        label: String,
        color: Color
    ) {
        let rect = CGRect(x: centerX - width / 2, y: baseline - height, width: width, height: height)
        context.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(color.opacity(0.78)))
        context.draw(Text(label).font(.caption.weight(.semibold)).foregroundColor(.primary), at: CGPoint(x: centerX, y: rect.minY - 13))
    }

    private func drawVelocityArrow(
        in context: inout GraphicsContext,
        centerX: CGFloat,
        baseline: CGFloat,
        velocity: Double,
        label: String?
    ) {
        let direction: CGFloat = velocity < 0 ? -1 : 1
        let length = CGFloat(min(62, max(12, abs(velocity) * 8)))
        let start = CGPoint(x: centerX, y: baseline + 13)
        let end = CGPoint(x: centerX + direction * length, y: baseline + 13)
        var arrow = Path()
        arrow.move(to: start)
        arrow.addLine(to: end)
        arrow.move(to: end)
        arrow.addLine(to: CGPoint(x: end.x - direction * 8, y: end.y - 5))
        arrow.move(to: end)
        arrow.addLine(to: CGPoint(x: end.x - direction * 8, y: end.y + 5))
        context.stroke(arrow, with: .color(.primary), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        if let label {
            context.draw(Text(label).font(.caption.monospacedDigit()).foregroundColor(.secondary), at: CGPoint(x: centerX, y: baseline + 34))
        }
    }

    private func valueSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue, specifier: "%.0f")\(suffix)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
                .accessibilityLabel(Text(title))
        }
    }

    private func readout(title: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(value, specifier: "%.1f") \(unit)")
                .font(.callout.monospacedDigit().weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }

    private func predictionButton(title: String, tag: Int) -> some View {
        Button(title) { prediction = tag }
            .buttonStyle(.bordered)
            .tint(prediction == tag ? .accentColor : nil)
            .accessibilityAddTraits(prediction == tag ? .isSelected : [])
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

private struct GeneRegulationLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var variant = 0
    @State private var signalPresent = true
    @State private var selectedAnswer: Int?
    @State private var optionOrder = QuizAnswerOrder(optionCount: 2, answerOriginalIndex: 1)

    private var productMade: Bool { variant == 0 && signalPresent }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.dnaModelHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)

            Picker(L10n.text("lab.dnaVariant", store.language), selection: $variant) {
                Text(L10n.text("lab.dnaVariant0", store.language)).tag(0)
                Text(L10n.text("lab.dnaVariant1", store.language)).tag(1)
            }
            .pickerStyle(.segmented)
            .onChange(of: variant) { _ in
                selectedAnswer = nil
                optionOrder = QuizAnswerOrder(optionCount: 2, answerOriginalIndex: 1)
            }

            DNAHelixVisualization(variant: variant)
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel(Text(L10n.text("lab.dna3DHint", store.language)))
            Text(L10n.text("lab.dna3DHint", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(L10n.text(variant == 0 ? "lab.dnaPairAT" : "lab.dnaPairCG", store.language))
                .font(.callout.weight(.medium))
                .accessibilityLabel(Text(L10n.text(variant == 0 ? "lab.dnaPairAT" : "lab.dnaPairCG", store.language)))

            Toggle(L10n.text("lab.dnaSignal", store.language), isOn: $signalPresent)
                .onChange(of: signalPresent) { _ in
                    selectedAnswer = nil
                    optionOrder = QuizAnswerOrder(optionCount: 2, answerOriginalIndex: 1)
                }

            HStack(spacing: 8) {
                flowNode(title: L10n.text("lab.dnaSequence", store.language), value: "A · T · C · G")
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                flowNode(
                    title: L10n.text("lab.dnaGeneActivity", store.language),
                    value: L10n.text(productMade ? "lab.dnaGeneOn" : "lab.dnaGeneOff", store.language)
                )
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                flowNode(
                    title: L10n.text("lab.dnaProduct", store.language),
                    value: L10n.text(productMade ? "lab.dnaProductMade" : "lab.dnaProductAbsent", store.language)
                )
            }
            .accessibilityElement(children: .combine)

            Text(L10n.text("lab.dnaPredict", store.language))
                .font(.callout.weight(.medium))
            HStack {
                ForEach(Array(optionOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                    answerButton(
                        displayIndex,
                        key: originalIndex == 0 ? "lab.dnaPredictOption0" : "lab.dnaPredictOption1"
                    )
                }
            }

            if let selectedAnswer {
                let isCorrect = optionOrder.isCorrect(displayedIndex: selectedAnswer)
                Label(
                    L10n.text(
                        isCorrect ? "lab.dnaPredictCorrect" : "lab.dnaPredictIncorrect",
                        store.language
                    ),
                    systemImage: isCorrect ? "checkmark.circle.fill" : "arrow.clockwise.circle"
                )
                .font(.callout)
                .foregroundStyle(isCorrect ? Color.green : Color.secondary)
            }
        }
    }

    private func flowNode(title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.callout.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: .infinity)
    }

    private func answerButton(_ answer: Int, key: String) -> some View {
        Button {
            selectedAnswer = answer
        } label: {
            Text(L10n.text(key, store.language))
                .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.bordered)
        .tint(selectedAnswer == answer ? Color.accentColor : nil)
        .accessibilityAddTraits(selectedAnswer == answer ? .isSelected : [])
    }
}

private struct GeneExpressionLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var transcriptionEnabled = true
    @State private var selectedStage = 0
    @State private var selectedAnswer = -1
    @State private var didCheckAnswer = false
    @State private var optionOrder = QuizAnswerOrder(optionCount: 3, answerOriginalIndex: 1)

    private let answerOptionKeys = [
        "lab.geneExpressionOptionA",
        "lab.geneExpressionOptionB",
        "lab.geneExpressionOptionC"
    ]

    private var snapshot: GeneExpressionSnapshot {
        GeneExpressionPractice.snapshot(promoterIsActive: transcriptionEnabled)
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.geneExpressionHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(L10n.text("lab.geneExpressionRegulator", store.language), isOn: $transcriptionEnabled)
                .onChange(of: transcriptionEnabled) { _ in
                    selectedAnswer = -1
                    didCheckAnswer = false
                    optionOrder = QuizAnswerOrder(optionCount: 3, answerOriginalIndex: 1)
                }

            Picker(L10n.text("lab.geneExpressionStage", store.language), selection: $selectedStage) {
                Text(L10n.text("lab.geneExpressionDNA", store.language)).tag(0)
                Text(L10n.text("lab.geneExpressionRNA", store.language)).tag(1)
                Text(L10n.text("lab.geneExpressionProtein", store.language)).tag(2)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text(stageTitleKey, store.language))
                    .font(.headline)
                Text(stageValue)
                    .font(.title3.monospaced())
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.text(stageExplanationKey, store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)

            Text(L10n.text("lab.geneExpressionQuiz", store.language))
                .font(.callout.weight(.medium))
            Picker(L10n.text("lab.geneExpressionQuiz", store.language), selection: $selectedAnswer) {
                ForEach(Array(optionOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Text(L10n.text(answerOptionKeys[originalIndex], store.language)).tag(displayIndex)
                }
            }
            .pickerStyle(.radioGroup)
            .onChange(of: selectedAnswer) { _ in didCheckAnswer = false }

            Button(L10n.text("lab.geneExpressionCheck", store.language)) {
                didCheckAnswer = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedAnswer < 0)

            if didCheckAnswer {
                let isCorrect = optionOrder.isCorrect(displayedIndex: selectedAnswer)
                Label(
                    L10n.text(isCorrect ? "lab.geneExpressionCorrect" : "lab.geneExpressionReview", store.language),
                    systemImage: isCorrect ? "checkmark.circle.fill" : "arrow.uturn.backward.circle"
                )
                .font(.callout.weight(.medium))
                .foregroundStyle(isCorrect ? .green : .orange)
                .fixedSize(horizontal: false, vertical: true)
            }

            Text(L10n.text("lab.geneExpressionLimit", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stageTitleKey: String {
        ["lab.geneExpressionDNA", "lab.geneExpressionRNA", "lab.geneExpressionProtein"][selectedStage]
    }

    private var stageExplanationKey: String {
        ["lab.geneExpressionDNAExplain", "lab.geneExpressionRNAExplain", "lab.geneExpressionProteinExplain"][selectedStage]
    }

    private var stageValue: String {
        switch selectedStage {
        case 0:
            return "3′ \(GeneExpressionPractice.templateStrand) 5′"
        case 1:
            guard let messengerRNA = snapshot.messengerRNA else {
                return L10n.text("lab.geneExpressionNoTranscript", store.language)
            }
            return "5′ \(messengerRNA) 3′"
        default:
            guard let peptide = snapshot.peptide else {
                return L10n.text("lab.geneExpressionNoProtein", store.language)
            }
            return peptide.joined(separator: " – ")
        }
    }
}

private struct CellCycleLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var selectedStage: CellCycleStage = .g1
    @State private var selectedAnswer = -1
    @State private var didCheckAnswer = false
    @State private var optionOrder = QuizAnswerOrder(optionCount: 3, answerOriginalIndex: 0)

    private let answerOptionKeys = [
        "lab.cellCycle.optionS",
        "lab.cellCycle.optionAnaphase",
        "lab.cellCycle.optionCytokinesis"
    ]

    var body: some View {
        LabCard {
            Text(L10n.text("lab.cellCycle.hint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker(L10n.text("lab.cellCycle.chooseStage", store.language), selection: $selectedStage) {
                ForEach(CellCycleStage.allCases) { stage in
                    Text(L10n.text(stage.localizationKey, store.language)).tag(stage)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedStage) { _ in
                selectedAnswer = -1
                didCheckAnswer = false
                optionOrder = QuizAnswerOrder(optionCount: 3, answerOriginalIndex: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text(selectedStage.localizationKey, store.language))
                    .font(.headline)
                Text(L10n.text("lab.cellCycle.explain.\(selectedStage.rawValue)", store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.text(statusKey, store.language))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)

            HStack {
                Button(L10n.text("lab.cellCycle.previous", store.language)) {
                    move(by: -1)
                }
                .disabled(selectedStage == CellCycleStage.allCases.first)
                Spacer()
                Text("\((CellCycleStage.allCases.firstIndex(of: selectedStage) ?? 0) + 1) / \(CellCycleStage.allCases.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(L10n.text("lab.cellCycle.position", store.language))
                Spacer()
                Button(L10n.text("lab.cellCycle.next", store.language)) {
                    move(by: 1)
                }
                .disabled(selectedStage == CellCycleStage.allCases.last)
            }

            Text(L10n.text("lab.cellCycle.quiz", store.language))
                .font(.callout.weight(.medium))
            Picker(L10n.text("lab.cellCycle.quiz", store.language), selection: $selectedAnswer) {
                ForEach(Array(optionOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Text(L10n.text(answerOptionKeys[originalIndex], store.language)).tag(displayIndex)
                }
            }
            .pickerStyle(.radioGroup)
            .onChange(of: selectedAnswer) { _ in didCheckAnswer = false }

            Button(L10n.text("lab.cellCycle.check", store.language)) {
                didCheckAnswer = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedAnswer < 0)

            if didCheckAnswer {
                let correct = optionOrder.isCorrect(displayedIndex: selectedAnswer)
                Label(
                    L10n.text(correct ? "lab.cellCycle.correct" : "lab.cellCycle.review", store.language),
                    systemImage: correct ? "checkmark.circle.fill" : "arrow.uturn.backward.circle"
                )
                .font(.callout.weight(.medium))
                .foregroundStyle(correct ? .green : .orange)
                .fixedSize(horizontal: false, vertical: true)
            }

            Text(L10n.text("lab.cellCycle.limit", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusKey: String {
        if CellCyclePractice.isDNAReplicationStage(selectedStage) { return "lab.cellCycle.statusDNA" }
        if CellCyclePractice.isNuclearDivision(selectedStage) { return "lab.cellCycle.statusNucleus" }
        if CellCyclePractice.isCytoplasmDivision(selectedStage) { return "lab.cellCycle.statusCytoplasm" }
        if selectedStage == .differentiation { return "lab.cellCycle.statusSpecialize" }
        return "lab.cellCycle.statusPrepare"
    }

    private func move(by offset: Int) {
        guard let index = CellCycleStage.allCases.firstIndex(of: selectedStage) else { return }
        let nextIndex = index + offset
        guard CellCycleStage.allCases.indices.contains(nextIndex) else { return }
        selectedStage = CellCycleStage.allCases[nextIndex]
    }
}

private struct AnimalFunctionLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var selectedFunction: AnimalFunction = .feeding
    @State private var selectedAnswer = -1
    @State private var didCheckAnswer = false
    @State private var optionOrder = QuizAnswerOrder(
        optionCount: 3,
        answerOriginalIndex: AnimalFunctionPractice.correctComparisonAnswer
    )

    private let answerOptionKeys = [
        "lab.zoology.optionA",
        "lab.zoology.optionB",
        "lab.zoology.optionC"
    ]

    var body: some View {
        LabCard {
            Text(L10n.text("lab.zoology.hint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker(L10n.text("lab.zoology.chooseFunction", store.language), selection: $selectedFunction) {
                ForEach(AnimalFunction.allCases) { function in
                    Text(L10n.text(function.titleKey, store.language)).tag(function)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedFunction) { _ in
                selectedAnswer = -1
                didCheckAnswer = false
                optionOrder = QuizAnswerOrder(
                    optionCount: 3,
                    answerOriginalIndex: AnimalFunctionPractice.correctComparisonAnswer
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(L10n.text(selectedFunction.titleKey, store.language), systemImage: systemSymbol)
                    .font(.headline)
                Text(L10n.text(selectedFunction.exampleKey, store.language))
                    .font(.callout.weight(.medium))
                Text(L10n.text(selectedFunction.mechanismKey, store.language))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.text(selectedFunction.limitationKey, store.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)

            Text(L10n.text("lab.zoology.quiz", store.language))
                .font(.callout.weight(.medium))
            Picker(L10n.text("lab.zoology.quiz", store.language), selection: $selectedAnswer) {
                ForEach(Array(optionOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Text(L10n.text(answerOptionKeys[originalIndex], store.language)).tag(displayIndex)
                }
            }
            .pickerStyle(.radioGroup)
            .onChange(of: selectedAnswer) { _ in didCheckAnswer = false }

            Button(L10n.text("lab.zoology.check", store.language)) {
                didCheckAnswer = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedAnswer < 0)

            if didCheckAnswer {
                let correct = optionOrder.isCorrect(displayedIndex: selectedAnswer)
                Label(
                    L10n.text(correct ? "lab.zoology.correct" : "lab.zoology.review", store.language),
                    systemImage: correct ? "checkmark.circle.fill" : "arrow.uturn.backward.circle"
                )
                .font(.callout.weight(.medium))
                .foregroundStyle(correct ? .green : .orange)
                .fixedSize(horizontal: false, vertical: true)
            }

            Text(L10n.text("lab.zoology.limit", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var systemSymbol: String {
        switch selectedFunction {
        case .feeding: return "fork.knife"
        case .gasExchange: return "wind"
        case .movement: return "figure.walk"
        case .reproduction: return "leaf"
        }
    }
}

private struct DNAHelixVisualization: NSViewRepresentable {
    let variant: Int

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = Self.makeScene(variant: variant)
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .controlBackgroundColor
        return view
    }

    func updateNSView(_ view: SCNView, context: Context) {
        guard let rung = view.scene?.rootNode.childNode(withName: "model-variant-rung", recursively: false) else { return }
        rung.geometry?.firstMaterial?.diffuse.contents = Self.variantColor(variant)
    }

    private static func makeScene(variant: Int) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor.controlBackgroundColor

        let backboneMaterial = SCNMaterial()
        backboneMaterial.diffuse.contents = NSColor.systemBlue
        backboneMaterial.roughness.contents = 0.46

        let complementaryMaterial = SCNMaterial()
        complementaryMaterial.diffuse.contents = NSColor.systemOrange
        complementaryMaterial.roughness.contents = 0.46

        let rungMaterials = [backboneMaterial, complementaryMaterial]
        let stepCount = 20
        let radius: Float = 0.58
        let verticalStep: Float = 0.16
        let twist = 2 * Float.pi / 10
        var firstStrand: [SCNVector3] = []
        var secondStrand: [SCNVector3] = []

        for index in 0..<stepCount {
            let angle = Float(index) * twist
            let height = (Float(index) - Float(stepCount - 1) / 2) * verticalStep
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            let first = SCNVector3(x, y, height)
            let second = SCNVector3(-x, -y, height)
            firstStrand.append(first)
            secondStrand.append(second)

            let firstBead = SCNNode(geometry: SCNSphere(radius: 0.055))
            firstBead.geometry?.firstMaterial = backboneMaterial
            firstBead.position = first
            scene.rootNode.addChildNode(firstBead)

            let secondBead = SCNNode(geometry: SCNSphere(radius: 0.055))
            secondBead.geometry?.firstMaterial = complementaryMaterial
            secondBead.position = second
            scene.rootNode.addChildNode(secondBead)

            let rung = SCNCylinder(radius: 0.026, height: CGFloat(radius * 2))
            rung.firstMaterial = rungMaterials[index.isMultiple(of: 2) ? 0 : 1]
            let rungNode = segmentNode(from: first, to: second, geometry: rung)
            if index == stepCount / 2 {
                rungNode.name = "model-variant-rung"
                rung.firstMaterial = SCNMaterial()
                rung.firstMaterial?.diffuse.contents = variantColor(variant)
                rung.firstMaterial?.roughness.contents = 0.42
            }
            scene.rootNode.addChildNode(rungNode)
        }

        for index in 0..<(stepCount - 1) {
            let firstRail = SCNCylinder(radius: 0.018, height: distance(firstStrand[index], firstStrand[index + 1]))
            firstRail.firstMaterial = backboneMaterial
            scene.rootNode.addChildNode(segmentNode(from: firstStrand[index], to: firstStrand[index + 1], geometry: firstRail))

            let secondRail = SCNCylinder(radius: 0.018, height: distance(secondStrand[index], secondStrand[index + 1]))
            secondRail.firstMaterial = complementaryMaterial
            scene.rootNode.addChildNode(segmentNode(from: secondStrand[index], to: secondStrand[index + 1], geometry: secondRail))
        }

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 4.2
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, -5.2, 0.25)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        let light = SCNLight()
        light.type = .omni
        light.intensity = 620
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(-2, -3, 4)
        scene.rootNode.addChildNode(lightNode)
        scene.lightingEnvironment.intensity = 0.65
        return scene
    }

    private static func segmentNode(from start: SCNVector3, to end: SCNVector3, geometry: SCNGeometry) -> SCNNode {
        let direction = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
        let length = distance(start, end)
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3((start.x + end.x) / 2, (start.y + end.y) / 2, (start.z + end.z) / 2)

        let normalized = SCNVector3(direction.x / length, direction.y / length, direction.z / length)
        let dot = normalized.y
        if dot < -0.9999 {
            node.orientation = SCNQuaternion(1, 0, 0, 0)
        } else {
            let cross = SCNVector3(normalized.z, 0, -normalized.x)
            let scale = sqrt(2 * (1 + dot))
            let inverseScale = 1 / scale
            node.orientation = SCNQuaternion(
                cross.x * inverseScale,
                cross.y * inverseScale,
                cross.z * inverseScale,
                scale / 2
            )
        }
        return node
    }

    private static func distance(_ first: SCNVector3, _ second: SCNVector3) -> CGFloat {
        let x = second.x - first.x
        let y = second.y - first.y
        let z = second.z - first.z
        let squaredDistance = x * x + y * y + z * z
        return sqrt(squaredDistance)
    }

    private static func variantColor(_ variant: Int) -> NSColor {
        variant == 0 ? .systemYellow : .systemPurple
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

private struct BiomoleculeLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var selectedExample = "enzyme"
    @State private var selectedGroup = "protein"
    @State private var checked = false
    @State private var reactionJoins = true

    private let examples = ["enzyme", "starch", "dna", "triglyceride"]
    private let groups = ["carbohydrate", "lipid", "protein", "nucleic_acid"]

    private var correctGroup: String {
        switch selectedExample {
        case "enzyme": "protein"
        case "starch": "carbohydrate"
        case "dna": "nucleic_acid"
        default: "lipid"
        }
    }

    private var exampleInfoKey: String {
        switch selectedExample {
        case "enzyme": "biology.moleculeLab.info.enzyme"
        case "starch": "biology.moleculeLab.info.starch"
        case "dna": "biology.moleculeLab.info.dna"
        default: "biology.moleculeLab.info.triglyceride"
        }
    }

    var body: some View {
        LabCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.teal)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.text("biology.moleculeLab.title", store.language))
                            .font(.headline)
                        Text(L10n.text("biology.moleculeLab.subtitle", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Picker(L10n.text("biology.moleculeLab.example", store.language), selection: $selectedExample) {
                    ForEach(examples, id: \.self) { example in
                        Text(L10n.text("biology.moleculeLab.\(example)", store.language)).tag(example)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedExample) { example in
                    switch example {
                    case "enzyme": selectedGroup = "protein"
                    case "starch": selectedGroup = "carbohydrate"
                    case "dna": selectedGroup = "nucleic_acid"
                    default: selectedGroup = "lipid"
                    }
                    checked = false
                }

                Picker(L10n.text("biology.moleculeLab.chooseGroup", store.language), selection: $selectedGroup) {
                    ForEach(groups, id: \.self) { group in
                        Text(L10n.text("biology.moleculeLab.group.\(group)", store.language)).tag(group)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedGroup) { _ in checked = false }

                Button {
                    checked = true
                } label: {
                    Label(L10n.text("biology.moleculeLab.check", store.language), systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)

                if checked {
                    Label(
                        L10n.text(selectedGroup == correctGroup ? "biology.moleculeLab.correct" : "biology.moleculeLab.tryAgain", store.language),
                        systemImage: selectedGroup == correctGroup ? "checkmark.circle.fill" : "arrow.uturn.backward.circle"
                    )
                    .font(.callout.weight(.medium))
                    .foregroundStyle(selectedGroup == correctGroup ? .green : .orange)
                }

                Text(L10n.text(exampleInfoKey, store.language))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 9))

                Divider()

                HStack {
                    Text(L10n.text("biology.moleculeLab.reaction", store.language))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Picker("", selection: $reactionJoins) {
                        Text(L10n.text("biology.moleculeLab.join", store.language)).tag(true)
                        Text(L10n.text("biology.moleculeLab.split", store.language)).tag(false)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                }

                HStack(spacing: 10) {
                    Text(L10n.text(reactionJoins ? "biology.moleculeLab.components" : "biology.moleculeLab.polymer", store.language))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(.background, in: RoundedRectangle(cornerRadius: 9))
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(L10n.text(reactionJoins ? "biology.moleculeLab.polymer" : "biology.moleculeLab.components", store.language))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(.background, in: RoundedRectangle(cornerRadius: 9))
                    Text(L10n.text(reactionJoins ? "biology.moleculeLab.waterOut" : "biology.moleculeLab.waterIn", store.language))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.teal)
                }
                .font(.caption)

                Text(L10n.text("biology.moleculeLab.caveat", store.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct NaturalSelectionLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var environmentOptimum = 75.0
    @State private var selectionStrength = 0.45
    @State private var heritability = 0.8
    @State private var traitMean = 35.0
    @State private var traitSpread = 20.0
    @State private var generation = 0

    var body: some View {
        LabCard {
            VStack(alignment: .leading, spacing: 12) {
                header
                distributionChart
                chartLegend
                populationSummary
                controls
                actions
                limitations
            }
        }
    }

    private var header: some View {
        Label(L10n.text("biology.selectionLab.title", store.language), systemImage: "chart.xyaxis.line")
            .font(.headline)
    }

    private var distributionChart: some View {
        Canvas { context, size in
            var curve = Path()
            for step in 0...100 {
                let trait = Double(step)
                let distance = (trait - traitMean) / max(traitSpread, 1)
                let height = exp(-0.5 * distance * distance)
                let point = CGPoint(
                    x: CGFloat(step) / 100 * size.width,
                    y: size.height - 8 - CGFloat(height) * max(0, size.height - 18)
                )
                if step == 0 { curve.move(to: point) } else { curve.addLine(to: point) }
            }
            context.stroke(curve, with: .color(.teal), lineWidth: 2.5)
            drawMarker(traitMean, color: .teal, context: context, size: size)
            drawMarker(environmentOptimum, color: .orange, context: context, size: size)
        }
        .frame(height: 116)
        .padding(.horizontal, 4)
        .accessibilityLabel(Text(L10n.text("biology.selectionLab.chart", store.language)))
    }

    private var chartLegend: some View {
        HStack {
            Label(L10n.text("biology.selectionLab.mean", store.language), systemImage: "line.diagonal")
                .foregroundStyle(.teal)
            Spacer()
            Label(L10n.text("biology.selectionLab.environment", store.language), systemImage: "line.diagonal")
                .foregroundStyle(.orange)
        }
        .font(.caption)
    }

    private var populationSummary: some View {
        HStack {
            Text("\(L10n.text("biology.selectionLab.generation", store.language)) \(generation)")
            Spacer()
            Text("\(L10n.text("biology.selectionLab.meanValue", store.language)) \(traitMean, specifier: "%.1f")")
        }
        .font(.subheadline.monospacedDigit())
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            parameterSlider("biology.selectionLab.environment", value: $environmentOptimum, range: 0...100)
            parameterSlider("biology.selectionLab.strength", value: $selectionStrength)
            parameterSlider("biology.selectionLab.heritable", value: $heritability)
        }
    }

    private var actions: some View {
        HStack {
            Button(action: advanceGeneration) {
                Label(L10n.text("biology.selectionLab.next", store.language), systemImage: "forward.end.fill")
            }
            .buttonStyle(.borderedProminent)

            Button(action: resetSimulation) {
                Label(L10n.text("biology.selectionLab.reset", store.language), systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
        }
    }

    private var limitations: some View {
        Text(L10n.text("biology.selectionLab.limit", store.language))
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func drawMarker(_ value: Double, color: Color, context: GraphicsContext, size: CGSize) {
        let x = CGFloat(value / 100) * size.width
        var marker = Path()
        marker.move(to: CGPoint(x: x, y: 0))
        marker.addLine(to: CGPoint(x: x, y: size.height))
        context.stroke(marker, with: .color(color.opacity(0.75)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
    }

    private func advanceGeneration() {
        let response = (environmentOptimum - traitMean) * selectionStrength * heritability
        traitMean = min(100, max(0, traitMean + response))
        traitSpread = max(6, traitSpread * (1 - selectionStrength * 0.12))
        generation += 1
    }

    private func resetSimulation() {
        environmentOptimum = 75
        selectionStrength = 0.45
        heritability = 0.8
        traitMean = 35
        traitSpread = 20
        generation = 0
    }

    private func parameterSlider(
        _ labelKey: String,
        value: Binding<Double>,
        range: ClosedRange<Double> = 0...1
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(L10n.text(labelKey, store.language))
                Spacer()
                Text("\(value.wrappedValue, specifier: "%.2f")")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
                .accessibilityLabel(Text(L10n.text(labelKey, store.language)))
        }
        .font(.caption)
    }
}

private struct EcosystemEnergyLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var producerEnergy = 8_000.0
    @State private var transferFraction = 0.12

    private let levels = ["producers", "primary", "secondary", "tertiary"]
    private var energies: [Double] {
        levels.indices.map { producerEnergy * pow(transferFraction, Double($0)) }
    }

    var body: some View {
        LabCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.text("biology.energyLab.title", store.language), systemImage: "chart.bar.xaxis")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(L10n.text("biology.energy.level.\(level)", store.language))
                                Spacer()
                                Text("\(energies[index], specifier: "%.1f") kJ")
                                    .monospacedDigit()
                            }
                            .font(.caption.weight(.medium))
                            ProgressView(value: energies[index], total: producerEnergy)
                                .tint(levelColor(index))
                                .accessibilityLabel(Text(L10n.text("biology.energy.level.\(level)", store.language)))
                                .accessibilityValue(Text("\(energies[index], specifier: "%.1f") kJ"))
                        }
                    }
                }
                .padding(12)
                .background(.background, in: RoundedRectangle(cornerRadius: 10))

                energySlider(
                    key: "biology.energyLab.producerEnergy",
                    value: $producerEnergy,
                    range: 1_000...20_000,
                    format: "%.0f kJ"
                )
                energySlider(
                    key: "biology.energyLab.transfer",
                    value: $transferFraction,
                    range: 0.05...0.30,
                    format: "%.0f%%",
                    scale: 100
                )

                Text(L10n.text("biology.energyLab.limit", store.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func energySlider(
        key: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: String,
        scale: Double = 1
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(L10n.text(key, store.language))
                Spacer()
                Text(String(format: format, value.wrappedValue * scale))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
                .accessibilityLabel(Text(L10n.text(key, store.language)))
        }
        .font(.caption)
    }

    private func levelColor(_ index: Int) -> Color {
        switch index {
        case 0: .green
        case 1: .teal
        case 2: .orange
        default: .purple
        }
    }
}

private struct FoodWebLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var selectedNode = "algae"
    @State private var removedNode = "none"

    private let species = ["algae", "zooplankton", "snails", "smallFish", "heron"]

    private var visibleLinks: [PondFoodWebLink] {
        PondFoodWebModel.visibleLinks(excluding: removedNode)
    }

    private var directConsumers: [String] {
        PondFoodWebModel.directConsumers(of: removedNode)
    }

    var body: some View {
        LabCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.text("biology.foodWebLab.title", store.language), systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.headline)

                Text(L10n.text("biology.foodWebLab.arrow", store.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                diagram
                    .frame(height: 280)
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .contain)

                selectedNodeDetails

                Picker(L10n.text("biology.foodWebLab.scenario", store.language), selection: $removedNode) {
                    Text(L10n.text("biology.foodWebLab.none", store.language)).tag("none")
                    ForEach(species, id: \.self) { id in
                        Text(nodeName(id)).tag(id)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: removedNode) { newValue in
                    if selectedNode == newValue { selectedNode = "none" }
                }

                if removedNode != "none" {
                    removalSummary
                }

                Text(L10n.text("biology.foodWebLab.limit", store.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var diagram: some View {
        GeometryReader { geometry in
            ZStack {
                Canvas { context, size in
                    for link in visibleLinks {
                        guard let from = PondFoodWebModel.nodes.first(where: { $0.id == link.from }),
                              let to = PondFoodWebModel.nodes.first(where: { $0.id == link.to }) else { continue }
                        let start = CGPoint(x: from.x * size.width, y: from.y * size.height)
                        let end = CGPoint(x: to.x * size.width, y: to.y * size.height)
                        let dx = end.x - start.x
                        let dy = end.y - start.y
                        let distance = max(hypot(dx, dy), 1)
                        let ux = dx / distance
                        let uy = dy / distance
                        let lineStart = CGPoint(x: start.x + ux * 50, y: start.y + uy * 22)
                        let tip = CGPoint(x: end.x - ux * 51, y: end.y - uy * 22)
                        let base = CGPoint(x: tip.x - ux * 9, y: tip.y - uy * 9)
                        let opacity = selectedNode == "none" || link.from == selectedNode || link.to == selectedNode ? 0.78 : 0.16
                        var shaft = Path()
                        shaft.move(to: lineStart)
                        shaft.addLine(to: tip)
                        let isMatterCycle = link.kind == .matterCycle
                        let linkColor = isMatterCycle ? Color.teal : Color.secondary
                        context.stroke(
                            shaft,
                            with: .color(linkColor.opacity(opacity)),
                            style: StrokeStyle(lineWidth: 1.7, lineCap: .round, dash: isMatterCycle ? [4, 3] : [])
                        )

                        let wing = CGPoint(x: -uy * 4, y: ux * 4)
                        var arrow = Path()
                        arrow.move(to: tip)
                        arrow.addLine(to: CGPoint(x: base.x + wing.x, y: base.y + wing.y))
                        arrow.addLine(to: CGPoint(x: base.x - wing.x, y: base.y - wing.y))
                        arrow.closeSubpath()
                        context.fill(arrow, with: .color(linkColor.opacity(opacity)))
                    }
                }

                ForEach(PondFoodWebModel.nodes) { node in
                    if node.id != removedNode {
                        Button {
                            selectedNode = node.id
                        } label: {
                            Text(nodeName(node.id))
                                .font(.caption.weight(.medium))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .frame(width: 104, height: 42)
                                .background(node.id == selectedNode ? Color.accentColor.opacity(0.18) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 9))
                                .overlay(RoundedRectangle(cornerRadius: 9).stroke(nodeColor(node.kind).opacity(0.7), lineWidth: node.id == selectedNode ? 2 : 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(nodeName(node.id))
                        .accessibilityHint(Text(L10n.text("biology.foodWebLab.select", store.language)))
                        .position(x: node.x * geometry.size.width, y: node.y * geometry.size.height)
                    }
                }
            }
        }
        .accessibilityLabel(L10n.text("biology.foodWebLab.title", store.language))
    }

    private var selectedNodeDetails: some View {
        let incoming = PondFoodWebModel.incomingLinks(to: selectedNode, excluding: removedNode).map(\.from)
        let outgoing = PondFoodWebModel.outgoingLinks(from: selectedNode, excluding: removedNode).map(\.to)
        return VStack(alignment: .leading, spacing: 4) {
            Text(nodeName(selectedNode))
                .font(.subheadline.weight(.semibold))
            if !incoming.isEmpty {
                Text("\(L10n.text("biology.foodWebLab.incoming", store.language)): \(incoming.map(nodeName).joined(separator: ", "))")
            }
            if !outgoing.isEmpty {
                Text("\(L10n.text("biology.foodWebLab.outgoing", store.language)): \(outgoing.map(nodeName).joined(separator: ", "))")
            }
            if incoming.isEmpty && outgoing.isEmpty {
                Text(L10n.text("biology.foodWebLab.noDirectLinks", store.language))
            }
        }
        .font(.caption)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var removalSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.text("biology.foodWebLab.removal", store.language))
                .font(.caption.weight(.semibold))
            if directConsumers.isEmpty {
                Text(L10n.text("biology.foodWebLab.noConsumers", store.language))
                    .font(.caption)
            } else {
                Text(directConsumers.map(nodeName).joined(separator: ", "))
                    .font(.caption)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private func nodeName(_ id: String) -> String {
        if id == "none" { return L10n.text("biology.foodWebLab.network", store.language) }
        return L10n.text("biology.foodweb.node.\(id)", store.language)
    }

    private func nodeColor(_ kind: PondFoodWebNodeKind) -> Color {
        switch kind {
        case .producer: .green
        case .consumer: .orange
        case .decomposer: .purple
        case .matter: .teal
        }
    }
}

private struct EukaryoticCellLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var selectedPart = "nucleus"

    private let parts = ["membrane", "nucleus", "rough_er", "golgi", "mitochondria", "ribosomes", "lysosome"]

    var body: some View {
        LabCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(
                        L10n.text("lab.cell3d.title", store.language),
                        systemImage: "cube.transparent"
                    )
                    .font(.headline)
                    Spacer()
                    Text(L10n.text("lab.cell3d.rotateHint", store.language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                EukaryoticCellScene(selectedPart: selectedPart)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel(Text(L10n.text("lab.cell3d.accessibility", store.language)))

                Picker(L10n.text("lab.cellPart", store.language), selection: $selectedPart) {
                    ForEach(parts, id: \.self) { part in
                        Text(L10n.text("biology.cell3d.\(part)", store.language)).tag(part)
                    }
                }
                .pickerStyle(.menu)

                Text(L10n.text("biology.cell3d.\(selectedPart).function", store.language))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 10))

                Text(L10n.text("lab.cell3d.scaleNote", store.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct EukaryoticCellScene: NSViewRepresentable {
    let selectedPart: String

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = Self.makeScene()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .controlBackgroundColor
        view.antialiasingMode = .multisampling4X
        Self.highlight(selectedPart, in: view.scene)
        return view
    }

    func updateNSView(_ view: SCNView, context: Context) {
        Self.highlight(selectedPart, in: view.scene)
    }

    private static func makeScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor.controlBackgroundColor

        let membrane = SCNNode(geometry: SCNSphere(radius: 1.42))
        membrane.name = "organelle-membrane"
        membrane.geometry?.firstMaterial = material(.systemTeal, roughness: 0.35, transparency: 0.14)
        membrane.geometry?.firstMaterial?.isDoubleSided = true
        membrane.geometry?.firstMaterial?.fillMode = .lines
        scene.rootNode.addChildNode(membrane)

        let nucleus = SCNNode(geometry: SCNSphere(radius: 0.52))
        nucleus.name = "organelle-nucleus"
        nucleus.position = SCNVector3(-0.25, 0.08, 0.05)
        nucleus.geometry?.firstMaterial = material(.systemPurple)
        scene.rootNode.addChildNode(nucleus)

        let nucleolus = SCNNode(geometry: SCNSphere(radius: 0.15))
        nucleolus.position = SCNVector3(0.14, 0.02, 0.38)
        nucleolus.geometry?.firstMaterial = material(.systemPink)
        nucleus.addChildNode(nucleolus)

        let roughER = SCNNode()
        roughER.name = "organelle-rough_er"
        let roughERFolds: [(Float, Float, Float)] = [
            (-0.50, 0.48, -0.06), (-0.56, 0.19, 0.01), (-0.52, -0.13, -0.08), (-0.37, -0.40, -0.02),
        ]
        for (index, offset) in roughERFolds.enumerated() {
            let fold = SCNNode(geometry: SCNTorus(ringRadius: 0.39 - CGFloat(index) * 0.025, pipeRadius: 0.035))
            fold.position = SCNVector3(offset.0, offset.1, offset.2)
            fold.geometry?.firstMaterial = material(.systemOrange)
            roughER.addChildNode(fold)
        }
        scene.rootNode.addChildNode(roughER)

        let golgi = SCNNode()
        golgi.name = "organelle-golgi"
        for index in 0..<4 {
            let cisterna = SCNNode(geometry: SCNCapsule(capRadius: 0.07, height: 0.72))
            cisterna.eulerAngles.z = .pi / 2
            cisterna.position = SCNVector3(0.56 + Float(index) * 0.045, -0.52 + Float(index) * 0.13, -0.18)
            cisterna.geometry?.firstMaterial = material(.systemPink)
            golgi.addChildNode(cisterna)
        }
        scene.rootNode.addChildNode(golgi)

        let mitochondria = SCNNode()
        mitochondria.name = "organelle-mitochondria"
        let mitochondrialPositions: [((Float, Float, Float), Float)] = [
            ((0.56, 0.47, 0.0), -0.55), ((-0.82, -0.50, 0.18), 0.65),
        ]
        for (position, angle) in mitochondrialPositions {
            let body = SCNNode(geometry: SCNCapsule(capRadius: 0.15, height: 0.54))
            body.eulerAngles.z = CGFloat(angle)
            body.position = SCNVector3(position.0, position.1, position.2)
            body.geometry?.firstMaterial = material(.systemRed)
            mitochondria.addChildNode(body)
            for foldIndex in 0..<3 {
                let crista = SCNNode(geometry: SCNCylinder(radius: 0.018, height: 0.19))
                crista.eulerAngles.z = .pi / 2
                crista.position = SCNVector3(position.0, position.1 + Float(foldIndex - 1) * 0.07, position.2 + 0.12)
                crista.geometry?.firstMaterial = material(.systemYellow)
                mitochondria.addChildNode(crista)
            }
        }
        scene.rootNode.addChildNode(mitochondria)

        let ribosomes = SCNNode()
        ribosomes.name = "organelle-ribosomes"
        let ribosomePositions: [(Float, Float, Float)] = [
            (-0.90, 0.35, 0.24), (-0.76, 0.72, -0.12), (-0.42, 0.86, 0.1),
            (-0.05, 0.90, -0.18), (0.28, 0.82, 0.26), (0.78, 0.65, -0.08),
            (0.93, 0.22, 0.12), (0.90, -0.20, -0.15), (0.62, -0.84, 0.09),
            (0.22, -0.91, -0.22), (-0.21, -0.89, 0.20), (-0.67, -0.74, -0.11),
            (-0.97, -0.17, -0.12), (0.38, 0.21, 0.66), (-0.64, 0.05, 0.68),
            (0.08, -0.57, 0.69),
        ]
        for position in ribosomePositions {
            let dot = SCNNode(geometry: SCNSphere(radius: 0.045))
            dot.position = SCNVector3(position.0, position.1, position.2)
            dot.geometry?.firstMaterial = material(.systemBlue)
            ribosomes.addChildNode(dot)
        }
        scene.rootNode.addChildNode(ribosomes)

        let lysosome = SCNNode()
        lysosome.name = "organelle-lysosome"
        let lysosomePositions: [(Float, Float, Float)] = [
            (-0.82, 0.08, -0.42), (0.78, -0.08, 0.44), (0.18, -0.74, -0.48),
        ]
        for position in lysosomePositions {
            let vesicle = SCNNode(geometry: SCNSphere(radius: 0.13))
            vesicle.position = SCNVector3(position.0, position.1, position.2)
            vesicle.geometry?.firstMaterial = material(.systemGreen)
            lysosome.addChildNode(vesicle)
        }
        scene.rootNode.addChildNode(lysosome)

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 3.8
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 5.2)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        let light = SCNLight()
        light.type = .omni
        light.intensity = 850
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(-2.5, 3.5, 5)
        scene.rootNode.addChildNode(lightNode)
        return scene
    }

    private static func highlight(_ selectedPart: String, in scene: SCNScene?) {
        guard let scene else { return }
        for part in ["membrane", "nucleus", "rough_er", "golgi", "mitochondria", "ribosomes", "lysosome"] {
            guard let node = scene.rootNode.childNode(withName: "organelle-\(part)", recursively: false) else { continue }
            node.enumerateChildNodes { child, _ in setEmission(on: child, selected: false) }
            setEmission(on: node, selected: part == selectedPart)
        }
    }

    private static func setEmission(on node: SCNNode, selected: Bool) {
        guard let materials = node.geometry?.materials else { return }
        for material in materials {
            material.emission.contents = selected ? NSColor.systemYellow : NSColor.black
        }
    }

    private static func material(_ color: NSColor, roughness: CGFloat = 0.62, transparency: CGFloat = 1) -> SCNMaterial {
        let result = SCNMaterial()
        result.diffuse.contents = color
        result.roughness.contents = roughness
        result.transparency = transparency
        return result
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

private struct VariablesTypesLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var reassignToText = false

    var body: some View {
        LabCard {
            Text(L10n.text("lab.variableCodeInitial", store.language))
                .font(.system(.body, design: .monospaced).weight(.medium))
            Toggle(L10n.text("lab.variableReassign", store.language), isOn: $reassignToText)
                .toggleStyle(.switch)
            Text(L10n.text("lab.variableCodeUpdate", store.language))
                .font(.system(.body, design: .monospaced).weight(.medium))
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("lab.variableCurrentBinding", store.language))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline) {
                    Text("score")
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                    Spacer()
                    Text(reassignToText ? "\"12\"" : "12")
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                        .textSelection(.enabled)
                    Text(reassignToText ? "str" : "int")
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Label(
                    L10n.text(reassignToText ? "lab.variableAfter" : "lab.variableBefore", store.language),
                    systemImage: reassignToText ? "textformat" : "number"
                )
                .font(.callout)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
        }
    }
}

private struct AlgorithmicThinkingLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var completedSteps: [String] = []
    @State private var feedbackKey: String?
    @State private var a = 6
    @State private var b = 3

    private let stepOrder = ["input", "compare", "otherwise", "display"]

    private var choices: [String] {
        switch completedSteps.count {
        case 0: ["compare", "input", "display"]
        case 1: ["otherwise", "compare", "display"]
        case 2: ["display", "otherwise", "input"]
        default: ["display", "compare", "input"]
        }
    }

    private var result: Int { max(a, b) }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.algorithmHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(completedSteps.enumerated()), id: \.offset) { index, step in
                Label("\(index + 1). \(L10n.text(stepTitleKey(step), store.language))", systemImage: "checkmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(Color.green)
            }

            if completedSteps.count < stepOrder.count {
                Text(String(format: L10n.text("lab.algorithmProgress", store.language), completedSteps.count + 1, stepOrder.count))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)

                ForEach(choices, id: \.self) { choice in
                    Button {
                        select(choice)
                    } label: {
                        Label(L10n.text(stepTitleKey(choice), store.language), systemImage: "arrow.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let feedbackKey {
                Label(L10n.text(feedbackKey, store.language), systemImage: completedSteps.count == stepOrder.count ? "checkmark.circle.fill" : "info.circle")
                    .font(.callout)
                    .foregroundStyle(completedSteps.count == stepOrder.count ? Color.green : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if completedSteps.count == stepOrder.count {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text("lab.algorithmInputs", store.language))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Stepper("a = \(a)", value: $a, in: -10...10)
                    Stepper("b = \(b)", value: $b, in: -10...10)
                    Text("\(L10n.text("lab.algorithmCondition", store.language)): \(a) > \(b) → \(L10n.text(a > b ? "lab.algorithmTrue" : "lab.algorithmFalse", store.language))")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(String(format: L10n.text("lab.algorithmResult", store.language), result))
                        .font(.headline.monospacedDigit())
                    Text(L10n.text(a > b ? "lab.algorithmTraceGreater" : "lab.algorithmTraceOtherwise", store.language))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background, in: RoundedRectangle(cornerRadius: 12))

                Button {
                    completedSteps = []
                    feedbackKey = nil
                } label: {
                    Label(L10n.text("lab.algorithmRestart", store.language), systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func select(_ step: String) {
        guard completedSteps.count < stepOrder.count else { return }
        guard step == stepOrder[completedSteps.count] else {
            feedbackKey = "lab.algorithmIncorrect"
            return
        }
        completedSteps.append(step)
        feedbackKey = completedSteps.count == stepOrder.count ? "lab.algorithmComplete" : "lab.algorithmStepCorrect"
    }

    private func stepTitleKey(_ step: String) -> String {
        switch step {
        case "input": "lab.algorithmInput"
        case "compare": "lab.algorithmCompare"
        case "otherwise": "lab.algorithmOtherwise"
        default: "lab.algorithmDisplay"
        }
    }
}

private struct FileReadingLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var scenarioID = FileReadingPractice.scenarios[0].id
    @State private var selectedOutcome: FileReadingOutcome?
    @State private var hasCheckedAnswer = false
    @State private var outcomeOrder = QuizAnswerOrder(
        optionCount: FileReadingOutcome.allCases.count,
        answerOriginalIndex: FileReadingPractice.scenarios[0].expectedOutcome.rawValue
    )

    private var scenario: FileReadingScenario {
        FileReadingPractice.scenario(id: scenarioID) ?? FileReadingPractice.scenarios[0]
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.fileTrace.hint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker(L10n.text("lab.fileTrace.scenario", store.language), selection: $scenarioID) {
                ForEach(FileReadingPractice.scenarios) { item in
                    Text(L10n.text("lab.fileTrace.scenario.\(item.id)", store.language)).tag(item.id)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: scenarioID) { _ in
                selectedOutcome = nil
                hasCheckedAnswer = false
                outcomeOrder = QuizAnswerOrder(
                    optionCount: FileReadingOutcome.allCases.count,
                    answerOriginalIndex: scenario.expectedOutcome.rawValue
                )
            }

            Text("""
            with path.open("r", encoding="utf-8") as file:
                total = sum(int(line.strip()) for line in file if line.strip())
            """)
            .font(.system(.callout, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(Text(L10n.text("lab.fileTrace.code", store.language)))

            Text(L10n.text("lab.fileTrace.question", store.language))
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(outcomeOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                let outcome = FileReadingPractice.outcomes[originalIndex]
                Button {
                    guard !hasCheckedAnswer else { return }
                    selectedOutcome = outcome
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selectedOutcome == outcome ? "largecircle.fill.circle" : "circle")
                        Text(L10n.text(outcome.localizationKey, store.language))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(10)
                    .background(
                        selectedOutcome == outcome ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
                .disabled(hasCheckedAnswer)
                .accessibilityAddTraits(selectedOutcome == outcome ? .isSelected : [])
            }

            if hasCheckedAnswer {
                let correct = selectedOutcome.map { FileReadingPractice.isCorrect($0, for: scenarioID) } ?? false
                Label(
                    L10n.text(correct ? "lab.fileTrace.correct" : "lab.fileTrace.incorrect", store.language),
                    systemImage: correct ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                )
                .foregroundStyle(correct ? Color.green : Color.orange)

                Label(
                    L10n.text(scenario.explanationKey, store.language),
                    systemImage: "info.circle"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                hasCheckedAnswer = true
            } label: {
                Label(L10n.text("lab.fileTrace.check", store.language), systemImage: "checkmark")
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedOutcome == nil || hasCheckedAnswer)
        }
    }
}

private struct TransactionLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var scenario: TransactionScenario = .commitTransfer
    @State private var snapshot = TransactionPractice.initialSnapshot()

    var body: some View {
        LabCard {
            Text(L10n.text("lab.transaction.hint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker(L10n.text("lab.transaction.scenarioPicker", store.language), selection: $scenario) {
                ForEach(TransactionScenario.allCases) { item in
                    Text(L10n.text(item.titleKey, store.language)).tag(item)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: scenario) { _ in resetPractice() }

            Text("BEGIN;  UPDATE;  COMMIT / ROLLBACK")
                .font(.system(.callout, design: .monospaced).weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                balanceColumn(title: "lab.transaction.source", value: snapshot.sourceBalance, saved: snapshot.committedSourceBalance)
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                balanceColumn(title: "lab.transaction.destination", value: snapshot.destinationBalance, saved: snapshot.committedDestinationBalance)
            }

            Label(L10n.text(snapshot.stage.titleKey, store.language), systemImage: snapshot.stage.isFinished ? "checkmark.circle.fill" : "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.callout.weight(.medium))
                .foregroundStyle(snapshot.stage.isFinished ? Color.green : Color.accentColor)

            Text(L10n.text(snapshot.traceKey, store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("transaction-practice-feedback")

            Text(String(format: L10n.text("lab.transaction.savedTotal", store.language), snapshot.committedTotal))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            HStack {
                Button {
                    snapshot = TransactionPractice.advance(snapshot, scenario: scenario)
                } label: {
                    Label(
                        L10n.text(TransactionPractice.nextActionKey(for: snapshot, scenario: scenario) ?? "lab.transaction.done", store.language),
                        systemImage: snapshot.stage.isFinished ? "checkmark" : "arrow.right"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(snapshot.stage.isFinished)

                Button {
                    resetPractice()
                } label: {
                    Label(L10n.text("lab.transaction.reset", store.language), systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func balanceColumn(title: String, value: Int, saved: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(L10n.text(title, store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(value))
                .font(.system(.title3, design: .rounded).weight(.semibold).monospacedDigit())
            Text(String(format: L10n.text("lab.transaction.persisted", store.language), saved))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private func resetPractice() {
        snapshot = TransactionPractice.initialSnapshot()
    }
}

private struct DebuggingLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var scenarioID = DebuggingPractice.scenarios[0].id
    @State private var selectedChoice = -1
    @State private var hasChecked = false
    @State private var optionOrder = QuizAnswerOrder(
        optionCount: DebuggingPractice.scenarios[0].choiceKeys.count,
        answerOriginalIndex: DebuggingPractice.scenarios[0].correctChoice
    )

    private var scenario: DebuggingScenario {
        DebuggingPractice.scenario(id: scenarioID) ?? DebuggingPractice.scenarios[0]
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.debugging.hint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker(L10n.text("lab.debugging.scenarioPicker", store.language), selection: $scenarioID) {
                ForEach(DebuggingPractice.scenarios) { item in
                    Text(L10n.text(item.promptKey, store.language)).tag(item.id)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: scenarioID) { newScenarioID in
                selectedChoice = -1
                hasChecked = false
                if let newScenario = DebuggingPractice.scenario(id: newScenarioID) {
                    optionOrder = QuizAnswerOrder(
                        optionCount: newScenario.choiceKeys.count,
                        answerOriginalIndex: newScenario.correctChoice
                    )
                }
            }

            Text(scenario.code)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.background, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel(Text(L10n.text("lab.debugging.code", store.language)))

            Label(scenario.traceback, systemImage: "exclamationmark.triangle.fill")
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(Text(L10n.text("lab.debugging.traceback", store.language)))

            Text(L10n.text("lab.debugging.choose", store.language))
                .font(.callout.weight(.medium))

            Picker(L10n.text("lab.debugging.choicePicker", store.language), selection: $selectedChoice) {
                ForEach(Array(optionOrder.displayedOriginalIndices.enumerated()), id: \.offset) { displayIndex, originalIndex in
                    Text(L10n.text(scenario.choiceKeys[originalIndex], store.language)).tag(displayIndex)
                }
            }
            .pickerStyle(.radioGroup)
            .disabled(hasChecked)

            if hasChecked {
                Label(
                    L10n.text(scenario.explanationKey, store.language),
                    systemImage: optionOrder.isCorrect(displayedIndex: selectedChoice)
                        ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                )
                .font(.callout)
                .foregroundStyle(optionOrder.isCorrect(displayedIndex: selectedChoice) ? Color.green : Color.orange)
                .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                hasChecked = true
            } label: {
                Label(L10n.text("lab.debugging.check", store.language), systemImage: "checkmark")
            }
            .buttonStyle(.borderedProminent)
            .disabled(hasChecked || selectedChoice < 0)
        }
    }
}

private struct LinearSystemLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var scenarioID = LinearSystemPractice.scenarios[0].id
    @State private var prediction = -1
    @State private var hasChecked = false

    private var scenario: LinearSystemScenario {
        LinearSystemPractice.scenario(id: scenarioID)
    }

    private var equationOne: String {
        equation(scenario.first.x, scenario.first.y, scenario.first.result)
    }

    private var equationTwo: String {
        equation(scenario.second.x, scenario.second.y, scenario.second.result)
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.linearSystemHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker(L10n.text("lab.linearSystemScenario", store.language), selection: $scenarioID) {
                Text(L10n.text("lab.linearSystemUnique", store.language)).tag("unique")
                Text(L10n.text("lab.linearSystemParallel", store.language)).tag("parallel")
                Text(L10n.text("lab.linearSystemSameLine", store.language)).tag("same-line")
            }
            .pickerStyle(.segmented)
            .onChange(of: scenarioID) { _ in
                prediction = -1
                hasChecked = false
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(equationOne).font(.title3.monospaced())
                Text(equationTwo).font(.title3.monospaced())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Label(L10n.text("lab.linearSystemEliminate", store.language), systemImage: "arrow.down.to.line")
                .font(.callout.weight(.medium))
            Text(String(format: L10n.text("lab.linearSystemReduction", store.language), scenario.eliminationResult.x, scenario.eliminationResult.result))
                .font(.title3.monospaced())
                .accessibilityLabel(L10n.text("lab.linearSystemReduction", store.language))

            Picker(L10n.text("lab.linearSystemPredict", store.language), selection: $prediction) {
                Text(L10n.text("lab.linearSystemOne", store.language)).tag(0)
                Text(L10n.text("lab.linearSystemNone", store.language)).tag(1)
                Text(L10n.text("lab.linearSystemInfinite", store.language)).tag(2)
            }
            .pickerStyle(.segmented)

            Button(L10n.text("lab.linearSystemCheck", store.language)) {
                hasChecked = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(prediction < 0)

            if hasChecked {
                let correct = LinearSystemPractice.isCorrectPrediction(prediction, for: scenario)
                Label(
                    L10n.text(correct ? "lab.linearSystemCorrect" : "lab.linearSystemReview", store.language),
                    systemImage: correct ? "checkmark.circle.fill" : "arrow.uturn.backward.circle"
                )
                .font(.callout.weight(.medium))
                .foregroundStyle(correct ? .green : .orange)
                .fixedSize(horizontal: false, vertical: true)
            }

            if hasChecked {
                Text(outcomeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var outcomeDescription: String {
        switch LinearSystemPractice.classify(scenario) {
        case let .oneSolution(x, y):
            return String(format: L10n.text("lab.linearSystemOutcomeOne", store.language), x, y)
        case .noSolution:
            return L10n.text("lab.linearSystemOutcomeNone", store.language)
        case .infinitelyManySolutions:
            return L10n.text("lab.linearSystemOutcomeInfinite", store.language)
        }
    }

    private func equation(_ x: Int, _ y: Int, _ result: Int) -> String {
        let xTerm = x == 1 ? "x" : (x == -1 ? "−x" : "\(x)x")
        let yMagnitude = abs(y) == 1 ? "y" : "\(abs(y))y"
        let yTerm = y >= 0 ? " + \(yMagnitude)" : " − \(yMagnitude)"
        return "\(xTerm)\(yTerm) = \(result)"
    }
}

private struct AlgorithmComplexityLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var sizeIndex = 2.0

    private var itemCount: Int {
        AlgorithmComplexityPractice.sampleSizes[Int(sizeIndex.rounded())]
    }

    private var linearCount: Int {
        AlgorithmComplexityPractice.linearSearchWorstCaseComparisons(for: itemCount)
    }

    private var binaryCount: Int {
        AlgorithmComplexityPractice.binarySearchWorstCaseComparisons(for: itemCount)
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.complexityHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 7) {
                Text(String(format: L10n.text("lab.complexitySize", store.language), itemCount))
                    .font(.headline.monospacedDigit())
                Slider(value: $sizeIndex, in: 0...3, step: 1)
                    .accessibilityLabel(L10n.text("lab.complexitySize", store.language))
                    .accessibilityValue(String(itemCount))
            }

            complexityBar(
                title: L10n.text("lab.complexityLinear", store.language),
                comparisons: linearCount,
                maximum: linearCount,
                tint: .blue
            )
            complexityBar(
                title: L10n.text("lab.complexityBinary", store.language),
                comparisons: binaryCount,
                maximum: linearCount,
                tint: .purple
            )

            Label(L10n.text("lab.complexityPrecondition", store.language), systemImage: "checkmark.seal")
                .font(.callout.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.text("lab.complexityLimit", store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func complexityBar(title: String, comparisons: Int, maximum: Int, tint: Color) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.medium))
                .frame(width: 132, alignment: .leading)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.12))
                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: max(8, geometry.size.width * CGFloat(comparisons) / CGFloat(maximum)))
                }
            }
            .frame(height: 14)
            Text(String(format: L10n.text("lab.complexityComparisons", store.language), comparisons))
                .font(.caption.monospacedDigit())
                .frame(width: 82, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct LoopTraceLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var scenarioID = LoopTracePractice.scenarios[0].id
    @State private var prediction = 0
    @State private var hasCheckedPrediction = false
    @State private var revealedStepCount = 0

    private var scenario: LoopTraceScenario {
        LoopTracePractice.scenario(id: scenarioID) ?? LoopTracePractice.scenarios[0]
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.loopTraceHint", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("count_even(\(scenario.displayedValues))")
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .textSelection(.enabled)
                .accessibilityLabel(Text(L10n.text("lab.loopTraceInput", store.language)))

            Picker(L10n.text("lab.loopTraceScenario", store.language), selection: $scenarioID) {
                ForEach(LoopTracePractice.scenarios) { item in
                    Text(L10n.text("lab.loopTraceScenario.\(item.id)", store.language)).tag(item.id)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: scenarioID) { _ in resetPractice() }

            Text("""
            count = 0
            for number in numbers:
                if number % 2 == 0:
                    count += 1
            return count
            """)
            .font(.system(.callout, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(Text(L10n.text("lab.loopTraceCode", store.language)))

            HStack {
                Text(L10n.text("lab.loopTracePrediction", store.language))
                Spacer()
                Picker(L10n.text("lab.loopTracePrediction", store.language), selection: $prediction) {
                    ForEach(0...scenario.values.count, id: \.self) { value in
                        Text(String(value)).tag(value)
                    }
                }
                .frame(width: 90)
                .disabled(hasCheckedPrediction)
            }

            if hasCheckedPrediction {
                Label(
                    String(format: L10n.text("lab.loopTraceFeedback", store.language), scenario.expectedCount),
                    systemImage: LoopTracePractice.isCorrect(prediction: prediction, for: scenarioID)
                        ? "checkmark.circle.fill" : "arrow.counterclockwise.circle"
                )
                .foregroundStyle(LoopTracePractice.isCorrect(prediction: prediction, for: scenarioID) ? Color.green : Color.orange)
                .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(scenario.steps.prefix(revealedStepCount))) { step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(step.index + 1)")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 22, alignment: .leading)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(String(format: L10n.text("lab.loopTraceStep", store.language), step.value))
                                .font(.system(.callout, design: .monospaced).weight(.medium))
                            Text(L10n.text(step.isEven ? "lab.loopTraceEven" : "lab.loopTraceOdd", store.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(step.countAfter))
                            .font(.system(.callout, design: .monospaced).weight(.semibold))
                            .accessibilityLabel(Text(L10n.text("lab.loopTraceCount", store.language)))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityElement(children: .combine)
                }

                if revealedStepCount == scenario.steps.count {
                    Label(
                        String(format: L10n.text("lab.loopTraceReturn", store.language), scenario.expectedCount),
                        systemImage: "arrow.uturn.backward.circle"
                    )
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.tint)
                }
            }

            Button {
                if hasCheckedPrediction {
                    revealedStepCount = min(revealedStepCount + 1, scenario.steps.count)
                } else {
                    hasCheckedPrediction = true
                    revealedStepCount = scenario.steps.isEmpty ? 0 : 1
                }
            } label: {
                Label(
                    L10n.text(
                        hasCheckedPrediction ? "lab.loopTraceNextStep" : "lab.loopTraceCheck",
                        store.language
                    ),
                    systemImage: hasCheckedPrediction ? "arrow.right" : "checkmark"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(hasCheckedPrediction && revealedStepCount >= scenario.steps.count)
        }
    }

    private func resetPractice() {
        prediction = 0
        hasCheckedPrediction = false
        revealedStepCount = 0
    }
}

private struct CollectionsLoopsLab: View {
    @EnvironmentObject private var store: LearningStore
    @State private var tasks = ["docs", "tests", "app"]
    @State private var nextTask = 0
    @State private var includesIndexes = true

    private let additions = ["build", "review", "ship", "notes", "measure"]

    private var outputLines: [String] {
        if includesIndexes {
            return tasks.enumerated().map { "\($0.offset)  \($0.element)" }
        }
        return tasks.map { $0 }
    }

    private var loopCode: String {
        includesIndexes
            ? "for index, task in enumerate(tasks):\n    print(index, task)"
            : "for task in tasks:\n    print(task)"
    }

    var body: some View {
        LabCard {
            Text(L10n.text("lab.collectionsHelp", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("tasks = [\(tasks.map { "\"\($0)\"" }.joined(separator: ", "))]")
                .font(.system(.body, design: .monospaced).weight(.medium))
                .textSelection(.enabled)
                .accessibilityLabel(Text(L10n.text("lab.collectionsState", store.language)))

            if tasks.isEmpty {
                Label(L10n.text("lab.collectionsEmpty", store.language), systemImage: "list.bullet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(tasks.indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 7) {
                                if includesIndexes {
                                    Text("[\(index)]")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                Text(tasks[index])
                                    .font(.system(.body, design: .monospaced).weight(.semibold))
                                    .textSelection(.enabled)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(.background, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                .accessibilityLabel(Text(L10n.text("lab.collectionsState", store.language)))
            }

            Picker(L10n.text("lab.collectionsLoop", store.language), selection: $includesIndexes) {
                Text(L10n.text("lab.collectionsValuesOnly", store.language)).tag(false)
                Text(L10n.text("lab.collectionsWithIndex", store.language)).tag(true)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text(loopCode)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                Divider()
                ForEach(outputLines.indices, id: \.self) { index in
                    Text(outputLines[index])
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)

            HStack(spacing: 10) {
                Button {
                    guard tasks.count < 8 else { return }
                    tasks.append(additions[nextTask % additions.count])
                    nextTask += 1
                } label: {
                    Label(L10n.text("lab.collectionsAdd", store.language), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(tasks.count >= 8)

                Button {
                    guard !tasks.isEmpty else { return }
                    tasks.removeLast()
                } label: {
                    Label(L10n.text("lab.collectionsRemove", store.language), systemImage: "minus")
                }
                .buttonStyle(.bordered)
                .disabled(tasks.isEmpty)
            }

            Text(L10n.text("lab.collectionsCount", store.language) + ": \(tasks.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}


struct TutorChatView: View {
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

    init(
        customSubject: CustomLearningSubject,
        topic: CustomLearningTopic,
        language: AppLanguage,
        mode: AIRoutingMode,
        routeSubjectID: String? = nil
    ) {
        self.language = language
        let topicName = topic.name.value(in: language.rawValue)
        let subjectName = customSubject.name.value(in: language.rawValue)
        let notes = topic.notes.value(in: language.rawValue)
        let goal = topic.learningOutcome.value(in: language.rawValue)
        let lesson = LessonContent(
            title: topicName,
            objective: goal.isEmpty ? topicName : goal,
            explanation: notes,
            mechanism: L10n.text("custom.learnPrompt", language),
            example: notes,
            limitations: language == .ru
                ? "Это пользовательский материал. Не выдавай его за подтверждённый источник; отмечай, что требует проверки."
                : "This is learner-provided material. Do not present it as a verified source; flag claims that need checking.",
            question: "",
            options: [],
            answerIndex: 0,
            feedback: ""
        )
        _chat = StateObject(wrappedValue: TutorChatModel(
            subjectID: routeSubjectID ?? "custom-\(customSubject.id.uuidString.lowercased())",
            subjectName: subjectName,
            lesson: lesson,
            language: language,
            mode: mode
        ))
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
                    if let policy = store.autoCostPolicy, !policy.allowPaidRoutes {
                        Label(L10n.text("tutor.webSearchCostBlocked", language), systemImage: "lock.fill")
                            .font(.caption2).foregroundStyle(.secondary)
                    } else if store.autoCostPolicy == nil {
                        Label(L10n.text("tutor.webSearchCostChecking", language), systemImage: "lock.fill")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
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
                    .disabled(chat.isSending || store.autoCostPolicy?.allowPaidRoutes != true)
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
            await store.refreshAutoCostPolicy()
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
                        if message.citationWarnings.contains("NO_VALID_CITATIONS") {
                            Label(L10n.text("tutor.noValidCitations", language), systemImage: "quote.bubble")
                        }
                        let missingIDs = message.citationWarnings.filter { $0 != "NO_VALID_CITATIONS" }
                        if !missingIDs.isEmpty {
                            Label(
                                String(
                                    format: L10n.text("tutor.missingCitation", language),
                                    missingIDs.joined(separator: ", ")
                                ),
                                systemImage: "exclamationmark.triangle"
                            )
                        }
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
                                if ["google_grounding", "official_web"].contains(item.sourceType ?? ""),
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
                                if let path = item.path,
                                   path != item.title,
                                   !["google_grounding", "official_web"].contains(item.sourceType ?? "") {
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
                                    Text("\(L10n.text(item.sourceType == "official_web" ? "tutor.sourceSyncedAt" : "tutor.sourceReviewDate", language)): \(sourceCheckedAt)")
                                        .font(.caption2).foregroundStyle(.secondary)
                                    if item.sourceType != "official_web" {
                                        Text(L10n.text("tutor.sourceCheckCaveat", language))
                                        .font(.caption2).foregroundStyle(.tertiary)
                                    }
                                }
                                if let license = item.license {
                                    HStack(spacing: 4) {
                                        Text("\(L10n.text("tutor.sourceLicense", language)): \(license)")
                                        if let licenseURL = item.licenseURL,
                                           let url = URL(string: licenseURL) {
                                            Link(L10n.text("tutor.sourceLicenseTerms", language), destination: url)
                                        }
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                }
                                if let attribution = item.attribution {
                                    Text(attribution)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .textSelection(.enabled)
                                }
                                if let officialReferences = item.officialReferences,
                                   !officialReferences.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(L10n.text("tutor.officialReferences", language))
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        ForEach(officialReferences) { reference in
                                            if let url = officialSourceURL(reference) {
                                                Link(reference.title, destination: url)
                                                    .font(.caption2)
                                                    .lineLimit(2)
                                            }
                                        }
                                        Text(L10n.text("tutor.officialReferencesCaveat", language))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
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
        if useWebSearch {
            return chat.mode == .automatic
                && store.autoCostPolicy?.allowPaidRoutes == true
                && health.hasGroundedSearch
        }
        return chat.mode == .automatic ? health.hasAutomaticRoute : health.hasLocalModel
    }

    private func officialSourceURL(_ reference: TutorSourceReference) -> URL? {
        reference.safeURL
    }

    private func routeDescription(for health: OrchestratorHealth) -> String {
        if store.aiMode == .localOnly {
            return L10n.text(health.hasLocalModel ? "settings.aiLocalRoute" : "settings.aiNoLocal", language)
        }
        if health.hasCloudRoute { return L10n.text("settings.aiOnlineRoute", language) }
        if health.hasLocalModel { return L10n.text("settings.aiLocalRoute", language) }
        return L10n.text("settings.aiNoRoute", language)
    }

    private func send() {
        guard canSend, !chat.isSending else { return }
        let message = draft
        Task {
            guard await backendSupervisor.ensureRunning() else { return }
            await store.refreshAIStatus()
            await store.refreshAutoCostPolicy()
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
