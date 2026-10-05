import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var store: LearningStore
    @EnvironmentObject private var backendSupervisor: LocalBackendSupervisor
    @State private var selection: AppSection? = .today

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    Label { Text(L10n.text("nav.today", store.language)) } icon: { Image(systemName: "sparkles") }
                        .tag(AppSection.today)
                    Label { Text(L10n.text("nav.subjects", store.language)) } icon: { Image(systemName: "square.grid.2x2") }
                        .tag(AppSection.subjects)
                } header: {
                    Text(L10n.text("nav.yourLearning", store.language))
                }

                Section {
                    ForEach(Subject.allCases) { subject in
                        Label { Text(subject.title(in: store.language)) } icon: { Image(systemName: subject.symbol) }
                            .tag(AppSection.subject(subject))
                    }
                } header: {
                    Text(L10n.text("nav.subjects", store.language))
                }

                Section {
                    Label { Text(L10n.text("nav.settings", store.language)) } icon: { Image(systemName: "gearshape") }
                        .tag(AppSection.settings)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("ColiDev")
        } detail: {
            Group {
                switch selection ?? .today {
                case .today:
                    TodayView(open: open, openDueReview: openDueReview)
                case .subjects:
                    SubjectCatalogView(open: open)
                case .subject(let subject):
                    SubjectOverviewView(
                        subject: subject,
                        openCourseLesson: { resource in
                            selection = .courseLesson(subject, resource)
                        }
                    ) {
                        selection = .lesson(subject)
                    }
                case .lesson(let subject):
                    LessonSessionView(subject: subject) {
                        selection = .subject(subject)
                    }
                case .courseLesson(let subject, let resource):
                    CurriculumModuleView(subject: subject, resource: resource)
                case .settings:
                    SettingsView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker(selection: $store.language, label: Text(L10n.text("settings.language", store.language))) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.shortLabel).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 112)
                    .accessibilityLabel(Text(L10n.text("settings.language", store.language)))
                }
            }
        }
        .task {
            guard await backendSupervisor.ensureRunning() else { return }
            await store.syncStudyProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            backendSupervisor.stop()
        }
    }

    private func open(_ subject: Subject) {
        selection = .subject(subject)
    }

    private func openDueReview(_ subject: Subject, lessonID: String) {
        if lessonID == subject.lessonID {
            selection = .lesson(subject)
        } else {
            let prefix = "\(subject.rawValue)."
            let resource = String(lessonID.dropFirst(prefix.count))
            selection = .courseLesson(subject, resource)
        }
    }
}

