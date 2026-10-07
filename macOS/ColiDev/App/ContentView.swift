import SwiftUI
import AppKit
import UniformTypeIdentifiers

private struct LearningProgressBackupFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

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
                    Label { Text(L10n.text("nav.management", store.language)) } icon: {
                        Image(systemName: "wrench.and.screwdriver")
                    }
                    .tag(AppSection.management)
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
                case .management:
                    ManagementView(openSettings: { selection = .settings })
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
            await store.refreshAutoCostPolicy()
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
                            if health.openRouterKeyConfigured == true {
                                Text(String(
                                    format: L10n.text("settings.aiOpenRouterReady", store.language),
                                    health.openRouterModel ?? "openrouter/free"
                                ))
                                .font(.caption2).foregroundStyle(.secondary)
                            }
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
                                if let dueCount = health.knowledgeReviewDueDocumentCount, dueCount > 0 {
                                    Text(String(
                                        format: L10n.text("settings.aiReviewDue", store.language),
                                        dueCount
                                    ))
                                    .font(.caption2).foregroundStyle(.orange)
                                    Text(L10n.text("settings.aiReviewCaveat", store.language))
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                if let unscheduledCount = health.knowledgeReviewScheduleMissingDocumentCount,
                                   unscheduledCount > 0 {
                                    Text(String(
                                        format: L10n.text("settings.aiReviewUnscheduled", store.language),
                                        unscheduledCount
                                    ))
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
        if health.hasCloudRoute { return L10n.text("settings.aiOnlineRoute", store.language) }
        if health.hasLocalModel { return L10n.text("settings.aiLocalRoute", store.language) }
        return L10n.text("settings.aiNoRoute", store.language)
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

private enum ManagementPane: String, CaseIterable, Identifiable {
    case overview
    case courses
    case models
    case rag
    case sources
    case integrations

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .overview: return "management.overview"
        case .courses: return "management.courses"
        case .models: return "management.models"
        case .rag: return "management.rag"
        case .sources: return "management.sources"
        case .integrations: return "management.integrations"
        }
    }
}

private enum SourceRegistryFilter: String, CaseIterable, Identifiable {
    case all
    case attention
    case changed
    case review

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .all: return "management.sourceFilterAll"
        case .attention: return "management.sourceFilterAttention"
        case .changed: return "management.sourceFilterChanged"
        case .review: return "management.sourceFilterReview"
        }
    }
}

private struct ManagementView: View {
    @EnvironmentObject private var store: LearningStore
    @EnvironmentObject private var backendSupervisor: LocalBackendSupervisor
    @State private var pane: ManagementPane = .overview
    @State private var sourceInventory: TrustedSourceInventory?
    @State private var sourceSearchText = ""
    @State private var sourceFilter = SourceRegistryFilter.all
    @State private var ragQuery = ""
    @State private var ragSearchResult: KnowledgeRAGSearchResult?
    @State private var includeObsidianRAG = false
    @State private var isSearchingRAG = false
    @State private var isLoading = false
    @State private var isRefreshingIndex = false
    @State private var isCheckingSources = false
    @State private var routeSubject: Subject = .mathematics
    @State private var routeProvider = "auto"
    @State private var routeModel = ""
    @State private var autoAgentRole = "local_draft"
    @State private var autoAgentProvider = "auto"
    @State private var autoAgentModel = ""
    @State private var finalSynthesisProvider = "auto"
    @State private var finalSynthesisModel = ""
    @State private var compatibleBaseURL = ""
    @State private var compatibleModel = ""
    @State private var isSavingCompatibleSettings = false
    @State private var allowsPaidAutoRoutes = false
    @State private var isSavingRoute = false
    @State private var isSavingCostPolicy = false
    @State private var isPreparingBackup = false
    @State private var isRestoringBackup = false
    @State private var isExportingBackup = false
    @State private var isExportingDiagnostics = false
    @State private var isImportingBackup = false
    @State private var showingRestoreConfirmation = false
    @State private var progressBackupDocument: LearningProgressBackupFile?
    @State private var diagnosticsDocument: LearningProgressBackupFile?
    @State private var pendingBackupData: Data?
    @State private var statusMessage: String?
    @State private var statusIsError = false

    let openSettings: () -> Void