private struct TodayView: View {
    @EnvironmentObject private var store: LearningStore
    let open: (Subject) -> Void
    let openDueReview: (Subject, String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 210), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.text("home.eyebrow", store.language))
                        .font(.caption.weight(.semibold))
                        .tracking(1.4)
                        .foregroundStyle(.secondary)
                    Text(L10n.text("home.title", store.language))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(L10n.text("home.subtitle", store.language))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 28)

                progressCard

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.text("home.catalog", store.language))
                            .font(.title2.weight(.semibold))
                        Text(L10n.text("home.catalogHint", store.language))
                            .foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                        ForEach(Subject.allCases) { subject in
                            SubjectCard(subject: subject, complete: store.isComplete(subject)) {
                                open(subject)
                            }
                        }
                    }
                }

                Label { Text(L10n.text("home.offline", store.language)) } icon: { Image(systemName: "wifi.slash") }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var progressCard: some View {
        HStack(spacing: 22) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(store.completedSubjectCount) / CGFloat(Subject.allCases.count))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(store.completedSubjectCount)/6")
                    .font(.headline.monospacedDigit())
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("home.progress", store.language))
                    .font(.caption.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                Text("\(store.completedSubjectCount) \(L10n.text("home.completed", store.language))")
                    .font(.headline)
                Text(L10n.text("home.subjectCount", store.language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if store.dueReviewCount > 0 {
                    Text(L10n.text("home.dueReviews", store.language)
                        .replacingOccurrences(of: "%@", with: "\(store.dueReviewCount)"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
            }
            Spacer(minLength: 0)
            Button {
                if let subject = store.nextDueSubject, let lessonID = store.nextDueLessonID {
                    openDueReview(subject, lessonID)
                } else {
                    let next = Subject.allCases.first(where: { !store.isComplete($0) }) ?? .mathematics
                    open(next)
                }
            } label: {
                Label {
                    Text(L10n.text(store.dueReviewCount > 0 ? "home.reviewNow" : "home.continue", store.language))
                } icon: {
                    Image(systemName: store.dueReviewCount > 0 ? "arrow.counterclockwise" : "arrow.right")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct SubjectCatalogView: View {
    @EnvironmentObject private var store: LearningStore
    let open: (Subject) -> Void
    private let columns = [GridItem(.adaptive(minimum: 210), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                ForEach(Subject.allCases) { subject in
                    SubjectCard(subject: subject, complete: store.isComplete(subject)) { open(subject) }
                }
            }
            .padding(28)
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(Text(L10n.text("nav.subjects", store.language)))
    }
}

private struct SubjectCard: View {
    @EnvironmentObject private var store: LearningStore
    let subject: Subject
    let complete: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: subject.symbol)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(subject.tint)
                        .frame(width: 44, height: 44)
                        .background(subject.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                    Spacer()
                    if complete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title(in: store.language))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subject.subtitle(in: store.language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Text(complete ? L10n.text("home.done", store.language) : L10n.text("home.foundation", store.language))
                    Image(systemName: "arrow.right")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(subject.tint)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.quaternary, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var store: LearningStore
    @EnvironmentObject private var backendSupervisor: LocalBackendSupervisor
    @State private var isRefreshingKnowledge = false
    @State private var knowledgeRefreshMessage: String?
    @State private var knowledgeRefreshFailed = false

    var body: some View {
        Form {
            Section {
                Picker(selection: $store.language, label: Text(L10n.text("settings.languages", store.language))) {
                    Text("Русский").tag(AppLanguage.ru)
                    Text("English").tag(AppLanguage.en)
                }
                .pickerStyle(.segmented)
            }
            Section {
                Picker(selection: $store.aiMode, label: Text(L10n.text("settings.aiRoute", store.language))) {
                    Text(L10n.text("settings.aiAuto", store.language)).tag(AIRoutingMode.automatic)
                    Text(L10n.text("settings.aiLocal", store.language)).tag(AIRoutingMode.localOnly)
                }
                .pickerStyle(.segmented)
                LabeledContent {
                    Text(LearningStore.orchestratorBaseURL).font(.callout.monospaced())
                } label: {
                    Text(L10n.text("settings.aiAddress", store.language))
                }
                HStack {
                    if store.isCheckingAI && store.aiHealth == nil {
                        ProgressView().controlSize(.small)
                        Text(L10n.text("settings.aiChecking", store.language)).foregroundStyle(.secondary)
                    } else if let health = store.aiHealth {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(L10n.text("settings.aiConnected", store.language), systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(routeDescription(for: health))
                                .font(.caption).foregroundStyle(.secondary)
                            if !health.isOllamaEndpointLocal {
                                Label(L10n.text("settings.aiOllamaRemote", store.language), systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption).foregroundStyle(.orange)
                            }
                            if !health.isObsidianEndpointLocal {
                                Label(L10n.text("settings.aiObsidianRemote", store.language), systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption).foregroundStyle(.orange)
                            }
                            if let documentCount = health.knowledgeDocumentCount {
                                Text(L10n.text("settings.aiKnowledgeCount", store.language) + "\(documentCount)")
                                    .font(.caption).foregroundStyle(.secondary)
                                if let checkedAt = health.displayKnowledgeIndexCheckedAt {
                                    Text(L10n.text("settings.aiKnowledgeChecked", store.language) + checkedAt)
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                            } else {
                                Text(L10n.text("settings.aiKnowledgeUnknown", store.language))
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                            if let embeddingModel = health.ollamaEmbeddingModel {
                                Text(String(format: L10n.text("settings.aiSemanticConfigured", store.language), embeddingModel))
                                    .font(.caption2).foregroundStyle(.secondary)
                            } else {
                                Text(L10n.text("settings.aiSemanticKeyword", store.language))
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    } else {
                        Label(L10n.text("settings.aiOffline", store.language), systemImage: "wifi.slash")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(L10n.text("settings.aiRefresh", store.language)) {
                        Task {
                            guard await backendSupervisor.ensureRunning() else { return }
                            await store.refreshAIStatus()
                            await store.refreshProviderSecretStatuses()
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        Task { await refreshKnowledgeIndex() }
                    } label: {
                        if isRefreshingKnowledge {
                            ProgressView().controlSize(.small)
                            Text(L10n.text("settings.knowledgeRefreshing", store.language))
                        } else {
                            Label(
                                L10n.text("settings.knowledgeRefresh", store.language),
                                systemImage: "arrow.clockwise"
                            )
                        }
                    }
                    .disabled(isRefreshingKnowledge)
                    Text(L10n.text("settings.knowledgeRefreshExplanation", store.language))
                        .font(.caption).foregroundStyle(.secondary)
                    if let knowledgeRefreshMessage {
                        Text(knowledgeRefreshMessage)
                            .font(.caption)
                            .foregroundStyle(knowledgeRefreshFailed ? Color.orange : Color.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.text("settings.aiLaunch", store.language)).font(.caption.weight(.semibold))
                    Text(L10n.text(backendSupervisor.status.localizationKey, store.language))
                        .font(.callout)
                    Text(L10n.text("settings.aiPrivacy", store.language)).font(.caption).foregroundStyle(.secondary)
                }
            } header: {
                Text(L10n.text("settings.aiTitle", store.language))
            }
            Section {
                ProviderKeyEntryView(provider: "gemini", title: "Gemini")
                ProviderKeyEntryView(provider: "kimi", title: "Kimi")
                ProviderKeyEntryView(provider: "obsidian", title: "Obsidian Local REST API")
            } header: {
                Text(L10n.text("settings.keysTitle", store.language))
            } footer: {
                Text(L10n.text("settings.keysPrivacy", store.language))
            }
            Section {
                Label { Text(L10n.text("settings.localBody", store.language)) } icon: { Image(systemName: "internaldrive") }
                    .foregroundStyle(.secondary)
            } header: {
                Text(L10n.text("settings.local", store.language))
            }
            Section {
                LabeledContent { Text(L10n.text("settings.preview", store.language)) } label: { Text(L10n.text("settings.version", store.language)) }
            }
        }
        .task {
            guard await backendSupervisor.ensureRunning() else { return }
            await store.refreshAIStatus()
            await store.refreshProviderSecretStatuses()
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(maxWidth: 720, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(Text(L10n.text("settings.title", store.language)))
    }

    private func routeDescription(for health: OrchestratorHealth) -> String {
        if store.aiMode == .localOnly {
            return L10n.text(health.hasLocalModel ? "settings.aiLocalRoute" : "settings.aiNoLocal", store.language)
        }
        if health.hasCloudSession { return L10n.text("settings.aiOnlineRoute", store.language) }
        if health.hasLocalModel { return L10n.text("settings.aiLocalRoute", store.language) }
        return L10n.text("settings.aiNoRoute", store.language)
    }

    @MainActor
    private func refreshKnowledgeIndex() async {
        isRefreshingKnowledge = true
        knowledgeRefreshMessage = nil
        knowledgeRefreshFailed = false
        defer { isRefreshingKnowledge = false }
        guard await backendSupervisor.ensureRunning() else {
            knowledgeRefreshFailed = true
            knowledgeRefreshMessage = L10n.text("settings.knowledgeRefreshFailed", store.language)
            return
        }
        do {
            let result = try await OrchestratorClient.refreshKnowledgeIndex()
            await store.refreshAIStatus()
            knowledgeRefreshMessage = String(
                format: L10n.text("settings.knowledgeRefreshDone", store.language),
                result.documentCount
            )
        } catch {
            knowledgeRefreshFailed = true
            knowledgeRefreshMessage = L10n.text("settings.knowledgeRefreshFailed", store.language)
        }
    }
}

private struct ProviderKeyEntryView: View {
    @EnvironmentObject private var store: LearningStore
    @EnvironmentObject private var backendSupervisor: LocalBackendSupervisor
    let provider: String
    let title: String

    @State private var apiKey = ""
    @State private var isSaving = false
    @State private var feedback: String?
    @State private var feedbackIsError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            HStack(spacing: 8) {
                SecureField(L10n.text("settings.keyPlaceholder", store.language), text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isSaving || !backendSupervisor.isReady)
                Button {
                    Task { await saveKey() }
                } label: {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(L10n.text("settings.keySave", store.language))
                    }
                }
                .disabled(
                    isSaving
                    || !backendSupervisor.isReady
                    || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
            HStack {
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if store.providerSecretStatuses[provider]?.source == "keychain" {
                    Button(L10n.text("settings.keyRemove", store.language), role: .destructive) {
                        Task { await removeKey() }
                    }
                    .disabled(isSaving || !backendSupervisor.isReady)
                }
            }
            if let feedback {
                Text(feedback)
                    .font(.caption)
                    .foregroundStyle(feedbackIsError ? Color.red : Color.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusLabel: String {
        let key: String
        switch store.providerSecretStatuses[provider]?.source {
        case "keychain": key = "settings.keyStatusKeychain"
        case "environment": key = "settings.keyStatusEnvironment"
        case "missing": key = "settings.keyStatusMissing"
        case "unavailable", .none: key = "settings.keyStatusUnavailable"
        default: key = "settings.keyStatusUnavailable"
        }
        return L10n.text(key, store.language)
    }

    @MainActor
    private func saveKey() async {
        guard await backendSupervisor.ensureRunning() else {
            feedback = L10n.text("settings.backendFailed", store.language)
            feedbackIsError = true
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await store.saveProviderSecret(apiKey, for: provider)
            apiKey = ""
            feedback = L10n.text("settings.keySaved", store.language)
            feedbackIsError = false
        } catch {
            feedback = L10n.text("settings.keyFailed", store.language)
            feedbackIsError = true
        }
    }

    @MainActor
    private func removeKey() async {
        guard await backendSupervisor.ensureRunning() else {
            feedback = L10n.text("settings.backendFailed", store.language)
            feedbackIsError = true
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await store.deleteProviderSecret(for: provider)
            feedback = L10n.text("settings.keyRemoved", store.language)
            feedbackIsError = false
        } catch {
            feedback = L10n.text("settings.keyFailed", store.language)
            feedbackIsError = true
        }
    }
}