    private let metricColumns = [GridItem(.adaptive(minimum: 190), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.text("management.title", store.language))
                        .font(.largeTitle.weight(.bold))
                    Text(L10n.text("management.subtitle", store.language))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button {
                    Task { await reload() }
                } label: {
                    if isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
                .help(L10n.text("management.reload", store.language))
                .accessibilityLabel(L10n.text("management.reload", store.language))
            }

            Picker(L10n.text("management.title", store.language), selection: $pane) {
                ForEach(ManagementPane.allCases) { section in
                    Text(L10n.text(section.titleKey, store.language)).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 900)

            if let statusMessage {
                Label(statusMessage, systemImage: statusIsError ? "exclamationmark.triangle" : "checkmark.circle")
                    .font(.callout)
                    .foregroundStyle(statusIsError ? Color.orange : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Group {
                switch pane {
                case .overview:
                    overviewPane
                case .courses:
                    coursesPane
                case .models:
                    modelsPane
                case .rag:
                    ragPane
                case .sources:
                    sourcesPane
                case .integrations:
                    integrationsPane
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(28)
        .frame(maxWidth: 1120, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(Text(L10n.text("management.title", store.language)))
        .onChange(of: routeSubject) { _ in syncSubjectModelRouteForm() }
        .onChange(of: autoAgentRole) { _ in syncAutoAgentModelForm() }
        .onChange(of: autoAgentProvider) { provider in
            if provider == "auto" { autoAgentModel = "" }
        }
        .onChange(of: finalSynthesisProvider) { provider in
            if provider == "auto" { finalSynthesisModel = "" }
        }
        .onChange(of: routeProvider) { provider in
            if provider == "auto" { routeModel = "" }
        }
        .task { await reload() }
        .task(id: pane) {
            guard pane == .sources else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000_000)
                guard !Task.isCancelled else { break }
                if let latestInventory = try? await OrchestratorClient.trustedSourceInventory() {
                    sourceInventory = latestInventory
                }
            }
        }
        .fileExporter(
            isPresented: $isExportingBackup,
            document: progressBackupDocument,
            contentType: .json,
            defaultFilename: "ColiDev-Learning-Progress"
        ) { result in
            switch result {
            case .success(let url):
                statusMessage = String(
                    format: L10n.text("management.backupExported", store.language),
                    url.lastPathComponent
                )
                statusIsError = false
            case .failure(let error):
                if (error as? CocoaError)?.code == .userCancelled {
                    statusMessage = nil
                } else {
                    reportError("management.backupFailed")
                }
            }
        }
        .fileExporter(
            isPresented: $isExportingDiagnostics,
            document: diagnosticsDocument,
            contentType: .json,
            defaultFilename: "ColiDev-Diagnostics"
        ) { result in
            switch result {
            case .success(let url):
                statusMessage = String(
                    format: L10n.text("management.diagnosticsExported", store.language),
                    url.lastPathComponent
                )
                statusIsError = false
            case .failure(let error):
                if (error as? CocoaError)?.code == .userCancelled {
                    statusMessage = nil
                } else {
                    reportError("management.diagnosticsFailed")
                }
            }
        }
        .fileImporter(
            isPresented: $isImportingBackup,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                do {
                    let handle = try FileHandle(forReadingFrom: url)
                    defer { try? handle.close() }
                    let data = try handle.read(upToCount: 1_048_577) ?? Data()
                    guard data.count <= 1_048_576 else {
                        reportError("management.backupTooLarge")
                        return
                    }
                    pendingBackupData = data
                    showingRestoreConfirmation = true
                } catch {
                    reportError("management.backupFailed")
                }
            case .failure(let error):
                if (error as? CocoaError)?.code == .userCancelled {
                    statusMessage = nil
                } else {
                    reportError("management.backupFailed")
                }
            }
        }
        .confirmationDialog(
            L10n.text("management.backupConfirmTitle", store.language),
            isPresented: $showingRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("management.backupConfirmAction", store.language), role: .destructive) {
                Task { await restoreProgressBackup() }
            }
            Button(L10n.text("management.backupCancel", store.language), role: .cancel) {
                pendingBackupData = nil
            }
        } message: {
            Text(L10n.text("management.backupConfirmMessage", store.language))
        }
    }

    private var overviewPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 12) {
                    metric(
                        title: L10n.text("management.backend", store.language),
                        value: backendSupervisor.isReady
                            ? L10n.text("management.backendReady", store.language)
                            : L10n.text("management.backendUnavailable", store.language),
                        symbol: backendSupervisor.isReady ? "checkmark.circle.fill" : "exclamationmark.circle",
                        tint: backendSupervisor.isReady ? .green : .orange
                    )
                    metric(
                        title: L10n.text("management.indexedDocuments", store.language),
                        value: store.aiHealth?.knowledgeDocumentCount.map { String($0) } ?? "—",
                        symbol: "doc.text.magnifyingglass",
                        tint: .accentColor
                    )
                    metric(
                        title: L10n.text("management.sourcesTotal", store.language),
                        value: sourceInventory.map { String($0.listedCount) } ?? "—",
                        symbol: "link",
                        tint: .accentColor
                    )
                    metric(
                        title: L10n.text("management.sourcesAttention", store.language),
                        value: sourceInventory.map { String($0.needsAttentionCount + $0.uncheckedCount) } ?? "—",
                        symbol: "exclamationmark.bubble",
                        tint: .orange
                    )
                    metric(
                        title: L10n.text("management.reviewDue", store.language),
                        value: store.aiHealth?.knowledgeReviewDueDocumentCount.map { String($0) } ?? "—",
                        symbol: "calendar.badge.exclamationmark",
                        tint: .orange
                    )
                    metric(
                        title: L10n.text("management.reviewScheduleMissing", store.language),
                        value: store.aiHealth?.knowledgeReviewScheduleMissingDocumentCount.map { String($0) } ?? "—",
                        symbol: "calendar.badge.questionmark",
                        tint: .secondary
                    )
                }

                GroupBox(label: Text(L10n.text("management.systemStatus", store.language))) {
                    VStack(spacing: 10) {
                        statusRow(
                            title: L10n.text("management.network", store.language),
                            value: L10n.text(
                                store.aiHealth?.online == true ? "management.networkOnline" : "management.networkOffline",
                                store.language
                            ),
                            symbol: store.aiHealth?.online == true ? "network" : "wifi.slash"
                        )
                        statusRow(
                            title: L10n.text("management.indexChecked", store.language),
                            value: store.aiHealth?.displayKnowledgeIndexCheckedAt ?? "—",
                            symbol: "clock"
                        )
                        statusRow(
                            title: L10n.text("management.embedding", store.language),
                            value: store.aiHealth?.ollamaEmbeddingModel
                                ?? L10n.text("settings.aiSemanticKeyword", store.language),
                            symbol: "point.3.connected.trianglepath.dotted"
                        )
                        statusRow(
                            title: L10n.text("management.dailyOnlineLimit", store.language),
                            value: dailyOnlineLimitSummary,
                            symbol: "chart.bar"
                        )
                        Text(L10n.text("management.dailyOnlineLimitCaveat", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        statusRow(
                            title: L10n.text("management.dailyCloudCalls", store.language),
                            value: dailyCloudCallSummary,
                            symbol: "cloud"
                        )
                        Text(L10n.text("management.dailyCloudCallsCaveat", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 6)
                }

                HStack(spacing: 10) {
                    Button {
                        Task { await refreshIndex() }
                    } label: {
                        if isRefreshingIndex {
                            ProgressView().controlSize(.small)
                            Text(L10n.text("management.refreshIndexRunning", store.language))
                        } else {
                            Label(L10n.text("management.refreshIndex", store.language), systemImage: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRefreshingIndex || isCheckingSources)

                    Button {
                        Task { await checkSources() }
                    } label: {
                        if isCheckingSources {
                            ProgressView().controlSize(.small)
                            Text(L10n.text("management.checkSourcesRunning", store.language))
                        } else {
                            Label(L10n.text("management.checkSources", store.language), systemImage: "checkmark.icloud")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isCheckingSources || isRefreshingIndex)

                    Button(action: prepareDiagnosticsExport) {
                        Label(L10n.text("management.diagnosticsExport", store.language), systemImage: "stethoscope")
                    }
                    .buttonStyle(.bordered)
                }

                Text(L10n.text("management.diagnosticsPrivacy", store.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let usage = store.providerUsage {
                    GroupBox(label: Text(L10n.text("settings.usageTitle", store.language))) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(format: L10n.text("management.usageResponses", store.language), usage.totals.successfulResponses))
                            Text(String(format: L10n.text("management.usageTokens", store.language), usage.totals.totalTokens))
                                .foregroundStyle(.secondary)
                            if usage.providers.isEmpty {
                                Text(L10n.text("settings.usageNoCalls", store.language))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(usage.providers) { provider in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("\(provider.provider) · \(provider.model)")
                                            .font(.callout.weight(.medium))
                                            .textSelection(.enabled)
                                        Text(String(format: L10n.text("settings.usageProviderCounts", store.language),
                                                    provider.successfulResponses,
                                                    provider.responsesWithReportedUsage,
                                                    provider.totalTokens,
                                                    provider.inputTokens,
                                                    provider.outputTokens))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.vertical, 3)
                                }
                            }
                            Text(usage.note)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)
                    }
                }
            }
            .padding(.bottom, 18)
        }
    }

    private var modelsPane: some View {
        let localRoles = store.autoAgentModelRoutes.values
            .filter { $0.effectiveProvider == "ollama" }
            .sorted { $0.role < $1.role }

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.text("management.modelsSubtitle", store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                GroupBox(label: Text(L10n.text("management.ollamaLocalService", store.language))) {
                    VStack(alignment: .leading, spacing: 10) {
                        statusRow(
                            title: "Ollama",
                            value: store.localOllamaModelCatalog.available
                                ? L10n.text("management.ollamaServiceReachable", store.language)
                                : L10n.text("management.serviceUnavailable", store.language),
                            symbol: store.localOllamaModelCatalog.available ? "checkmark.circle.fill" : "wifi.slash"
                        )
                        statusRow(
                            title: L10n.text("management.localTutorRoute", store.language),
                            value: store.aiHealth?.hasLocalModel == true
                                ? L10n.text("settings.aiLocalRoute", store.language)
                                : L10n.text("settings.aiNoLocal", store.language),
                            symbol: store.aiHealth?.hasLocalModel == true ? "checkmark.circle.fill" : "exclamationmark.circle"
                        )
                        Text(L10n.text("management.localModelsDescription", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            Task { await store.refreshLocalOllamaModelCatalog() }
                        } label: {
                            if store.isRefreshingLocalOllamaModelCatalog {
                                ProgressView().controlSize(.small)
                            } else {
                                Label(
                                    L10n.text("management.ollamaModelsRefresh", store.language),
                                    systemImage: "arrow.clockwise"
                                )
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(store.isRefreshingLocalOllamaModelCatalog)

                        if store.localOllamaModelCatalog.available {
                            if store.localOllamaModelCatalog.models.isEmpty {
                                Text(L10n.text("management.ollamaModelsEmpty", store.language))
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            } else {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(store.localOllamaModelCatalog.models, id: \.self) { model in
                                        Label(model, systemImage: "cube")
                                            .font(.callout.monospaced())
                                            .textSelection(.enabled)
                                            .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                }

                GroupBox(label: Text(L10n.text("management.localModelAssignments", store.language))) {
                    VStack(alignment: .leading, spacing: 8) {
                        if localRoles.isEmpty {
                            Text(L10n.text("management.noLocalModelRoles", store.language))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(localRoles) { route in
                                statusRow(
                                    title: L10n.text("management.autoAgentRole.\(route.role)", store.language),
                                    value: route.effectiveModel,
                                    symbol: route.effectiveProviderReady == true
                                        ? "checkmark.circle.fill"
                                        : "exclamationmark.circle"
                                )
                            }
                        }

                        Button(L10n.text("management.configureAIRoutes", store.language)) {
                            pane = .integrations
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                }
            }
            .padding(.bottom, 18)
        }
    }

    private var coursesPane: some View {
        let coverage = Subject.allCases.map { CurriculumCatalog.coverage(for: $0) }
        let totalLessons = coverage.reduce(0) { $0 + $1.bundledLessonCount }
        let bilingualLessons = coverage.reduce(0) { $0 + $1.bilingualLessonCount }
        let sourceCitedLessons = coverage.reduce(0) { $0 + $1.sourceCitedLessonCount }
        let structurallyCompleteLessons = coverage.reduce(0) { $0 + $1.structurallyCompleteLessonCount }

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.text("management.coursesDescription", store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 12) {
                    metric(
                        title: L10n.text("management.courseFiles", store.language),
                        value: String(totalLessons),
                        symbol: "books.vertical",
                        tint: .accentColor
                    )
                    metric(
                        title: L10n.text("management.courseBilingual", store.language),
                        value: "\(bilingualLessons) / \(totalLessons)",
                        symbol: "character.bubble",
                        tint: bilingualLessons == totalLessons ? .green : .orange
                    )
                    metric(
                        title: L10n.text("management.courseWithSources", store.language),
                        value: "\(sourceCitedLessons) / \(totalLessons)",
                        symbol: "link",
                        tint: sourceCitedLessons == totalLessons ? .green : .orange
                    )
                    metric(
                        title: L10n.text("management.courseStructured", store.language),
                        value: "\(structurallyCompleteLessons) / \(totalLessons)",
                        symbol: "checklist",
                        tint: structurallyCompleteLessons == totalLessons ? .green : .orange
                    )
                }

                ForEach(coverage) { subjectCoverage in
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: subjectCoverage.subject.symbol)
                                    .foregroundStyle(subjectCoverage.subject.tint)
                                    .frame(width: 22)
                                Text(subjectCoverage.subject.title(in: store.language))
                                    .font(.headline)
                                Spacer()
                                Text(String(
                                    format: L10n.text("management.courseSubjectSummary", store.language),
                                    subjectCoverage.bilingualLessonCount,
                                    subjectCoverage.bundledLessonCount,
                                    subjectCoverage.structurallyCompleteLessonCount,
                                    subjectCoverage.topicCount
                                ))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            }

                            ForEach(subjectCoverage.levels) { level in
                                HStack {
                                    Text(level.level.value(in: store.language))
                                        .frame(minWidth: 105, alignment: .leading)
                                    Spacer()
                                    Text(String(
                                        format: L10n.text("management.courseLevelSummary", store.language),
                                        level.linkedLessonCount,
                                        level.topicCount
                                    ))
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(level.linkedLessonCount == level.topicCount ? Color.green : Color.secondary)
                                }
                                .font(.subheadline)
                            }

                            if subjectCoverage.lessonStructureIssues.isEmpty {
                                Label(
                                    L10n.text("management.courseStructureComplete", store.language),
                                    systemImage: "checkmark.circle.fill"
                                )
                                .font(.caption)
                                .foregroundStyle(.green)
                            } else {
                                DisclosureGroup {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(subjectCoverage.lessonStructureIssues) { issue in
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(String(
                                                    format: L10n.text("management.courseStructureResource", store.language),
                                                    issue.resource
                                                ))
                                                .font(.caption.weight(.semibold))
                                                Text(String(
                                                    format: L10n.text("management.courseStructureRussian", store.language),
                                                    structureSectionSummary(issue.missingRussianSections)
                                                ))
                                                .font(.caption)
                                                Text(String(
                                                    format: L10n.text("management.courseStructureEnglish", store.language),
                                                    structureSectionSummary(issue.missingEnglishSections)
                                                ))
                                                .font(.caption)
                                                if issue.missingSources {
                                                    Text(L10n.text("management.courseStructureSources", store.language))
                                                        .font(.caption)
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 5)
                                        }
                                    }
                                    .padding(.top, 8)
                                } label: {
                                    Label(
                                        String(
                                            format: L10n.text("management.courseStructureIssues", store.language),
                                            subjectCoverage.lessonStructureIssues.count
                                        ),
                                        systemImage: "exclamationmark.circle"
                                    )
                                    .font(.caption.weight(.medium))
                                }
                                .tint(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 5)
                    }
                }

                Label(L10n.text("management.courseCoverageCaveat", store.language), systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 18)
        }
    }

    private func structureSectionSummary(_ sectionKeys: [String]) -> String {
        guard !sectionKeys.isEmpty else {
            return L10n.text("management.courseStructureNone", store.language)
        }
        return sectionKeys
            .map { L10n.text($0, store.language) }
            .joined(separator: ", ")
    }

    private var ragPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("management.ragExplanation", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                TextField(L10n.text("management.ragQuery", store.language), text: $ragQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await searchRAG() } }

                Button {
                    Task { await searchRAG() }
                } label: {
                    if isSearchingRAG {
                        ProgressView().controlSize(.small)
                    } else {
                        Label(L10n.text("management.ragSearch", store.language), systemImage: "magnifyingglass")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSearchingRAG || ragQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Toggle(L10n.text("management.ragIncludeObsidian", store.language), isOn: $includeObsidianRAG)
                .toggleStyle(.checkbox)

            if let ragSearchResult {
                HStack {
                    Label(
                        String(format: L10n.text("management.ragResultCount", store.language), ragSearchResult.sourceCount),
                        systemImage: "doc.text.magnifyingglass"
                    )
                    Spacer()
                    Text(ragSearchResult.generatedAt)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }

                if ragSearchResult.sources.isEmpty {
                    Label(L10n.text("management.ragNoResults", store.language), systemImage: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(ragSearchResult.sources) { source in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(source.id)
                                    .font(.caption.weight(.bold).monospaced())
                                    .foregroundStyle(Color.accentColor)
                                Text(source.title)
                                    .font(.headline)
                                    .textSelection(.enabled)
                                Spacer(minLength: 8)
                                Text(L10n.text("management.ragType.\(source.sourceType ?? "course")", store.language))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }

                            Text(source.excerpt)
                                .font(.callout)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)

                            if let path = source.path {
                                if source.sourceType == "official_web", let url = URL(string: path) {
                                    Link(path, destination: url)
                                        .font(.caption.monospaced())
                                        .lineLimit(2)
                                        .textSelection(.enabled)
                                } else {
                                    Text(source.location.map { "\(path):\($0)" } ?? path)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.tertiary)
                                        .textSelection(.enabled)
                                }
                            }

                            HStack(spacing: 12) {
                                Text("\(L10n.text("management.ragRetrieved", store.language)): \(source.displayRetrievedAt)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                if let sourceCheckedAt = source.sourceCheckedAt {
                                    Text("\(L10n.text("management.ragFreshness", store.language)): \(sourceCheckedAt)")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            if let license = source.license {
                                Text("\(license) · \(source.attribution ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if let licenseURL = source.licenseURL, let url = URL(string: licenseURL) {
                                Link(L10n.text("management.ragLicense", store.language), destination: url)
                                    .font(.caption)
                            }

                            if let references = source.officialReferences, !references.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(references) { reference in
                                        if let url = URL(string: reference.url) {
                                            Link(reference.title, destination: url)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .listStyle(.inset)
                    .frame(minHeight: 320)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text(L10n.text("management.ragEmptyTitle", store.language))
                        .font(.headline)
                    Text(L10n.text("management.ragEmptyBody", store.language))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var sourcesPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("management.sourceExplanation", store.language))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let automaticCheckEnabled = sourceInventory?.automaticCheckEnabled {
                Label(
                    automaticCheckEnabled
                        ? String(
                            format: L10n.text("management.autoSourceCheckEnabled", store.language),
                            sourceInventory?.automaticCheckIntervalHours ?? 24
                        )
                        : L10n.text("management.autoSourceCheckDisabled", store.language),
                    systemImage: automaticCheckEnabled ? "clock.arrow.circlepath" : "pause.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                TextField(L10n.text("management.sourceSearch", store.language), text: $sourceSearchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 320)

                Picker(selection: $sourceFilter) {
                    ForEach(SourceRegistryFilter.allCases) { filter in
                        Text(L10n.text(filter.titleKey, store.language)).tag(filter)
                    }
                } label: {
                    Label(L10n.text("management.sourceFilter", store.language), systemImage: "line.3.horizontal.decrease")
                }
                .pickerStyle(.menu)

                Spacer(minLength: 8)

                Button {
                    Task { await checkSources() }
                } label: {
                    if isCheckingSources {
                        ProgressView().controlSize(.small)
                        Text(L10n.text("management.checkSourcesRunning", store.language))
                    } else {
                        Label(L10n.text("management.checkSources", store.language), systemImage: "checkmark.icloud")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCheckingSources || isRefreshingIndex)

                if let sourceInventory {
                    Text("\(visibleSourceItems.count) / \(sourceInventory.listedCount)")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            if let sourceInventory {
                let due = sourceInventory.editorialReviewDueCount ?? 0
                let missingDate = sourceInventory.editorialReviewMissingCount ?? 0
                let missingSchedule = sourceInventory.editorialReviewUnscheduledCount ?? 0
                if due + missingDate + missingSchedule > 0 {
                    Label(
                        String(
                            format: L10n.text("management.editorialReviewSummary", store.language),
                            due,
                            missingDate,
                            missingSchedule
                        ),
                        systemImage: due > 0 || missingDate > 0
                            ? "exclamationmark.circle.fill"
                            : "calendar.badge.clock"
                    )
                    .font(.caption)
                    .foregroundStyle(due > 0 || missingDate > 0 ? Color.orange : Color.secondary)
                }
            }

            if let sourceInventory {
                if sourceInventory.sources.isEmpty {
                    Label(L10n.text("management.noSources", store.language), systemImage: "link")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if visibleSourceItems.isEmpty {
                    Label(L10n.text("management.sourceNoMatches", store.language), systemImage: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(visibleSourceItems) { source in
                        SourceRegistryRow(source: source, language: store.language) {
                            Task { await reloadSourceInventory() }
                        }
                    }
                    .listStyle(.inset)
                    .frame(minHeight: 320)
                }
                if sourceInventory.unsupportedCount > 0 || sourceInventory.omittedCount > 0 {
                    Text(String(format: L10n.text("management.sourceOmissions", store.language), sourceInventory.unsupportedCount, sourceInventory.omittedCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if isLoading {
                ProgressView(L10n.text("management.loading", store.language))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Label(L10n.text("management.loadFailed", store.language), systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var visibleSourceItems: [TrustedSourceInventoryItem] {
        let sources = sourceInventory?.sources ?? []
        let query = sourceSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return sources.filter { source in
            let lessonPaths = source.lessonPaths ?? [source.lessonPath]
            let subjectNames: [(folder: String, ru: String, en: String)] = [
                ("Mathematics", "Математика", "Mathematics"),
                ("English", "Английский", "English"),
                ("Physics", "Физика", "Physics"),
                ("Biology", "Биология", "Biology"),
                ("Zoology", "Зоология", "Zoology"),
                ("Programming", "Программирование", "Programming"),
            ]
            let subjectSearchText = subjectNames
                .filter { subject in
                    lessonPaths.contains { $0.localizedCaseInsensitiveContains("/\(subject.folder)/") }
                }
                .map { "\($0.ru) \($0.en)" }
                .joined(separator: " ")
            let searchableText = [
                source.title,
                source.pageTitle ?? "",
                source.pageDescription ?? "",
                source.url,
                subjectSearchText,
                lessonPaths.joined(separator: " "),
            ].joined(separator: " ")
            guard query.isEmpty || searchableText.localizedCaseInsensitiveContains(query) else {
                return false
            }

            let reviewStatuses = source.lessonReviews?.map(\.editorialReviewStatus)
                ?? [source.editorialReviewStatus ?? "review_missing"]
            switch sourceFilter {
            case .all:
                return true
            case .attention:
                return source.state != "unchanged" || reviewStatuses.contains { $0 != "review_scheduled" }
            case .changed:
                return source.state == "changed"
            case .review:
                return reviewStatuses.contains { $0 != "review_scheduled" }
            }
        }
    }

    private var dailyOnlineLimitSummary: String {
        guard let current = store.aiHealth?.sessionCurrent,
              let maximum = store.aiHealth?.sessionMax else {
            return "—"
        }
        return String(format: L10n.text("management.dailyOnlineLimitValue", store.language), current, maximum)
    }

    private func prepareDiagnosticsExport() {
        let health = store.aiHealth
        let inventory = sourceInventory
        let usage = store.providerUsage
        let coverage: [[String: Any]] = Subject.allCases.map { subject in
            let value = CurriculumCatalog.coverage(for: subject)
            return [
                "subject": subject.rawValue,
                "bundled_lessons": value.bundledLessonCount,
                "bilingual_lessons": value.bilingualLessonCount,
                "lessons_with_sources": value.sourceCitedLessonCount,
                "roadmap_topics": value.topicCount,
                "topics_linked_to_full_lessons": value.linkedLessonCount,
            ]
        }
        let modelUsage: [[String: Any]] = usage?.providers.map { provider in
            [
                "provider": provider.provider,
                "model": provider.model,
                "successful_responses": provider.successfulResponses,
                "reported_tokens": provider.totalTokens,
            ]
        } ?? []
        let report: [String: Any] = [
            "schema_version": 1,
            "generated_at": ISO8601DateFormatter().string(from: Date()),
            "app": [
                "bundle_identifier": Bundle.main.bundleIdentifier ?? "unknown",
                "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                "language": store.language.rawValue,
            ],
            "system": [
                "operating_system": ProcessInfo.processInfo.operatingSystemVersionString,
            ],
            "backend": [
                "ready": backendSupervisor.isReady,
                "health_available": health != nil,
                "online": health?.online as Any? ?? NSNull(),
                "ollama_available": health?.ollamaAvailable as Any? ?? NSNull(),
                "ollama_model_ready": health?.ollamaModelReady as Any? ?? NSNull(),
                "ollama_endpoint_is_local": health?.isOllamaEndpointLocal as Any? ?? NSNull(),
                "obsidian_endpoint_is_local": health?.isObsidianEndpointLocal as Any? ?? NSNull(),
                "indexed_documents": health?.knowledgeDocumentCount as Any? ?? NSNull(),
                "index_checked_at": health?.knowledgeIndexCheckedAt as Any? ?? NSNull(),
                "online_requests_today": health?.sessionCurrent as Any? ?? NSNull(),
                "online_requests_daily_limit": health?.sessionMax as Any? ?? NSNull(),
                "cloud_model_calls_today": health?.cloudModelCallsToday as Any? ?? NSNull(),
                "cloud_model_calls_daily_limit": health?.cloudModelCallsMax as Any? ?? NSNull(),
                "review_items_due": health?.knowledgeReviewDueDocumentCount as Any? ?? NSNull(),
                "review_schedules_missing": health?.knowledgeReviewScheduleMissingDocumentCount as Any? ?? NSNull(),
            ],
            "sources": [
                "inventory_available": inventory != nil,
                "listed": inventory?.listedCount as Any? ?? NSNull(),
                "unchecked": inventory?.uncheckedCount as Any? ?? NSNull(),
                "changed": inventory?.changedCount as Any? ?? NSNull(),
                "needs_attention": inventory?.needsAttentionCount as Any? ?? NSNull(),
                "automatic_check_enabled": inventory?.automaticCheckEnabled as Any? ?? NSNull(),
                "automatic_check_interval_hours": inventory?.automaticCheckIntervalHours as Any? ?? NSNull(),
                "unsupported": inventory?.unsupportedCount as Any? ?? NSNull(),
                "omitted": inventory?.omittedCount as Any? ?? NSNull(),
            ],
            "curriculum": coverage,
            "provider_usage": [
                "available": usage != nil,
                "period_days": usage?.periodDays as Any? ?? NSNull(),
                "successful_responses": usage?.totals.successfulResponses as Any? ?? NSNull(),
                "reported_tokens": usage?.totals.totalTokens as Any? ?? NSNull(),
                "models": modelUsage,
            ],
            "privacy": [
                "api_keys_included": false,
                "chat_messages_included": false,
                "learning_reflections_included": false,
                "source_page_text_included": false,
            ],
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            diagnosticsDocument = LearningProgressBackupFile(data: data)
            statusMessage = nil
            isExportingDiagnostics = true
        } catch {
            reportError("management.diagnosticsFailed")
        }
    }

    private var dailyCloudCallSummary: String {
        guard let current = store.aiHealth?.cloudModelCallsToday,
              let maximum = store.aiHealth?.cloudModelCallsMax else {
            return L10n.text("management.usageUnknown", store.language)
        }
        return String(format: L10n.text("management.dailyOnlineLimitValue", store.language), current, maximum)
    }

    private var integrationsPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox(label: Text(L10n.text("management.providers", store.language))) {
                    VStack(spacing: 10) {
                        integrationRow(
                            title: "Gemini",
                            symbol: "sparkles",
                            detail: keyStatus("gemini"),
                            ready: store.providerSecretStatuses["gemini"]?.configured == true
                        )
                        integrationRow(
                            title: "Kimi",
                            symbol: "brain.head.profile",
                            detail: keyStatus("kimi"),
                            ready: store.providerSecretStatuses["kimi"]?.configured == true
                        )
                        integrationRow(
                            title: "OpenRouter",
                            symbol: "point.3.connected.trianglepath.dotted",
                            detail: store.aiHealth?.openRouterModel ?? keyStatus("openrouter"),
                            ready: store.providerSecretStatuses["openrouter"]?.configured == true
                        )
                        integrationRow(
                            title: L10n.text("management.compatibleTitle", store.language),
                            symbol: "point.3.connected.trianglepath.dotted",
                            detail: store.openAICompatibleSettings?.baseURL.isEmpty == false
                                ? (store.openAICompatibleSettings?.model ?? "")
                                : L10n.text("management.notConfigured", store.language),
                            ready: store.providerSecretStatuses["compatible"]?.configured == true
                                && store.openAICompatibleSettings?.providerReady == true
                        )
                        integrationRow(
                            title: "Ollama",
                            symbol: "desktopcomputer",
                            detail: store.aiHealth?.ollamaModel ?? L10n.text("management.serviceUnavailable", store.language),
                            ready: store.aiHealth?.hasLocalModel == true
                        )
                        integrationRow(
                            title: "Obsidian",
                            symbol: "externaldrive",
                            detail: store.aiHealth?.isObsidianEndpointLocal == true
                                ? keyStatus("obsidian")
                                : L10n.text("management.serviceUnavailable", store.language),
                            ready: store.aiHealth?.isObsidianEndpointLocal == true
                                && store.providerSecretStatuses["obsidian"]?.configured == true
                        )
                        integrationRow(
                            title: "NotebookLM",
                            symbol: "doc.on.doc",
                            detail: L10n.text("management.notebookManual", store.language),
                            ready: nil
                        )
                    }
                    .padding(.top, 6)
                }

                GroupBox(label: Text(L10n.text("settings.keysTitle", store.language))) {
                    VStack(alignment: .leading, spacing: 12) {
                        ProviderKeyEntryView(provider: "gemini", title: "Gemini")
                        ProviderKeyEntryView(provider: "kimi", title: "Kimi")
                        ProviderKeyEntryView(provider: "openrouter", title: "OpenRouter")
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.text("management.compatibleTitle", store.language))
                                .font(.headline)
                            Text(L10n.text("management.compatibleHelp", store.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            TextField(
                                L10n.text("management.compatibleBaseURL", store.language),
                                text: $compatibleBaseURL
                            )
                            .textFieldStyle(.roundedBorder)
                            TextField(
                                L10n.text("management.compatibleModel", store.language),
                                text: $compatibleModel
                            )
                            .textFieldStyle(.roundedBorder)
                            HStack {
                                Button {
                                    Task { await saveCompatibleSettings() }
                                } label: {
                                    if isSavingCompatibleSettings {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Text(L10n.text("management.compatibleSave", store.language))
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(isSavingCompatibleSettings)
                                if let config = store.openAICompatibleSettings, config.providerReady {
                                    Label(L10n.text("management.compatibleReady", store.language), systemImage: "checkmark.circle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            ProviderKeyEntryView(
                                provider: "compatible",
                                title: L10n.text("management.compatibleKeyTitle", store.language)
                            )
                        }
                        .padding(.vertical, 4)
                        ProviderKeyEntryView(provider: "obsidian", title: "Obsidian Local REST API")
                        Text(L10n.text("settings.keysPrivacy", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 6)
                }

                GroupBox(label: Text(L10n.text("management.agents", store.language))) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(L10n.text("management.agentStatus", store.language))
                            .font(.callout)
                        Text(L10n.text("management.agentCaveat", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                }

                GroupBox(label: Text(L10n.text("management.backupTitle", store.language))) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("management.backupDescription", store.language))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(L10n.text("management.backupPrivacy", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 10) {
                            Button {
                                Task { await prepareProgressBackup() }
                            } label: {
                                if isPreparingBackup {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Label(L10n.text("management.backupExport", store.language), systemImage: "square.and.arrow.down")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isPreparingBackup || isRestoringBackup)

                            Button {
                                isImportingBackup = true
                            } label: {
                                Label(L10n.text("management.backupImport", store.language), systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                            .disabled(isPreparingBackup || isRestoringBackup)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                }

                GroupBox(label: Text(L10n.text("management.autoCostPolicy", store.language))) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("management.autoCostPolicyHelp", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Toggle(
                            L10n.text("management.allowPaidAutoRoutes", store.language),
                            isOn: $allowsPaidAutoRoutes
                        )

                        Button {
                            Task { await saveAutoCostPolicy() }
                        } label: {
                            if isSavingCostPolicy {
                                ProgressView().controlSize(.small)
                            } else {
                                Text(L10n.text("management.saveCostPolicy", store.language))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSavingCostPolicy)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                }

                GroupBox(label: Text(L10n.text("management.finalSynthesis", store.language))) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("management.finalSynthesisHelp", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Picker(L10n.text("management.routeProvider", store.language), selection: $finalSynthesisProvider) {
                            ForEach(["auto", "gemini", "kimi", "openrouter", "compatible", "ollama"], id: \.self) { provider in
                                Text(L10n.text("management.routeProvider.\(provider)", store.language))
                                    .tag(provider)
                            }
                        }
                        .frame(maxWidth: 360, alignment: .leading)

                        if finalSynthesisProvider != "auto" {
                            TextField(L10n.text("management.routeModel", store.language), text: $finalSynthesisModel)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 520)
                        }
                        if finalSynthesisProvider != "ollama"
                            && (finalSynthesisProvider != "auto"
                                || store.finalSynthesisModelRoute?.effectiveProvider != "ollama") {
                            Label(
                                L10n.text("management.autoAgentCloudNotice", store.language),
                                systemImage: "exclamationmark.triangle"
                            )
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        if let route = store.finalSynthesisModelRoute {
                            HStack(spacing: 8) {
                                Image(systemName: route.providerReady == false
                                      ? "exclamationmark.circle"
                                      : (route.provider == "auto" ? "arrow.triangle.2.circlepath" : "checkmark.circle"))
                                    .foregroundStyle(route.providerReady == false ? Color.orange : Color.secondary)
                                Text(L10n.text("management.routeStatus.\(route.status)", store.language))
                                Text(route.effectiveModel)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                            .font(.caption)
                            .accessibilityElement(children: .combine)
                        }

                        HStack(spacing: 10) {
                            Button {
                                Task { await saveFinalSynthesisRoute() }
                            } label: {
                                if isSavingRoute {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Text(L10n.text("management.routeSave", store.language))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSavingRoute)

                            Button(L10n.text("management.routeReset", store.language)) {
                                Task { await resetFinalSynthesisRoute() }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isSavingRoute)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                }

                GroupBox(label: Text(L10n.text("management.subjectRouting", store.language))) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker(L10n.text("management.routeSubject", store.language), selection: $routeSubject) {
                            ForEach(Subject.allCases) { subject in
                                Text(subject.title(in: store.language)).tag(subject)
                            }
                        }
                        .frame(maxWidth: 360, alignment: .leading)

                        Picker(L10n.text("management.routeProvider", store.language), selection: $routeProvider) {
                            ForEach(["auto", "gemini", "kimi", "openrouter", "compatible", "ollama"], id: \.self) { provider in
                                Text(L10n.text("management.routeProvider.\(provider)", store.language))
                                    .tag(provider)
                            }
                        }
                        .frame(maxWidth: 360, alignment: .leading)

                        if routeProvider != "auto" {
                            TextField(L10n.text("management.routeModel", store.language), text: $routeModel)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 520)
                            Text(L10n.text("management.routeModelHelp", store.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if routeProvider != "ollama" {
                            Label(
                                L10n.text("management.autoAgentCloudNotice", store.language),
                                systemImage: "exclamationmark.triangle"
                            )
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        if let route = store.subjectModelRoutes[routeSubject.rawValue] {
                            HStack(spacing: 8) {
                                Image(systemName: route.providerReady == false
                                      ? "exclamationmark.circle"
                                      : (route.provider == "auto" ? "arrow.triangle.2.circlepath" : "checkmark.circle"))
                                    .foregroundStyle(route.providerReady == false ? Color.orange : Color.secondary)
                                Text(L10n.text("management.routeStatus.\(route.status)", store.language))
                                if let model = route.effectiveModel {
                                    Text(model).font(.caption.monospaced()).foregroundStyle(.secondary)
                                }
                            }
                            .font(.caption)
                            .accessibilityElement(children: .combine)
                        }

                        HStack(spacing: 10) {
                            Button {
                                Task { await saveSubjectModelRoute() }
                            } label: {
                                if isSavingRoute {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Text(L10n.text("management.routeSave", store.language))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSavingRoute)

                            Button(L10n.text("management.routeReset", store.language)) {
                                Task { await resetSubjectModelRoute() }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isSavingRoute)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                }

                GroupBox(label: Text(L10n.text("management.autoAgentModels", store.language))) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("management.autoAgentModelsHelp", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Picker(L10n.text("management.autoAgentRole", store.language), selection: $autoAgentRole) {
                            ForEach(["local_draft", "gemini_draft", "critic", "verifier"], id: \.self) { role in
                                Text(L10n.text("management.autoAgentRole.\(role)", store.language)).tag(role)
                            }
                        }
                        .frame(maxWidth: 360, alignment: .leading)

                        Picker(L10n.text("management.routeProvider", store.language), selection: $autoAgentProvider) {
                            ForEach(["auto", "ollama", "openrouter", "gemini", "kimi", "compatible"], id: \.self) { provider in
                                Text(L10n.text("management.routeProvider.\(provider)", store.language))
                                    .tag(provider)
                            }
                        }
                        .frame(maxWidth: 360, alignment: .leading)

                        if autoAgentProvider != "auto" {
                            TextField(L10n.text("management.routeModel", store.language), text: $autoAgentModel)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 520)
                        }
                        if autoAgentProvider == "ollama" {
                            HStack(spacing: 10) {
                                Button {
                                    Task { await store.refreshLocalOllamaModelCatalog() }
                                } label: {
                                    if store.isRefreshingLocalOllamaModelCatalog {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Label(
                                            L10n.text("management.ollamaModelsRefresh", store.language),
                                            systemImage: "arrow.clockwise"
                                        )
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(store.isRefreshingLocalOllamaModelCatalog)

                                Menu {
                                    ForEach(store.localOllamaModelCatalog.models, id: \.self) { model in
                                        Button(model) { autoAgentModel = model }
                                    }
                                } label: {
                                    Label(
                                        L10n.text("management.ollamaModelsChoose", store.language),
                                        systemImage: "list.bullet"
                                    )
                                }
                                .disabled(store.localOllamaModelCatalog.models.isEmpty)
                            }
                            if store.localOllamaModelCatalog.available {
                                Text(store.localOllamaModelCatalog.models.isEmpty
                                    ? L10n.text("management.ollamaModelsEmpty", store.language)
                                    : L10n.text("management.ollamaModelsReady", store.language))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if store.localOllamaModelCatalog.status != "not_checked" {
                                Text(L10n.text(
                                    "management.ollamaModelsStatus.\(store.localOllamaModelCatalog.status)",
                                    store.language
                                ))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if autoAgentProvider != "ollama"
                            && (autoAgentProvider != "auto"
                                || store.autoAgentModelRoutes[autoAgentRole]?.effectiveProvider != "ollama") {
                            Label(
                                L10n.text("management.autoAgentCloudNotice", store.language),
                                systemImage: "exclamationmark.triangle"
                            )
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        Text(L10n.text("management.autoAgentModelHelp", store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let route = store.autoAgentModelRoutes[autoAgentRole] {
                            HStack(spacing: 8) {
                                Image(systemName: route.effectiveProviderReady == false ? "exclamationmark.circle" : "checkmark.circle")
                                    .foregroundStyle(route.effectiveProviderReady == false ? Color.orange : Color.secondary)
                                Text(L10n.text("management.routeStatus.\(route.status)", store.language))
                                Text("\(route.effectiveProvider) · \(route.effectiveModel)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                            .font(.caption)
                            .accessibilityElement(children: .combine)
                        }

                        HStack(spacing: 10) {
                            Button {
                                Task { await saveAutoAgentModel() }
                            } label: {
                                if isSavingRoute {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Text(L10n.text("management.routeSave", store.language))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSavingRoute)

                            Button(L10n.text("management.routeReset", store.language)) {
                                Task { await resetAutoAgentModel() }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isSavingRoute)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                }

                Button(L10n.text("management.openSettings", store.language), action: openSettings)
                    .buttonStyle(.bordered)
            }
            .padding(.bottom, 18)
        }
    }

    private func metric(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(Color.secondary.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
    }

    private func statusRow(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(title)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }

    private func integrationRow(title: String, symbol: String, detail: String, ready: Bool?) -> some View {
        HStack(spacing: 10) {
            Label(title, systemImage: symbol)
            Spacer(minLength: 10)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
            if let ready {
                Image(systemName: ready ? "checkmark.circle.fill" : "minus.circle")
                    .foregroundStyle(ready ? Color.green : Color.secondary)
                    .accessibilityLabel(L10n.text(ready ? "management.serviceReady" : "management.serviceUnavailable", store.language))
            }
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }

    private func keyStatus(_ provider: String) -> String {
        guard let status = store.providerSecretStatuses[provider] else {
            return L10n.text("management.notConfigured", store.language)
        }
        switch status.source {
        case "keychain": return L10n.text("settings.keyStatusKeychain", store.language)
        case "environment": return L10n.text("settings.keyStatusEnvironment", store.language)
        case "missing": return L10n.text("management.notConfigured", store.language)
        default: return L10n.text("management.serviceUnavailable", store.language)
        }
    }

    @MainActor
    private func reloadSourceInventory() async {
        guard let latest = try? await OrchestratorClient.trustedSourceInventory() else { return }
        sourceInventory = latest
    }

    @MainActor
    private func prepareProgressBackup() async {
        isPreparingBackup = true
        defer { isPreparingBackup = false }
        guard await backendSupervisor.ensureRunning() else {
            reportError("management.backupFailed")
            return
        }
        await store.syncStudyProgress()
        guard store.pendingStudyReviewCount == 0 else {
            reportError("management.backupSyncFailed")
            return
        }
        do {
            let data = try await OrchestratorClient.learningProgressBackup()
            progressBackupDocument = LearningProgressBackupFile(data: data)
            isExportingBackup = true
        } catch {
            reportError("management.backupFailed")
        }
    }

    @MainActor
    private func restoreProgressBackup() async {
        guard let pendingBackupData else { return }
        isRestoringBackup = true
        defer {
            isRestoringBackup = false
            self.pendingBackupData = nil
        }
        guard await backendSupervisor.ensureRunning() else {
            reportError("management.backupFailed")
            return
        }
        await store.syncStudyProgress()
        guard store.pendingStudyReviewCount == 0 else {
            reportError("management.backupSyncFailed")
            return
        }
        do {
            let result = try await OrchestratorClient.restoreLearningProgressBackup(pendingBackupData)
            await store.syncStudyProgress()
            statusMessage = String(
                format: L10n.text("management.backupRestored", store.language),
                result.restored,
                result.unchanged
            )
            statusIsError = false
        } catch {
            reportError("management.backupFailed")
        }
    }

    @MainActor
    private func reload() async {
        isLoading = true
        defer { isLoading = false }
        guard await backendSupervisor.ensureRunning() else {
            statusMessage = L10n.text("management.loadFailed", store.language)
            statusIsError = true
            return
        }
        await store.refreshAIStatus()
        await store.refreshProviderSecretStatuses()
        await store.refreshOpenAICompatibleSettings()
        await store.refreshSubjectModelRoutes()
        await store.refreshAutoAgentModelRoutes()
        await store.refreshLocalOllamaModelCatalog()
        await store.refreshFinalSynthesisModelRoute()
        await store.refreshAutoCostPolicy()
        await store.refreshProviderUsage()
        syncSubjectModelRouteForm()
        syncAutoAgentModelForm()
        syncFinalSynthesisRouteForm()
        syncAutoCostPolicyForm()
        compatibleBaseURL = store.openAICompatibleSettings?.baseURL ?? ""
        compatibleModel = store.openAICompatibleSettings?.model ?? ""
        do {
            sourceInventory = try await OrchestratorClient.trustedSourceInventory()
            statusMessage = nil
            statusIsError = false
        } catch {
            sourceInventory = nil
            statusMessage = L10n.text("management.loadFailed", store.language)
            statusIsError = true
        }
    }

    @MainActor
    private func refreshIndex() async {
        isRefreshingIndex = true
        defer { isRefreshingIndex = false }
        guard await backendSupervisor.ensureRunning() else {
            reportError("management.refreshIndexFailed")
            return
        }
        do {
            let result = try await OrchestratorClient.refreshKnowledgeIndex()
            await store.refreshAIStatus()
            statusMessage = String(format: L10n.text("management.refreshIndexDone", store.language), result.documentCount)
            statusIsError = false
        } catch {
            reportError("management.refreshIndexFailed")
        }
    }

    @MainActor
    private func checkSources() async {
        isCheckingSources = true
        defer { isCheckingSources = false }
        guard await backendSupervisor.ensureRunning() else {
            reportError("management.checkSourcesFailed")
            return
        }
        do {
            let result = try await OrchestratorClient.checkTrustedSourceReferences()
            sourceInventory = try await OrchestratorClient.trustedSourceInventory()
            statusMessage = String(
                format: L10n.text("management.checkSourcesDone", store.language),
                result.checkedCount,
                result.changedCount,
                result.needsAttentionCount
            )
            statusIsError = result.needsAttentionCount > 0
        } catch {
            reportError("management.checkSourcesFailed")
        }
    }

    @MainActor
    private func searchRAG() async {
        let query = ragQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearchingRAG = true
        defer { isSearchingRAG = false }
        guard await backendSupervisor.ensureRunning() else {
            reportError("management.ragSearchFailed")
            return
        }
        do {
            ragSearchResult = try await OrchestratorClient.searchKnowledgeRAG(
                query: query,
                includeObsidian: includeObsidianRAG
            )
            statusMessage = nil
            statusIsError = false
        } catch {
            reportError("management.ragSearchFailed")
        }
    }

    @MainActor
    private func reportError(_ key: String) {
        statusMessage = L10n.text(key, store.language)
        statusIsError = true
    }

    @MainActor
    private func syncSubjectModelRouteForm() {
        let route = store.subjectModelRoutes[routeSubject.rawValue]
        routeProvider = route?.provider ?? "auto"
        routeModel = route?.model ?? ""
    }

    @MainActor
    private func syncFinalSynthesisRouteForm() {
        let route = store.finalSynthesisModelRoute
        finalSynthesisProvider = route?.provider ?? "auto"
        finalSynthesisModel = route?.model ?? ""
    }

    @MainActor
    private func syncAutoAgentModelForm() {
        let route = store.autoAgentModelRoutes[autoAgentRole]
        autoAgentProvider = route?.provider ?? "auto"
        autoAgentModel = route?.model ?? ""
    }

    @MainActor
    private func syncAutoCostPolicyForm() {
        allowsPaidAutoRoutes = store.autoCostPolicy?.allowPaidRoutes ?? false
    }

    @MainActor
    private func saveSubjectModelRoute() async {
        isSavingRoute = true
        defer { isSavingRoute = false }
        do {
            let model = routeModel.trimmingCharacters(in: .whitespacesAndNewlines)
            try await store.saveSubjectModelRoute(
                subject: routeSubject,
                provider: routeProvider,
                model: routeProvider == "auto" || model.isEmpty ? nil : model
            )
            syncSubjectModelRouteForm()
            statusMessage = L10n.text("management.routeSaved", store.language)
            statusIsError = false
        } catch {
            reportError("management.routeSaveFailed")
        }
    }

    @MainActor
    private func resetSubjectModelRoute() async {
        isSavingRoute = true
        defer { isSavingRoute = false }
        do {
            try await store.resetSubjectModelRoute(subject: routeSubject)
            syncSubjectModelRouteForm()
            statusMessage = L10n.text("management.routeResetDone", store.language)
            statusIsError = false
        } catch {
            reportError("management.routeSaveFailed")
        }
    }

    @MainActor
    private func saveAutoAgentModel() async {
        isSavingRoute = true
        defer { isSavingRoute = false }
        do {
            let model = autoAgentModel.trimmingCharacters(in: .whitespacesAndNewlines)
            try await store.saveAutoAgentModelRoute(
                role: autoAgentRole,
                provider: autoAgentProvider,
                model: autoAgentProvider == "auto" || model.isEmpty ? nil : model
            )
            syncAutoAgentModelForm()
            statusMessage = L10n.text("management.routeSaved", store.language)
            statusIsError = false
        } catch {
            reportError("management.routeSaveFailed")
        }
    }

    @MainActor
    private func resetAutoAgentModel() async {
        isSavingRoute = true
        defer { isSavingRoute = false }
        do {
            try await store.resetAutoAgentModelRoute(role: autoAgentRole)
            syncAutoAgentModelForm()
            statusMessage = L10n.text("management.routeResetDone", store.language)
            statusIsError = false
        } catch {
            reportError("management.routeSaveFailed")
        }
    }

    @MainActor
    private func saveFinalSynthesisRoute() async {
        isSavingRoute = true
        defer { isSavingRoute = false }
        do {
            let model = finalSynthesisModel.trimmingCharacters(in: .whitespacesAndNewlines)
            try await store.saveFinalSynthesisModelRoute(
                provider: finalSynthesisProvider,
                model: finalSynthesisProvider == "auto" || model.isEmpty ? nil : model
            )
            syncFinalSynthesisRouteForm()
            statusMessage = L10n.text("management.routeSaved", store.language)
            statusIsError = false
        } catch {
            reportError("management.routeSaveFailed")
        }
    }

    @MainActor
    private func resetFinalSynthesisRoute() async {
        isSavingRoute = true
        defer { isSavingRoute = false }
        do {
            try await store.resetFinalSynthesisModelRoute()
            syncFinalSynthesisRouteForm()
            statusMessage = L10n.text("management.routeResetDone", store.language)
            statusIsError = false
        } catch {
            reportError("management.routeSaveFailed")
        }
    }

    @MainActor
    private func saveAutoCostPolicy() async {
        isSavingCostPolicy = true
        defer { isSavingCostPolicy = false }
        do {
            try await store.saveAutoCostPolicy(allowPaidRoutes: allowsPaidAutoRoutes)
            await store.refreshFinalSynthesisModelRoute()
            statusMessage = L10n.text("management.costPolicySaved", store.language)
            statusIsError = false
        } catch {
            reportError("management.costPolicySaveFailed")
        }
    }

    @MainActor
    private func saveCompatibleSettings() async {
        isSavingCompatibleSettings = true
        defer { isSavingCompatibleSettings = false }
        guard await backendSupervisor.ensureRunning() else {
            reportError("management.compatibleSaveFailed")
            return
        }
        do {
            try await store.saveOpenAICompatibleSettings(
                baseURL: compatibleBaseURL,
                model: compatibleModel
            )
            compatibleBaseURL = store.openAICompatibleSettings?.baseURL ?? ""
            compatibleModel = store.openAICompatibleSettings?.model ?? ""
            await store.refreshProviderSecretStatuses()
            statusMessage = L10n.text("management.compatibleSaved", store.language)
            statusIsError = false
        } catch {
            reportError("management.compatibleSaveFailed")
        }
    }
}

private enum SourceRegistrySheet: Identifiable {
    case preview(TrustedSourcePagePreview)
    case history(String)

    var id: String {
        switch self {
        case .preview(let preview): return "preview:\(preview.id)"
        case .history(let url): return "history:\(url)"
        }
    }
}

private struct SourceRegistryRow: View {
    let source: TrustedSourceInventoryItem
    let language: AppLanguage
    let onReviewSaved: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(source.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(source.lessonPaths?.joined(separator: " · ") ?? source.lessonPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 8)
                Label(L10n.text(statusKey, language), systemImage: statusSymbol)
                    .font(.caption)
                    .foregroundStyle(statusTint)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if let url = URL(string: source.url) {
                    Button {
                        Task { await loadPreview() }
                    } label: {
                        if isLoadingPreview {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "doc.text.magnifyingglass")
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoadingPreview)
                    .help(L10n.text("management.sourcePreview", language))
                    .accessibilityLabel(
                        L10n.text(
                            isLoadingPreview ? "management.sourcePreviewLoading" : "management.sourcePreview",
                            language
                        )
                    )

                    Button {
                        activeSheet = .history(source.url)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .buttonStyle(.plain)
                    .help(L10n.text("management.sourceReviewHistory", language))
                    .accessibilityLabel(L10n.text("management.sourceReviewHistory", language))

                    Link(destination: url) {
                        Image(systemName: "arrow.up.right.square")
                    }
                    .buttonStyle(.plain)
                    .help(source.url)
                    .accessibilityLabel(source.title)
                }
            }
            Text(source.url)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            if let pageTitle = source.pageTitle {
                LabeledContent(L10n.text("management.sourcePageTitle", language), value: pageTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let pageDescription = source.pageDescription {
                Text(pageDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }

            if let ragContentState = source.ragContentState {
                HStack(spacing: 8) {
                    Label(
                        L10n.text(
                            ragContentState == "cached"
                                ? "management.sourceRAGCached"
                                : ragContentState == "license_approved_pending_check"
                                    ? "management.sourceRAGPending"
                                    : ragContentState == "metadata_only_noncommercial"
                                        ? "management.sourceRAGNonCommercial"
                                        : "management.sourceRAGMetadataOnly",
                            language
                        ),
                        systemImage: ragContentState == "cached" ? "doc.text.magnifyingglass" : "doc.text"
                    )
                    if let license = source.ragLicense {
                        Text(license)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        if let licenseURL = source.ragLicenseURL,
                           let destination = URL(string: licenseURL) {
                            Link(destination: destination) {
                                Image(systemName: "arrow.up.right.square")
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(licenseURL)
                        }
                    }
                    if ragContentState == "metadata_only_noncommercial",
                       let licenseURL = source.ragRestrictionURL,
                       let destination = URL(string: licenseURL) {
                        Link(L10n.text("management.sourceLicenseTerms", language), destination: destination)
                            .buttonStyle(.plain)
                    }
                    if let fetchedAt = source.ragContentFetchedAt {
                        Text("\(L10n.text("management.sourceRAGFetched", language)): \(formatISODate(fetchedAt))")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            if let reviewStatus = source.editorialReviewStatus {
                HStack(spacing: 12) {
                    Label(
                        L10n.text(editorialReviewKey(reviewStatus), language),
                        systemImage: editorialReviewSymbol(reviewStatus)
                    )
                    .foregroundStyle(editorialReviewTint(reviewStatus))
                    if let dueOn = source.editorialReviewDueOn {
                        Text(L10n.text("management.editorialReviewDueOn", language) + ": " + dueOn)
                    }
                    if (source.lessonReviews?.count ?? 1) <= 1,
                       let interval = source.editorialReviewIntervalDays {
                        Text(L10n.text("management.editorialReviewInterval", language) + ": \(interval)")
                    }
                }
                .font(.caption2)
            }

            if let lessonReviews = source.lessonReviews, lessonReviews.count > 1 {
                ForEach(lessonReviews) { review in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(review.lessonPath)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer(minLength: 4)
                            Label(
                                L10n.text(editorialReviewKey(review.editorialReviewStatus), language),
                                systemImage: editorialReviewSymbol(review.editorialReviewStatus)
                            )
                            .foregroundStyle(editorialReviewTint(review.editorialReviewStatus))
                        }
                        HStack(spacing: 10) {
                            Text(
                                L10n.text("management.lessonReviewed", language) + ": "
                                    + (review.lessonReviewedOn ?? L10n.text("management.unknownDate", language))
                            )
                            if let dueOn = review.editorialReviewDueOn {
                                Text(L10n.text("management.editorialReviewDueOn", language) + ": " + dueOn)
                            }
                            if let interval = review.editorialReviewIntervalDays {
                                Text(L10n.text("management.editorialReviewInterval", language) + ": \(interval)")
                            }
                        }
                        .foregroundStyle(.tertiary)
                    }
                    .font(.caption2)
                }
            }

            HStack(spacing: 12) {
                if (source.lessonReviews?.count ?? 1) <= 1 {
                    Text(
                        L10n.text("management.lessonReviewed", language) + ": "
                            + (source.lessonReviewedOn ?? L10n.text("management.unknownDate", language))
                    )
                }
                if let lastCheckedAt = source.lastCheckedAt {
                    Text("\(L10n.text("management.sourceChecked", language)): \(formatISODate(lastCheckedAt))")
                }
                if let contentCheckedAt = source.contentCheckedAt {
                    Text("\(L10n.text("management.sourceContentChecked", language)): \(formatISODate(contentCheckedAt))")
                }
                if let lastModified = source.lastModified {
                    Text("\(L10n.text("management.sourceModified", language)): \(lastModified)")
                }
                if let lastHTTPStatus = source.lastHTTPStatus {
                    Text("HTTP \(lastHTTPStatus)")
                }
                if source.hasETag {
                    Text("ETag")
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .textSelection(.enabled)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .contain)
        .sheet(item: $activeSheet) { item in
            switch item {
            case .preview(let preview):
                TrustedSourcePreviewSheet(
                    preview: preview,
                    language: language,
                    onReviewSaved: onReviewSaved
                )
            case .history(let url):
                TrustedSourceReviewHistorySheet(url: url, language: language)
            }
        }
        .alert(
            L10n.text("management.sourcePreviewTitle", language),
            isPresented: $showPreviewError
        ) {
            Button(L10n.text("management.sourcePreviewDone", language), role: .cancel) { }
        } message: {
            Text(L10n.text("management.sourcePreviewFailed", language))
        }
    }

    @MainActor
    private func loadPreview() async {
        isLoadingPreview = true
        defer { isLoadingPreview = false }
        do {
            activeSheet = .preview(try await OrchestratorClient.previewTrustedSource(url: source.url))
        } catch {
            showPreviewError = true
        }
    }

    @State private var isLoadingPreview = false
    @State private var activeSheet: SourceRegistrySheet?
    @State private var showPreviewError = false

    private var statusKey: String {
        switch source.state {
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

    private var statusSymbol: String {
        switch source.state {
        case "changed", "content_baseline", "content_unavailable", "content_too_large",
             "unsupported_content_type", "redirect_review", "unexpected_not_modified",
             "unavailable", "network_error":
            return "exclamationmark.triangle.fill"
        case "unchanged": return "checkmark.circle"
        case "available_untracked": return "questionmark.circle"
        default: return "clock"
        }
    }

    private var statusTint: Color {
        switch source.state {
        case "changed", "content_baseline", "content_unavailable", "content_too_large",
             "unsupported_content_type", "redirect_review", "unexpected_not_modified",
             "unavailable", "network_error": return .orange
        default: return .secondary
        }
    }

    private func editorialReviewKey(_ status: String) -> String {
        switch status {
        case "review_due": return "management.editorialReviewDue"
        case "review_scheduled": return "management.editorialReviewScheduled"
        case "review_missing": return "management.editorialReviewMissing"
        case "review_unscheduled": return "management.editorialReviewUnscheduled"
        default: return "management.editorialReviewUnknown"
        }
    }

    private func editorialReviewSymbol(_ status: String) -> String {
        switch status {
        case "review_due", "review_missing": return "exclamationmark.circle.fill"
        case "review_scheduled": return "calendar"
        case "review_unscheduled": return "calendar.badge.exclamationmark"
        default: return "questionmark.circle"
        }
    }

    private func editorialReviewTint(_ status: String) -> Color {
        switch status {
        case "review_due", "review_missing": return .orange
        default: return .secondary
        }
    }

    private func formatISODate(_ value: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: value) else { return value }
        return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
    }
}

private struct TrustedSourceReviewHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let url: String
    let language: AppLanguage

    @State private var reviews: [TrustedSourceEditorialReview] = []
    @State private var nextBeforeReviewID: Int?
    @State private var hasMore = false
    @State private var isLoading = false
    @State private var loadFailed = false

    var body: some View {
        NavigationStack {
            Group {
                if reviews.isEmpty && isLoading {
                    ProgressView(L10n.text("management.sourceReviewHistoryLoading", language))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reviews.isEmpty && loadFailed {
                    VStack(spacing: 12) {
                        Label(
                            L10n.text("management.sourceReviewHistoryFailed", language),
                            systemImage: "exclamationmark.triangle"
                        )
                        Button(L10n.text("management.retry", language)) {
                            Task { await loadNextPage() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reviews.isEmpty {
                    VStack(spacing: 12) {
                        Label(
                            L10n.text("management.sourceReviewHistoryEmpty", language),
                            systemImage: "clock"
                        )
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(url)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                            ForEach(reviews) { review in
                                GroupBox {
                                    VStack(alignment: .leading, spacing: 7) {
                                        HStack {
                                            Label(review.reviewedOn, systemImage: "checkmark.seal")
                                            Spacer()
                                            Text("#\(review.reviewID)")
                                                .foregroundStyle(.tertiary)
                                        }
                                        Text(review.lessonPath)
                                            .font(.caption.monospaced())
                                            .textSelection(.enabled)
                                        Text(
                                            "SHA-256 " + String(review.reviewedDigest.prefix(12)) + "…"
                                        )
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                        Text(formatReviewedAt(review.reviewedAt))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else if loadFailed {
                                Label(
                                    L10n.text("management.sourceReviewHistoryFailed", language),
                                    systemImage: "exclamationmark.triangle"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                Button(L10n.text("management.retry", language)) {
                                    Task { await loadNextPage() }
                                }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                            } else if hasMore {
                                Button(L10n.text("management.sourceReviewHistoryMore", language)) {
                                    Task { await loadNextPage() }
                                }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(L10n.text("management.sourceReviewHistoryTitle", language))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("management.sourcePreviewDone", language)) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            guard reviews.isEmpty else { return }
            await loadNextPage()
        }
        .frame(minWidth: 540, minHeight: 420)
    }

    @MainActor
    private func loadNextPage() async {
        guard !isLoading else { return }
        isLoading = true
        loadFailed = false
        defer { isLoading = false }
        do {
            let page = try await OrchestratorClient.trustedSourceReviewHistory(
                url: url,
                beforeReviewID: nextBeforeReviewID
            )
            reviews.append(contentsOf: page.reviews)
            hasMore = page.hasMore
            nextBeforeReviewID = page.nextBeforeReviewID
        } catch {
            loadFailed = true
        }
    }

    private func formatReviewedAt(_ value: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: value) else { return value }
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }
}

private struct TrustedSourcePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let preview: TrustedSourcePagePreview
    let language: AppLanguage
    let onReviewSaved: () -> Void
    @State private var selectedLessonPath: String?
    @State private var isSavingReview = false
    @State private var reviewedLessonPaths: Set<String> = []
    @State private var showReviewError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(preview.title)
                        .font(.headline)
                    if let pageTitle = preview.pageTitle, !pageTitle.isEmpty {
                        Text(pageTitle)
                            .font(.title2.weight(.semibold))
                    }
                    if let description = preview.pageDescription, !description.isEmpty {
                        Text(description)
                            .foregroundStyle(.secondary)
                    }
                    if preview.excerptTruncated {
                        Label(
                            L10n.text("management.sourcePreviewTruncated", language),
                            systemImage: "info.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Text(verbatim: preview.excerpt)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            if preview.lessonPaths.count > 1 {
                                Picker(
                                    L10n.text("management.sourceReviewLesson", language),
                                    selection: $selectedLessonPath
                                ) {
                                    ForEach(preview.lessonPaths, id: \.self) { path in
                                        Text(path).tag(Optional(path))
                                    }
                                }
                            } else if let lessonPath = preview.lessonPaths.first {
                                Text(lessonPath)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                            }

                            Text(L10n.text("management.sourceReviewExplanation", language))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if selectedLessonAlreadyReviewed {
                                Label(
                                    L10n.text("management.sourceReviewSaved", language),
                                    systemImage: "checkmark.circle.fill"
                                )
                                .foregroundStyle(.green)
                            }

                            Button {
                                Task { await recordReview() }
                            } label: {
                                if isSavingReview {
                                    ProgressView().controlSize(.small)
                                    Text(L10n.text("management.sourceReviewSaving", language))
                                } else {
                                    Label(
                                        L10n.text("management.sourceReviewAction", language),
                                        systemImage: "checkmark.seal"
                                    )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSavingReview || selectedLessonPath == nil || selectedLessonAlreadyReviewed)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider()
                    Text(L10n.text("management.sourcePreviewLessons", language))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(preview.lessonPaths.joined(separator: "\n"))
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                    HStack {
                        Text(L10n.text("management.sourcePreviewFetched", language))
                        Text(preview.fetchedAt).monospacedDigit()
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    if let url = URL(string: preview.url) {
                        Link(preview.url, destination: url)
                            .font(.caption)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(L10n.text("management.sourcePreviewTitle", language))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("management.sourcePreviewDone", language)) {
                        dismiss()
                    }
                }
            }
            .frame(minWidth: 540, minHeight: 420)
            .task {
                if selectedLessonPath == nil {
                    selectedLessonPath = preview.lessonPaths.first
                }
            }
            .alert(
                L10n.text("management.sourceReviewAction", language),
                isPresented: $showReviewError
            ) {
                Button(L10n.text("management.sourcePreviewDone", language), role: .cancel) { }
            } message: {
                Text(L10n.text("management.sourceReviewFailed", language))
            }
        }
    }

    @MainActor
    private func recordReview() async {
        guard let selectedLessonPath else { return }
        isSavingReview = true
        defer { isSavingReview = false }
        do {
            try await OrchestratorClient.recordTrustedSourceReview(
                url: preview.url,
                lessonPath: selectedLessonPath,
                previewDigest: preview.contentDigest
            )
            reviewedLessonPaths.insert(selectedLessonPath)
            onReviewSaved()
        } catch {
            showReviewError = true
        }
    }

    private var selectedLessonAlreadyReviewed: Bool {
        guard let selectedLessonPath else { return false }
        return reviewedLessonPaths.contains(selectedLessonPath)
    }
}
