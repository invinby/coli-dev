import SwiftUI
import Foundation
import AppKit

// The first client slice uses a small explicit course catalog; the tutor talks to the local orchestrator.
enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case ru
    case en

    var id: String { rawValue }
    var shortLabel: String { rawValue.uppercased() }
}

enum Subject: String, CaseIterable, Identifiable, Hashable {
    case mathematics
    case english
    case physics
    case biology
    case zoology
    case programming

    var id: String { rawValue }
    var lessonID: String { "intro.\(rawValue)" }

    func title(in language: AppLanguage) -> String {
        L10n.text("subject.\(rawValue)", language)
    }

    func subtitle(in language: AppLanguage) -> String {
        L10n.text("subject.\(rawValue).subtitle", language)
    }

    var symbol: String {
        switch self {
        case .mathematics: return "function"
        case .english: return "text.book.closed.fill"
        case .physics: return "atom"
        case .biology: return "leaf.fill"
        case .zoology: return "pawprint.fill"
        case .programming: return "chevron.left.forwardslash.chevron.right"
        }
    }

    var tint: Color {
        switch self {
        case .mathematics: return .indigo
        case .english: return .orange
        case .physics: return .blue
        case .biology: return .green
        case .zoology: return .brown
        case .programming: return .purple
        }
    }
}

struct LessonContent {
    let title: String
    let objective: String
    let explanation: String
    let mechanism: String
    let example: String
    let limitations: String
    let question: String
    let options: [String]
    let answerIndex: Int
    let feedback: String
}

enum LearningCatalog {
    static func lesson(for subject: Subject, language: AppLanguage) -> LessonContent {
        let key = "lesson.\(subject.rawValue)"
        return LessonContent(
            title: L10n.text("\(key).title", language),
            objective: L10n.text("\(key).objective", language),
            explanation: L10n.text("\(key).explanation", language),
            mechanism: L10n.text("\(key).mechanism", language),
            example: L10n.text("\(key).example", language),
            limitations: L10n.text("\(key).limitations", language),
            question: L10n.text("\(key).question", language),
            options: (0..<3).map { L10n.text("\(key).option\($0)", language) },
            answerIndex: Int(L10n.text("\(key).answer", language)) ?? 0,
            feedback: L10n.text("\(key).feedback", language)
        )
    }
}

struct StudyReviewEvent: Codable, Identifiable {
    let id: String
    let lessonID: String
    let quality: Int
    let reflection: String?
    let completeLesson: Bool?

    var eventID: String { id }

    enum CodingKeys: String, CodingKey {
        case id = "event_id"
        case lessonID = "lesson_id"
        case quality
        case reflection
        case completeLesson = "complete_lesson"
    }
}

struct StudyProgressRecord: Decodable, Identifiable {
    let lessonID: String
    let completed: Bool
    let repetitions: Int
    let intervalDays: Int
    let easeFactor: Double
    let reviewCount: Int
    let dueAt: String?
    let lastReviewedAt: String?
    let reflection: String?
    let updatedAt: String

    var id: String { lessonID }
    var dueDate: Date? {
        guard let dueAt else { return nil }
        return ISO8601DateFormatter().date(from: dueAt)
    }

    enum CodingKeys: String, CodingKey {
        case lessonID = "lesson_id"
        case completed, repetitions
        case intervalDays = "interval_days"
        case easeFactor = "ease_factor"
        case reviewCount = "review_count"
        case dueAt = "due_at"
        case lastReviewedAt = "last_reviewed_at"
        case reflection
        case updatedAt = "updated_at"
    }
}

struct StudyProgressSnapshot: Decodable {
    let records: [StudyProgressRecord]
    let dueCount: Int
    let nextDueAt: String?
    let generatedAt: String

    enum CodingKeys: String, CodingKey {
        case records
        case dueCount = "due_count"
        case nextDueAt = "next_due_at"
        case generatedAt = "generated_at"
    }
}

struct ProgressBackupRestoreSummary: Decodable {
    let restored: Int
    let unchanged: Int
}

@MainActor
final class LearningStore: ObservableObject {
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "colidev.language") }
    }
    @Published private(set) var completedLessonIDs: Set<String> {
        didSet { UserDefaults.standard.set(Array(completedLessonIDs), forKey: "colidev.completedLessons") }
    }
    @Published private(set) var lastOpenedCourseRoute: StudyLessonRoute? {
        didSet {
            guard let lastOpenedCourseRoute,
                  let data = try? JSONEncoder().encode(lastOpenedCourseRoute) else {
                UserDefaults.standard.removeObject(forKey: "colidev.lastOpenedCourseRoute")
                return
            }
            UserDefaults.standard.set(data, forKey: "colidev.lastOpenedCourseRoute")
        }
    }
    @Published private(set) var aiHealth: OrchestratorHealth?
    @Published private(set) var isCheckingAI = false
    @Published private(set) var providerSecretStatuses: [String: ProviderSecretStatus] = [:]
    @Published private(set) var openAICompatibleSettings: OpenAICompatibleSettings?
    @Published private(set) var subjectModelRoutes: [String: SubjectModelRoute] = [:]
    @Published private(set) var autoAgentModelRoutes: [String: AutoAgentModelRoute] = [:]
    @Published private(set) var localOllamaModelCatalog = LocalOllamaModelCatalog.notChecked
    @Published private(set) var isRefreshingLocalOllamaModelCatalog = false
    @Published private(set) var finalSynthesisModelRoute: FinalSynthesisModelRoute?
    @Published private(set) var autoCostPolicy: AutoCostPolicy?
    @Published private(set) var providerUsage: ProviderUsageSummary?
    @Published private(set) var isRefreshingProviderUsage = false
    @Published private(set) var providerUsageUnavailable = false
    @Published private(set) var studyProgress: [String: StudyProgressRecord] = [:]
    @Published private(set) var dueReviewCount = 0
    @Published private(set) var customCurriculum: CustomCurriculum {
        didSet {
            guard let data = try? JSONEncoder().encode(customCurriculum) else { return }
            UserDefaults.standard.set(data, forKey: "colidev.customCurriculum")
        }
    }
    @Published private var pendingStudyReviews: [StudyReviewEvent] {
        didSet {
            guard let data = try? JSONEncoder().encode(pendingStudyReviews) else { return }
            UserDefaults.standard.set(data, forKey: "colidev.pendingStudyReviews")
        }
    }
    private var isSyncingStudyProgress = false
    private var studyProgressSyncRequested = false
    @Published var aiMode: AIRoutingMode {
        didSet { UserDefaults.standard.set(aiMode.rawValue, forKey: "colidev.aiMode") }
    }

    static let orchestratorBaseURL = "http://127.0.0.1:8000"

    init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "colidev.language")
        language = AppLanguage(rawValue: savedLanguage ?? "") ?? .ru
        completedLessonIDs = Set(UserDefaults.standard.stringArray(forKey: "colidev.completedLessons") ?? [])
        if let data = UserDefaults.standard.data(forKey: "colidev.lastOpenedCourseRoute"),
           let savedRoute = try? JSONDecoder().decode(StudyLessonRoute.self, from: data) {
            lastOpenedCourseRoute = savedRoute
        } else {
            lastOpenedCourseRoute = nil
        }
        if let data = UserDefaults.standard.data(forKey: "colidev.customCurriculum"),
           let savedCurriculum = try? JSONDecoder().decode(CustomCurriculum.self, from: data) {
            customCurriculum = savedCurriculum
        } else {
            customCurriculum = CustomCurriculum()
        }
        let savedMode = UserDefaults.standard.string(forKey: "colidev.aiMode")
        aiMode = AIRoutingMode(rawValue: savedMode ?? "") ?? .automatic
        if let pending = UserDefaults.standard.data(forKey: "colidev.pendingStudyReviews"),
           let events = try? JSONDecoder().decode([StudyReviewEvent].self, from: pending) {
            pendingStudyReviews = events
        } else {
            pendingStudyReviews = []
        }
    }

    func refreshAIStatus() async {
        isCheckingAI = true
        defer { isCheckingAI = false }
        do {
            aiHealth = try await OrchestratorClient.health()
        } catch {
            aiHealth = nil
        }
    }

    func refreshProviderSecretStatuses() async {
        do {
            let statuses = try await OrchestratorClient.providerSecretStatuses()
            providerSecretStatuses = Dictionary(uniqueKeysWithValues: statuses.map { ($0.provider, $0) })
        } catch {
            providerSecretStatuses = [:]
        }
    }

    func refreshOpenAICompatibleSettings() async {
        do {
            openAICompatibleSettings = try await OrchestratorClient.openAICompatibleSettings()
        } catch {
            openAICompatibleSettings = nil
        }
    }

    func saveOpenAICompatibleSettings(baseURL: String, model: String) async throws {
        openAICompatibleSettings = try await OrchestratorClient.saveOpenAICompatibleSettings(
            baseURL: baseURL,
            model: model
        )
        await refreshSubjectModelRoutes()
        await refreshFinalSynthesisModelRoute()
    }

    func refreshSubjectModelRoutes() async {
        do {
            let routes = try await OrchestratorClient.subjectModelRoutes()
            subjectModelRoutes = Dictionary(uniqueKeysWithValues: routes.map { ($0.subject, $0) })
        } catch {
            subjectModelRoutes = [:]
        }
    }

    func saveSubjectModelRoute(subject: Subject, provider: String, model: String?) async throws {
        let route = try await OrchestratorClient.saveSubjectModelRoute(
            subject: subject,
            provider: provider,
            model: model
        )
        subjectModelRoutes[route.subject] = route
    }

    func resetSubjectModelRoute(subject: Subject) async throws {
        let route = try await OrchestratorClient.resetSubjectModelRoute(subject: subject)
        subjectModelRoutes[route.subject] = route
    }

    func refreshAutoAgentModelRoutes() async {
        do {
            let routes = try await OrchestratorClient.autoAgentModelRoutes()
            autoAgentModelRoutes = Dictionary(uniqueKeysWithValues: routes.map { ($0.role, $0) })
        } catch {
            autoAgentModelRoutes = [:]
        }
    }

    func refreshLocalOllamaModelCatalog() async {
        guard !isRefreshingLocalOllamaModelCatalog else { return }
        isRefreshingLocalOllamaModelCatalog = true
        defer { isRefreshingLocalOllamaModelCatalog = false }
        do {
            localOllamaModelCatalog = try await OrchestratorClient.localOllamaModelCatalog()
        } catch {
            localOllamaModelCatalog = .unavailable
        }
    }

    func saveAutoAgentModelRoute(role: String, provider: String, model: String?) async throws {
        let route = try await OrchestratorClient.saveAutoAgentModelRoute(
            role: role, provider: provider, model: model
        )
        autoAgentModelRoutes[route.role] = route
    }

    func resetAutoAgentModelRoute(role: String) async throws {
        let route = try await OrchestratorClient.resetAutoAgentModelRoute(role: role)
        autoAgentModelRoutes[route.role] = route
    }

    func refreshFinalSynthesisModelRoute() async {
        do {
            finalSynthesisModelRoute = try await OrchestratorClient.finalSynthesisModelRoute()
        } catch {
            finalSynthesisModelRoute = nil
        }
    }

    func saveFinalSynthesisModelRoute(provider: String, model: String?) async throws {
        finalSynthesisModelRoute = try await OrchestratorClient.saveFinalSynthesisModelRoute(
            provider: provider,
            model: model
        )
    }

    func resetFinalSynthesisModelRoute() async throws {
        finalSynthesisModelRoute = try await OrchestratorClient.resetFinalSynthesisModelRoute()
    }

    func refreshAutoCostPolicy() async {
        do {
            autoCostPolicy = try await OrchestratorClient.autoCostPolicy()
        } catch {
            autoCostPolicy = nil
        }
    }

    func saveAutoCostPolicy(allowPaidRoutes: Bool) async throws {
        autoCostPolicy = try await OrchestratorClient.saveAutoCostPolicy(
            allowPaidRoutes: allowPaidRoutes
        )
    }

    func refreshProviderUsage() async {
        isRefreshingProviderUsage = true
        defer { isRefreshingProviderUsage = false }
        do {
            providerUsage = try await OrchestratorClient.providerUsage(language: language)
            providerUsageUnavailable = false
        } catch {
            providerUsageUnavailable = true
        }
    }

    func saveProviderSecret(_ apiKey: String, for provider: String) async throws {
        let status = try await OrchestratorClient.saveProviderSecret(apiKey, for: provider)
        providerSecretStatuses[provider] = status
        await refreshAIStatus()
        if provider == "compatible" {
            await refreshOpenAICompatibleSettings()
            await refreshSubjectModelRoutes()
            await refreshFinalSynthesisModelRoute()
        }
    }

    func deleteProviderSecret(for provider: String) async throws {
        let status = try await OrchestratorClient.deleteProviderSecret(for: provider)
        providerSecretStatuses[provider] = status
        await refreshAIStatus()
        if provider == "compatible" {
            await refreshOpenAICompatibleSettings()
            await refreshSubjectModelRoutes()
            await refreshFinalSynthesisModelRoute()
        }
    }

    func isComplete(_ subject: Subject) -> Bool {
        isComplete(lessonID: subject.lessonID)
    }

    func isComplete(lessonID: String) -> Bool {
        completedLessonIDs.contains(lessonID)
    }

    func rememberCourseLesson(subject: Subject, resource: String) {
        lastOpenedCourseRoute = StudyLessonRoute(subjectID: subject.rawValue, resource: resource)
    }

    func markComplete(_ subject: Subject, reflection: String = "") {
        markComplete(lessonID: subject.lessonID, quality: 4, reflection: reflection)
    }

    func markComplete(lessonID: String, quality: Int, reflection: String = "") {
        completedLessonIDs.insert(lessonID)
        queueStudyReview(
            lessonID: lessonID,
            quality: quality,
            reflection: reflection,
            completeLesson: true
        )
    }

    func recordReview(for subject: Subject, reflection: String = "") {
        recordReview(lessonID: subject.lessonID, quality: 4, reflection: reflection)
    }

    func recordReview(lessonID: String, quality: Int, reflection: String = "") {
        queueStudyReview(
            lessonID: lessonID,
            quality: quality,
            reflection: reflection,
            completeLesson: false
        )
    }

    func isReviewDue(_ subject: Subject) -> Bool {
        isReviewDue(lessonID: subject.lessonID)
    }

    func isReviewDue(lessonID: String) -> Bool {
        guard let dueDate = studyProgress[lessonID]?.dueDate else { return false }
        return dueDate <= Date()
    }

    func hasPendingReview(_ subject: Subject) -> Bool {
        hasPendingReview(lessonID: subject.lessonID)
    }

    func hasPendingReview(lessonID: String) -> Bool {
        pendingStudyReviews.contains(where: { $0.lessonID == lessonID })
    }

    var nextDueLessonID: String? {
        let dueRecord = studyProgress.values
            .filter { ($0.dueDate ?? .distantFuture) <= Date() }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first
        return dueRecord?.lessonID
    }

    var nextDueSubject: Subject? {
        guard let lessonID = nextDueLessonID else { return nil }
        let subjectID = lessonID.hasPrefix("intro.")
            ? String(lessonID.dropFirst("intro.".count))
            : String(lessonID.split(separator: ".", maxSplits: 1).first ?? "")
        return Subject(rawValue: subjectID)
    }

    func syncStudyProgress() async {
        guard !isSyncingStudyProgress else {
            studyProgressSyncRequested = true
            return
        }
        isSyncingStudyProgress = true
        defer {
            isSyncingStudyProgress = false
            if studyProgressSyncRequested {
                studyProgressSyncRequested = false
                Task { await syncStudyProgress() }
            }
        }

        while let event = pendingStudyReviews.first {
            do {
                let record = try await OrchestratorClient.recordStudyReview(event)
                studyProgress[event.lessonID] = record
                if record.completed { completedLessonIDs.insert(event.lessonID) }
                pendingStudyReviews.removeAll(where: { $0.id == event.id })
            } catch {
                return
            }
        }

        do {
            let snapshot = try await OrchestratorClient.studyProgress()
            studyProgress = Dictionary(uniqueKeysWithValues: snapshot.records.map { ($0.lessonID, $0) })
            dueReviewCount = snapshot.records.filter { record in
                (record.dueDate ?? .distantFuture) <= Date()
            }.count
            for record in snapshot.records where record.completed {
                completedLessonIDs.insert(record.lessonID)
            }
        } catch {
            // Keep the local lesson state and queued review events while the backend is offline.
        }
    }

    var pendingStudyReviewCount: Int { pendingStudyReviews.count }

    @discardableResult
    func addCustomSubject(name: CustomCurriculumText, description: CustomCurriculumText) throws -> UUID {
        var updated = customCurriculum
        let reservedNames = Subject.allCases.map { subject in
            CustomCurriculumText(
                russian: subject.title(in: .ru),
                english: subject.title(in: .en)
            )
        }
        let id = try updated.addSubject(name: name, description: description, reservedNames: reservedNames)
        customCurriculum = updated
        return id
    }

    @discardableResult
    func addCustomTopic(
        subjectID: UUID,
        parentTopicID: UUID?,
        name: CustomCurriculumText,
        learningOutcome: CustomCurriculumText,
        notes: CustomCurriculumText,
        level: Int
    ) throws -> UUID {
        var updated = customCurriculum
        let id = try updated.addTopic(
            subjectID: subjectID,
            parentTopicID: parentTopicID,
            name: name,
            learningOutcome: learningOutcome,
            notes: notes,
            level: level
        )
        customCurriculum = updated
        return id
    }

    @discardableResult
    func addCustomTopic(
        builtInSubject: Subject,
        parentTopicID: UUID?,
        name: CustomCurriculumText,
        learningOutcome: CustomCurriculumText,
        notes: CustomCurriculumText,
        level: Int
    ) throws -> UUID {
        var updated = customCurriculum
        let id = try updated.addTopic(
            builtInSubjectID: builtInSubject.rawValue,
            parentTopicID: parentTopicID,
            name: name,
            learningOutcome: learningOutcome,
            notes: notes,
            level: level
        )
        customCurriculum = updated
        return id
    }

    func removeCustomSubject(id: UUID) {
        var updated = customCurriculum
        guard updated.removeSubject(id: id) else { return }
        customCurriculum = updated
    }

    func removeCustomTopic(subjectID: UUID, topicID: UUID) {
        var updated = customCurriculum
        guard updated.removeTopic(subjectID: subjectID, topicID: topicID) else { return }
        customCurriculum = updated
    }

    func removeCustomTopic(builtInSubject: Subject, topicID: UUID) {
        var updated = customCurriculum
        guard updated.removeTopic(builtInSubjectID: builtInSubject.rawValue, topicID: topicID) else { return }
        customCurriculum = updated
    }

    private func queueStudyReview(
        lessonID: String,
        quality: Int,
        reflection: String,
        completeLesson: Bool?
    ) {
        guard !hasPendingReview(lessonID: lessonID) else { return }
        pendingStudyReviews.append(StudyReviewEvent(
            id: UUID().uuidString.lowercased(),
            lessonID: lessonID,
            quality: quality,
            reflection: String(reflection.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500)),
            completeLesson: completeLesson
        ))
        Task { await syncStudyProgress() }
    }
}

@MainActor
final class LocalBackendSupervisor: ObservableObject {
    enum Status: Equatable {
        case idle
        case starting
        case running
        case alreadyRunning
        case unavailable
        case failed

        var localizationKey: String {
            switch self {
            case .idle: return "settings.backendIdle"
            case .starting: return "settings.backendStarting"
            case .running: return "settings.backendRunning"
            case .alreadyRunning: return "settings.backendAlreadyRunning"
            case .unavailable: return "settings.backendUnavailable"
            case .failed: return "settings.backendFailed"
            }
        }
    }

    @Published private(set) var status: Status = .idle
    private var process: Process?
    private var startupTask: Task<Bool, Never>?
    private let baseURL = URL(string: "http://127.0.0.1:8000")!

    var isReady: Bool {
        status == .alreadyRunning || (status == .running && process?.isRunning == true)
    }

    func ensureRunning() async -> Bool {
        if let startupTask {
            return await startupTask.value
        }
        if let process, process.isRunning {
            if await waitUntilReady(timeout: 3) {
                status = .running
                return true
            }
            if process.isRunning { process.terminate() }
            self.process = nil
            status = .failed
            return false
        }
        process = nil

        if await orchestratorResponds() {
            status = .alreadyRunning
            return true
        }
        if let startupTask {
            return await startupTask.value
        }

        let task = Task { @MainActor [weak self] in
            guard let self else { return false }
            return await self.startBundledBackend()
        }
        startupTask = task
        let result = await task.value
        startupTask = nil
        return result
    }

    func stop() {
        if let process, process.isRunning {
            process.terminate()
        }
        process = nil
        startupTask = nil
        status = .idle
    }

    private func startBundledBackend() async -> Bool {
        guard let resources = Bundle.main.resourceURL else {
            status = .unavailable
            return false
        }
        let executable = resources.appendingPathComponent("ColiDevBackend/ColiDevBackend")
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            status = .unavailable
            return false
        }

        status = .starting
        let child = Process()
        child.executableURL = executable
        child.currentDirectoryURL = resources
        var environment = ProcessInfo.processInfo.environment
        environment["COLIDEV_PROJECT_ROOT"] = resources.path
        environment["HOST"] = "127.0.0.1"
        environment["PORT"] = "8000"
        environment["DEV_MODE"] = "false"
        child.environment = environment
        child.standardOutput = FileHandle.nullDevice
        child.standardError = FileHandle.nullDevice
        child.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.process === child else { return }
                self.process = nil
                self.status = .failed
            }
        }

        do {
            try child.run()
        } catch {
            status = .failed
            return false
        }
        process = child

        if await waitUntilReady(timeout: 15) {
            status = .running
            return true
        }
        if child.isRunning {
            child.terminate()
        }
        process = nil
        status = .failed
        return false
    }

    private func waitUntilReady(timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await orchestratorResponds() { return true }
            if let process, !process.isRunning { return false }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        return false
    }

    private func orchestratorResponds() async -> Bool {
        let endpoint = baseURL.appendingPathComponent("api/status")
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 0.5
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let service = payload["service"] as? String else {
                return false
            }
            return service.hasPrefix("coli-dev Orchestrator")
        } catch {
            return false
        }
    }
}

struct OrchestratorHealth: Decodable {
    let status: String
    let online: Bool
    let provider: String
    let ollamaAvailable: Bool
    let ollamaModel: String
    let ollamaEmbeddingModel: String?
    let ollamaModelReady: Bool?
    let geminiKeyConfigured: Bool?
    let openRouterKeyConfigured: Bool?
    let openRouterModel: String?
    let ollamaEndpointLocal: Bool?
    let obsidianEndpointLocal: Bool?
    let sessionMode: String?
    let sessionCurrent: Int?
    let sessionMax: Int?
    let cloudRouteReady: Bool?
    let localRouteReady: Bool?
    let automaticRouteReady: Bool?
    let cloudModelCallsToday: Int?
    let cloudModelCallsMax: Int?
    let cloudModelCallsRemaining: Int?
    let knowledgeDocumentCount: Int?
    let knowledgeIndexCheckedAt: String?
    let knowledgeReviewDueDocumentCount: Int?
    let knowledgeReviewScheduledDocumentCount: Int?
    let knowledgeReviewScheduleMissingDocumentCount: Int?

    var isOllamaEndpointLocal: Bool { ollamaEndpointLocal ?? false }
    var isObsidianEndpointLocal: Bool { obsidianEndpointLocal ?? false }
    var hasGroundedSearch: Bool { online && geminiKeyConfigured == true && hasCloudSession }
    var hasLocalModel: Bool { isOllamaEndpointLocal && ollamaAvailable && (ollamaModelReady ?? false) }
    var displayKnowledgeIndexCheckedAt: String? {
        guard let knowledgeIndexCheckedAt else { return nil }
        guard let date = ISO8601DateFormatter().date(from: knowledgeIndexCheckedAt) else {
            return knowledgeIndexCheckedAt
        }
        return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
    }
    var hasCloudSession: Bool {
        guard online, sessionMode != "local" else { return false }
        guard let sessionCurrent, let sessionMax else { return true }
        return sessionCurrent < sessionMax
    }

    var hasCloudRoute: Bool { cloudRouteReady ?? false }
    var hasAutomaticRoute: Bool { automaticRouteReady ?? false }

    enum CodingKeys: String, CodingKey {
        case status, online, provider
        case ollamaAvailable = "ollama_available"
        case ollamaModel = "ollama_model"
        case ollamaEmbeddingModel = "ollama_embedding_model"
        case ollamaModelReady = "ollama_model_ready"
        case geminiKeyConfigured = "gemini_key_configured"
        case openRouterKeyConfigured = "openrouter_key_configured"
        case openRouterModel = "openrouter_model"
        case ollamaEndpointLocal = "ollama_endpoint_local"
        case obsidianEndpointLocal = "obsidian_endpoint_local"
        case sessionMode = "session_mode"
        case sessionCurrent = "session_current"
        case sessionMax = "session_max"
        case cloudRouteReady = "cloud_route_ready"
        case localRouteReady = "local_route_ready"
        case automaticRouteReady = "automatic_route_ready"
        case cloudModelCallsToday = "cloud_model_calls_today"
        case cloudModelCallsMax = "cloud_model_calls_max"
        case cloudModelCallsRemaining = "cloud_model_calls_remaining"
        case knowledgeDocumentCount = "knowledge_document_count"
        case knowledgeIndexCheckedAt = "knowledge_index_checked_at"
        case knowledgeReviewDueDocumentCount = "knowledge_review_due_document_count"
        case knowledgeReviewScheduledDocumentCount = "knowledge_review_scheduled_document_count"
        case knowledgeReviewScheduleMissingDocumentCount = "knowledge_review_schedule_missing_document_count"
    }
}

struct ProviderUsageCounts: Decodable {
    let successfulResponses: Int
    let responsesWithReportedUsage: Int
    let responsesWithoutReportedUsage: Int
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
    let responsesWithInputCount: Int
    let responsesWithOutputCount: Int
    let responsesWithTotalCount: Int

    enum CodingKeys: String, CodingKey {
        case successfulResponses = "successful_responses"
        case responsesWithReportedUsage = "responses_with_reported_usage"
        case responsesWithoutReportedUsage = "responses_without_reported_usage"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
        case responsesWithInputCount = "responses_with_input_count"
        case responsesWithOutputCount = "responses_with_output_count"
        case responsesWithTotalCount = "responses_with_total_count"
    }
}

struct ProviderUsageBreakdown: Decodable, Identifiable {
    let provider: String
    let model: String
    let successfulResponses: Int
    let responsesWithReportedUsage: Int
    let responsesWithoutReportedUsage: Int
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
    let responsesWithInputCount: Int
    let responsesWithOutputCount: Int
    let responsesWithTotalCount: Int

    var id: String { "\(provider):\(model)" }

    enum CodingKeys: String, CodingKey {
        case provider, model
        case successfulResponses = "successful_responses"
        case responsesWithReportedUsage = "responses_with_reported_usage"
        case responsesWithoutReportedUsage = "responses_without_reported_usage"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
        case responsesWithInputCount = "responses_with_input_count"
        case responsesWithOutputCount = "responses_with_output_count"
        case responsesWithTotalCount = "responses_with_total_count"
    }
}

struct ProviderUsageSummary: Decodable {
    let generatedAt: String
    let periodDays: Int
    let periodStart: String
    let totals: ProviderUsageCounts
    let providers: [ProviderUsageBreakdown]
    let note: String

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case periodDays = "period_days"
        case periodStart = "period_start"
        case totals, providers, note
    }
}

struct KnowledgeIndexRefreshResult: Decodable {
    let status: String
    let documentCount: Int
    let lastCheckedAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case documentCount = "document_count"
        case lastCheckedAt = "last_checked_at"
    }
}

struct KnowledgeRAGSearchResult: Decodable {
    let status: String
    let query: String
    let generatedAt: String
    let sourceCount: Int
    let sources: [TutorSource]

    enum CodingKeys: String, CodingKey {
        case status, query, sources
        case generatedAt = "generated_at"
        case sourceCount = "source_count"
    }
}

struct TrustedSourceCheckResult: Decodable {
    let supportedCount: Int
    let checkedCount: Int
    let changedCount: Int
    let needsAttentionCount: Int
    let availableUntrackedCount: Int
    let unsupportedCount: Int
    let omittedCount: Int
    let checks: [TrustedSourceCheck]

    enum CodingKeys: String, CodingKey {
        case supportedCount = "supported_count"
        case checkedCount = "checked_count"
        case changedCount = "changed_count"
        case needsAttentionCount = "needs_attention_count"
        case availableUntrackedCount = "available_untracked_count"
        case unsupportedCount = "unsupported_count"
        case omittedCount = "omitted_count"
        case checks
    }
}

struct TrustedSourceCheck: Decodable, Identifiable {
    let url: String
    let title: String
    let lessonPath: String
    let state: String

    var id: String { url }

    enum CodingKeys: String, CodingKey {
        case url
        case title
        case lessonPath = "lesson_path"
        case state
    }
}

struct TrustedSourceInventory: Decodable {
    let status: String
    let supportedCount: Int
    let listedCount: Int
    let uncheckedCount: Int
    let changedCount: Int
    let needsAttentionCount: Int
    let editorialReviewDueCount: Int?
    let editorialReviewScheduledCount: Int?
    let editorialReviewMissingCount: Int?
    let editorialReviewUnscheduledCount: Int?
    let unsupportedCount: Int
    let omittedCount: Int
    let automaticCheckEnabled: Bool?
    let automaticCheckIntervalHours: Int?
    let sources: [TrustedSourceInventoryItem]

    enum CodingKeys: String, CodingKey {
        case status, sources
        case supportedCount = "supported_count"
        case listedCount = "listed_count"
        case uncheckedCount = "unchecked_count"
        case changedCount = "changed_count"
        case needsAttentionCount = "needs_attention_count"
        case editorialReviewDueCount = "editorial_review_due_count"
        case editorialReviewScheduledCount = "editorial_review_scheduled_count"
        case editorialReviewMissingCount = "editorial_review_missing_count"
        case editorialReviewUnscheduledCount = "editorial_review_unscheduled_count"
        case unsupportedCount = "unsupported_count"
        case omittedCount = "omitted_count"
        case automaticCheckEnabled = "automatic_check_enabled"
        case automaticCheckIntervalHours = "automatic_check_interval_hours"
    }
}

struct TrustedSourceInventoryItem: Decodable, Identifiable {
    let url: String
    let title: String
    let lessonPath: String
    let lessonPaths: [String]?
    let lessonReviews: [TrustedSourceLessonReview]?
    let lessonReviewedOn: String?
    let editorialReviewIntervalDays: Int?
    let editorialReviewDueOn: String?
    let editorialReviewStatus: String?
    let state: String
    let lastCheckedAt: String?
    let lastHTTPStatus: Int?
    let lastModified: String?
    let hasETag: Bool
    let pageTitle: String?
    let pageDescription: String?
    let contentCheckedAt: String?
    let ragContentState: String?
    let ragContentFetchedAt: String?
    let ragLicense: String?
    let ragLicenseURL: String?
    let ragRestrictionURL: String?

    var id: String { url }

    enum CodingKeys: String, CodingKey {
        case url, title, state
        case lessonPath = "lesson_path"
        case lessonPaths = "lesson_paths"
        case lessonReviews = "lesson_reviews"
        case lessonReviewedOn = "lesson_reviewed_on"
        case editorialReviewIntervalDays = "editorial_review_interval_days"
        case editorialReviewDueOn = "editorial_review_due_on"
        case editorialReviewStatus = "editorial_review_status"
        case lastCheckedAt = "last_checked_at"
        case lastHTTPStatus = "last_http_status"
        case lastModified = "last_modified"
        case hasETag = "has_etag"
        case pageTitle = "page_title"
        case pageDescription = "page_description"
        case contentCheckedAt = "content_checked_at"
        case ragContentState = "rag_content_state"
        case ragContentFetchedAt = "rag_content_fetched_at"
        case ragLicense = "rag_license"
        case ragLicenseURL = "rag_license_url"
        case ragRestrictionURL = "rag_restriction_url"
    }
}

struct TrustedSourceEditorialReviewHistory: Decodable {
    let status: String
    let url: String
    let reviews: [TrustedSourceEditorialReview]
    let hasMore: Bool
    let nextBeforeReviewID: Int?

    enum CodingKeys: String, CodingKey {
        case status, url, reviews
        case hasMore = "has_more"
        case nextBeforeReviewID = "next_before_review_id"
    }
}

struct TrustedSourceEditorialReview: Decodable, Identifiable {
    let reviewID: Int
    let url: String
    let lessonPath: String
    let reviewedDigest: String
    let reviewedOn: String
    let reviewedAt: String

    var id: Int { reviewID }

    enum CodingKeys: String, CodingKey {
        case url
        case reviewID = "review_id"
        case lessonPath = "lesson_path"
        case reviewedDigest = "reviewed_digest"
        case reviewedOn = "reviewed_on"
        case reviewedAt = "reviewed_at"
    }
}

struct TrustedSourcePagePreview: Decodable, Identifiable {
    let url: String
    let title: String
    let lessonPaths: [String]
    let pageTitle: String?
    let pageDescription: String?
    let excerpt: String
    let excerptTruncated: Bool
    let contentDigest: String
    let fetchedAt: String

    var id: String { url }

    enum CodingKeys: String, CodingKey {
        case url, title, excerpt
        case lessonPaths = "lesson_paths"
        case pageTitle = "page_title"
        case pageDescription = "page_description"
        case excerptTruncated = "excerpt_truncated"
        case contentDigest = "content_digest"
        case fetchedAt = "fetched_at"
    }
}

struct TrustedSourceLessonReview: Decodable, Identifiable {
    let lessonPath: String
    let lessonReviewedOn: String?
    let editorialReviewIntervalDays: Int?
    let editorialReviewDueOn: String?
    let editorialReviewStatus: String

    var id: String { lessonPath }

    enum CodingKeys: String, CodingKey {
        case lessonPath = "lesson_path"
        case lessonReviewedOn = "lesson_reviewed_on"
        case editorialReviewIntervalDays = "editorial_review_interval_days"
        case editorialReviewDueOn = "editorial_review_due_on"
        case editorialReviewStatus = "editorial_review_status"
    }
}

struct ProviderSecretStatus: Decodable, Identifiable {
    let provider: String
    let configured: Bool
    let source: String

    var id: String { provider }
}

struct OpenAICompatibleSettings: Decodable, Hashable {
    let baseURL: String
    let model: String
    let providerReady: Bool
    let status: String

    enum CodingKeys: String, CodingKey {
        case model, status
        case baseURL = "base_url"
        case providerReady = "provider_ready"
    }
}

struct SubjectModelRoute: Decodable, Identifiable, Hashable {
    let subject: String
    let provider: String
    let model: String?
    let effectiveModel: String?
    let providerReady: Bool?
    let status: String

    var id: String { subject }

    enum CodingKeys: String, CodingKey {
        case subject, provider, model, status
        case effectiveModel = "effective_model"
        case providerReady = "provider_ready"
    }
}

struct SubjectModelRoutingSnapshot: Decodable {
    let subjects: [SubjectModelRoute]
}

struct AutoAgentModelRoute: Decodable, Identifiable, Hashable {
    let role: String
    let provider: String
    let model: String?
    let effectiveProvider: String
    let effectiveModel: String
    let providerReady: Bool?
    let effectiveProviderReady: Bool?
    let status: String
    let paidRouteBlocked: Bool

    var id: String { role }

    enum CodingKeys: String, CodingKey {
        case role, provider, model, status
        case effectiveProvider = "effective_provider"
        case effectiveModel = "effective_model"
        case providerReady = "provider_ready"
        case effectiveProviderReady = "effective_provider_ready"
        case paidRouteBlocked = "paid_route_blocked"
    }
}

struct AutoAgentModelRoutingSnapshot: Decodable {
    let roles: [AutoAgentModelRoute]
}

struct LocalOllamaModelCatalog: Decodable, Equatable {
    let available: Bool
    let status: String
    let models: [String]

    static let notChecked = Self(available: false, status: "not_checked", models: [])
    static let unavailable = Self(available: false, status: "unavailable", models: [])
}

struct FinalSynthesisModelRoute: Decodable, Hashable {
    let provider: String
    let model: String?
    let effectiveProvider: String
    let effectiveModel: String
    let providerReady: Bool?
    let status: String

    enum CodingKeys: String, CodingKey {
        case provider, model, status
        case effectiveProvider = "effective_provider"
        case effectiveModel = "effective_model"
        case providerReady = "provider_ready"
    }
}

struct AutoCostPolicy: Decodable, Hashable {
    let allowPaidRoutes: Bool

    enum CodingKeys: String, CodingKey {
        case allowPaidRoutes = "allow_paid_routes"
    }
}

private struct SubjectModelRouteUpdate: Encodable {
    let provider: String
    let model: String?
}

private struct OpenAICompatibleSettingsUpdate: Encodable {
    let baseURL: String
    let model: String

    enum CodingKeys: String, CodingKey {
        case model
        case baseURL = "base_url"
    }
}

private struct AutoAgentModelUpdate: Encodable {
    let provider: String
    let model: String?
}

private struct FinalSynthesisModelRouteUpdate: Encodable {
    let provider: String
    let model: String?
}

private struct AutoCostPolicyUpdate: Encodable {
    let allowPaidRoutes: Bool

    enum CodingKeys: String, CodingKey {
        case allowPaidRoutes = "allow_paid_routes"
    }
}

private struct ProviderSecretStatusResponse: Decodable {
    let providers: [ProviderSecretStatus]
}

private struct ProviderSecretInput: Encodable {
    let apiKey: String

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
    }
}

enum AIRoutingMode: String, CaseIterable, Identifiable, Hashable {
    case automatic = "auto"
    case localOnly = "local"

    var id: String { rawValue }
}

private struct TutorRequest: Encodable {
    let message: String
    let systemPrompt: String
    let subject: String
    let language: String
    let mode: String
    let retrievalQuery: String
    let useWebSearch: Bool
    let groundingAgeConfirmed: Bool
    let includeLocalSourcesInWebSearch: Bool

    enum CodingKeys: String, CodingKey {
        case message, subject, language, mode
        case systemPrompt = "system_prompt"
        case retrievalQuery = "retrieval_query"
        case useWebSearch = "use_web_search"
        case groundingAgeConfirmed = "grounding_age_confirmed"
        case includeLocalSourcesInWebSearch = "include_local_sources_in_web_search"
    }
}

struct TutorSource: Decodable, Identifiable {
    let id: String
    let title: String
    let excerpt: String
    let retrievedAt: String
    let path: String?
    let location: String?
    let modifiedAt: String?
    let sourceCheckedAt: String?
    let sourceReviewIntervalDays: String?
    let sourceReviewDueOn: String?
    let sourceReviewStatus: String?
    let sourceType: String?
    let officialReferences: [TutorSourceReference]?
    let license: String?
    let licenseURL: String?
    let attribution: String?

    enum CodingKeys: String, CodingKey {
        case id, title, excerpt
        case retrievedAt = "retrieved_at"
        case path, location
        case modifiedAt = "modified_at"
        case sourceCheckedAt = "source_checked_at"
        case sourceReviewIntervalDays = "source_review_interval_days"
        case sourceReviewDueOn = "source_review_due_on"
        case sourceReviewStatus = "source_review_status"
        case sourceType = "source_type"
        case officialReferences = "official_references"
        case license
        case licenseURL = "license_url"
        case attribution
    }

    var displayRetrievedAt: String {
        guard let date = ISO8601DateFormatter().date(from: retrievedAt) else { return retrievedAt }
        return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
    }

    var displayModifiedAt: String? {
        guard let modifiedAt else { return nil }
        guard let date = ISO8601DateFormatter().date(from: modifiedAt) else { return modifiedAt }
        return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
    }
}

struct TutorSourceReference: Decodable, Identifiable {
    let title: String
    let url: String

    var id: String { url }
    var safeURL: URL? { SafeWebReferenceURL.parse(url) }
}

private struct TutorEvent: Decodable {
    let type: String
    let content: String?
    let answer: String?
    let provider: String?
    let model: String?
    let durationMS: Int?
    let sources: [TutorSource]?
    let citationWarnings: [String]?
    let googleSearchSuggestions: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case type, content, answer, provider, model, sources, error
        case durationMS = "duration_ms"
        case citationWarnings = "citation_warnings"
        case googleSearchSuggestions = "google_search_suggestions"
    }
}

struct TutorCompletion {
    let provider: String
    let model: String
    let durationMS: Int
    let sources: [TutorSource]
    let citationWarnings: [String]
    let googleSearchSuggestions: String?
}

@MainActor
enum OrchestratorClient {
    enum ClientError: Error {
        case invalidResponse
        case unavailable
        case serverError(String)
        case incompleteStream
    }

    static func health() async throws -> OrchestratorHealth {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/health") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(OrchestratorHealth.self, from: data)
    }

    static func providerUsage(days: Int = 30, language: AppLanguage = .ru) async throws -> ProviderUsageSummary {
        guard (1...90).contains(days),
              let url = URL(string: LearningStore.orchestratorBaseURL + "/api/usage?days=\(days)&language=\(language.rawValue)") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(ProviderUsageSummary.self, from: data)
    }

    static func refreshKnowledgeIndex() async throws -> KnowledgeIndexRefreshResult {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/knowledge/refresh") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(KnowledgeIndexRefreshResult.self, from: data)
    }

    static func searchKnowledgeRAG(
        query: String, includeObsidian: Bool, limit: Int = 4
    ) async throws -> KnowledgeRAGSearchResult {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...500).contains(normalizedQuery.count), (1...4).contains(limit),
              let url = URL(string: LearningStore.orchestratorBaseURL + "/knowledge/rag/search") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            KnowledgeRAGSearchRequest(
                query: normalizedQuery,
                includeObsidian: includeObsidian,
                limit: limit
            )
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(KnowledgeRAGSearchResult.self, from: data)
    }

    static func checkTrustedSourceReferences() async throws -> TrustedSourceCheckResult {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/knowledge/sources/check") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(TrustedSourceCheckResult.self, from: data)
    }

    static func trustedSourceInventory() async throws -> TrustedSourceInventory {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/knowledge/sources") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(TrustedSourceInventory.self, from: data)
    }

    static func trustedSourceReviewHistory(
        url sourceURL: String,
        beforeReviewID: Int? = nil,
        limit: Int = 50
    ) async throws -> TrustedSourceEditorialReviewHistory {
        guard var components = URLComponents(
            string: LearningStore.orchestratorBaseURL + "/knowledge/sources/reviews"
        ) else { throw ClientError.invalidResponse }
        components.queryItems = [
            URLQueryItem(name: "url", value: sourceURL),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        if let beforeReviewID {
            components.queryItems?.append(
                URLQueryItem(name: "before_review_id", value: String(beforeReviewID))
            )
        }
        guard let url = components.url else { throw ClientError.invalidResponse }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(TrustedSourceEditorialReviewHistory.self, from: data)
    }

    static func previewTrustedSource(url sourceURL: String) async throws -> TrustedSourcePagePreview {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/knowledge/sources/preview") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(TrustedSourcePreviewRequest(url: sourceURL))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(TrustedSourcePagePreview.self, from: data)
    }

    static func recordTrustedSourceReview(
        url sourceURL: String,
        lessonPath: String,
        previewDigest: String
    ) async throws {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/knowledge/sources/review") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            TrustedSourceReviewRequest(url: sourceURL, lessonPath: lessonPath, previewDigest: previewDigest)
        )
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
    }

    static func studyProgress() async throws -> StudyProgressSnapshot {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/learning/progress") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(StudyProgressSnapshot.self, from: data)
    }

    static func learningProgressBackup() async throws -> Data {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/learning/progress/backup") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return data
    }

    static func restoreLearningProgressBackup(_ data: Data) async throws -> ProgressBackupRestoreSummary {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/learning/progress/backup/restore") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(ProgressBackupRestoreSummary.self, from: responseData)
    }

    static func saveObsidianNote(path: String, content: String) async throws {
        let segments = path.split(separator: "/", omittingEmptySubsequences: false)
        guard !path.isEmpty,
              path.utf8.count <= 512,
              !segments.isEmpty,
              segments.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
              !content.contains("\0"),
              content.utf8.count <= 950_000 else {
            throw ClientError.invalidResponse
        }
        let segmentCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
        let encodedPath = segments.map { segment in
            String(segment).addingPercentEncoding(withAllowedCharacters: segmentCharacters) ?? ""
        }.joined(separator: "/")
        guard !encodedPath.isEmpty,
              let url = URL(string: LearningStore.orchestratorBaseURL + "/obsidian/write/" + encodedPath) else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ObsidianWriteRequest(content: content))
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
    }

    static func recordStudyReview(_ event: StudyReviewEvent) async throws -> StudyProgressRecord {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/learning/reviews") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(event)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(StudyProgressRecord.self, from: data)
    }

    static func providerSecretStatuses() async throws -> [ProviderSecretStatus] {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/api-keys") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(ProviderSecretStatusResponse.self, from: data).providers
    }

    static func openAICompatibleSettings() async throws -> OpenAICompatibleSettings {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/openai-compatible") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(OpenAICompatibleSettings.self, from: data)
    }

    static func saveOpenAICompatibleSettings(
        baseURL: String,
        model: String
    ) async throws -> OpenAICompatibleSettings {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/openai-compatible") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            OpenAICompatibleSettingsUpdate(baseURL: baseURL, model: model)
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(OpenAICompatibleSettings.self, from: data)
    }

    static func subjectModelRoutes() async throws -> [SubjectModelRoute] {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/model-routing") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(SubjectModelRoutingSnapshot.self, from: data).subjects
    }

    static func saveSubjectModelRoute(
        subject: Subject,
        provider: String,
        model: String?
    ) async throws -> SubjectModelRoute {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/model-routing/\(subject.rawValue)") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(SubjectModelRouteUpdate(provider: provider, model: model))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(SubjectModelRoute.self, from: data)
    }

    static func resetSubjectModelRoute(subject: Subject) async throws -> SubjectModelRoute {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/model-routing/\(subject.rawValue)") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(SubjectModelRoute.self, from: data)
    }

    static func autoAgentModelRoutes() async throws -> [AutoAgentModelRoute] {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/agent-models") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(AutoAgentModelRoutingSnapshot.self, from: data).roles
    }

    static func localOllamaModelCatalog() async throws -> LocalOllamaModelCatalog {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/ollama/models") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(LocalOllamaModelCatalog.self, from: data)
    }

    static func saveAutoAgentModelRoute(
        role: String, provider: String, model: String?
    ) async throws -> AutoAgentModelRoute {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/agent-models/\(role)") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            AutoAgentModelUpdate(provider: provider, model: model)
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(AutoAgentModelRoute.self, from: data)
    }

    static func resetAutoAgentModelRoute(role: String) async throws -> AutoAgentModelRoute {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/agent-models/\(role)") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(AutoAgentModelRoute.self, from: data)
    }

    static func finalSynthesisModelRoute() async throws -> FinalSynthesisModelRoute {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/final-synthesis-route") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(FinalSynthesisModelRoute.self, from: data)
    }

    static func saveFinalSynthesisModelRoute(
        provider: String,
        model: String?
    ) async throws -> FinalSynthesisModelRoute {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/final-synthesis-route") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            FinalSynthesisModelRouteUpdate(provider: provider, model: model)
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(FinalSynthesisModelRoute.self, from: data)
    }

    static func resetFinalSynthesisModelRoute() async throws -> FinalSynthesisModelRoute {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/final-synthesis-route") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(FinalSynthesisModelRoute.self, from: data)
    }

    static func autoCostPolicy() async throws -> AutoCostPolicy {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/auto-cost-policy") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(AutoCostPolicy.self, from: data)
    }

    static func saveAutoCostPolicy(allowPaidRoutes: Bool) async throws -> AutoCostPolicy {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/auto-cost-policy") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            AutoCostPolicyUpdate(allowPaidRoutes: allowPaidRoutes)
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(AutoCostPolicy.self, from: data)
    }

    static func saveProviderSecret(_ apiKey: String, for provider: String) async throws -> ProviderSecretStatus {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/api-keys/\(provider)") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ProviderSecretInput(apiKey: apiKey))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(ProviderSecretStatus.self, from: data)
    }

    static func deleteProviderSecret(for provider: String) async throws -> ProviderSecretStatus {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/settings/api-keys/\(provider)") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }
        return try JSONDecoder().decode(ProviderSecretStatus.self, from: data)
    }

    static func streamChat(
        message: String,
        systemPrompt: String,
        retrievalQuery: String,
        subjectID: String,
        language: AppLanguage,
        mode: AIRoutingMode,
        useWebSearch: Bool = false,
        groundingAgeConfirmed: Bool = false,
        includeLocalSourcesInWebSearch: Bool = false,
        onToken: @MainActor (String) -> Void,
        onFinalAnswer: @MainActor (String) -> Void
    ) async throws -> TutorCompletion {
        guard let url = URL(string: LearningStore.orchestratorBaseURL + "/chat/stream") else {
            throw ClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 600
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(TutorRequest(
            message: message,
            systemPrompt: systemPrompt,
            subject: subjectID,
            language: language.rawValue,
            mode: mode.rawValue,
            retrievalQuery: retrievalQuery,
            useWebSearch: useWebSearch,
            groundingAgeConfirmed: groundingAgeConfirmed,
            includeLocalSourcesInWebSearch: includeLocalSourcesInWebSearch
        ))

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.unavailable
        }

        var completion: TutorCompletion?
        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }
            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            guard let data = payload.data(using: .utf8),
                  let event = try? JSONDecoder().decode(TutorEvent.self, from: data) else { continue }

            switch event.type {
            case "token":
                if let content = event.content { onToken(content) }
            case "error":
                throw ClientError.serverError(event.error ?? "The server could not answer this request.")
            case "done":
                if let answer = event.answer { onFinalAnswer(answer) }
                completion = TutorCompletion(
                    provider: event.provider ?? "AI",
                    model: event.model ?? "",
                    durationMS: event.durationMS ?? 0,
                    sources: event.sources ?? [],
                    citationWarnings: event.citationWarnings ?? [],
                    googleSearchSuggestions: event.googleSearchSuggestions
                )
            default:
                // Keep internal debate_log HTML out of the learner-facing chat.
                continue
            }
        }

        guard let completion else { throw ClientError.incompleteStream }
        return completion
    }
}

struct TutorMessage: Identifiable {
    enum Role: Equatable { case learner, tutor }
    let id = UUID()
    let role: Role
    var text: String
    var sources: [TutorSource] = []
    var citationWarnings: [String] = []
    var googleSearchSuggestions: String? = nil
    var isGoogleGrounded = false
}

private struct TrustedSourcePreviewRequest: Encodable {
    let url: String
}

private struct KnowledgeRAGSearchRequest: Encodable {
    let query: String
    let includeObsidian: Bool
    let limit: Int

    enum CodingKeys: String, CodingKey {
        case query, limit
        case includeObsidian = "include_obsidian"
    }
}

private struct ObsidianWriteRequest: Encodable {
    let content: String
}

private struct TrustedSourceReviewRequest: Encodable {
    let url: String
    let lessonPath: String
    let previewDigest: String

    enum CodingKeys: String, CodingKey {
        case url
        case lessonPath = "lesson_path"
        case previewDigest = "preview_digest"
    }
}

@MainActor
final class TutorChatModel: ObservableObject {
    @Published private(set) var messages: [TutorMessage] = []
    @Published private(set) var isSending = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var completionLabel: String?
    private var requestTask: Task<Void, Never>?

    let subjectID: String
    let subjectName: String
    let lesson: LessonContent
    let language: AppLanguage
    let mode: AIRoutingMode

    init(subject: Subject, lesson: LessonContent, language: AppLanguage, mode: AIRoutingMode) {
        self.subjectID = subject.rawValue
        self.subjectName = subject.title(in: language)
        self.lesson = lesson
        self.language = language
        self.mode = mode
    }

    init(subjectID: String, subjectName: String, lesson: LessonContent, language: AppLanguage, mode: AIRoutingMode) {
        self.subjectID = subjectID
        self.subjectName = subjectName
        self.lesson = lesson
        self.language = language
        self.mode = mode
    }

    func send(
        _ rawText: String,
        useWebSearch: Bool = false,
        groundingAgeConfirmed: Bool = false,
        includeLocalSourcesInWebSearch: Bool = false
    ) {
        let question = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isSending else { return }

        errorMessage = nil
        completionLabel = nil
        messages.append(TutorMessage(role: .learner, text: question))
        let reply = TutorMessage(role: .tutor, text: "")
        messages.append(reply)
        isSending = true

        let systemPrompt: String
        if language == .ru {
            systemPrompt = """
            Ты — внимательный учебный тьютор. Предмет: \(subjectName). Урок: \(lesson.title).
            Цель: \(lesson.objective)
            Теория: \(lesson.explanation)
            Механизм: \(lesson.mechanism)
            Пример: \(lesson.example)
            Ограничения модели: \(lesson.limitations)
            Отвечай по-русски. Объясняй ясно и по шагам, подбирай глубину к вопросу. Помогай разобраться вопросами и подсказками; не выдавай решение задания сразу, если ученик просит научить. Не выдумывай источники и текущие факты.
            """
        } else {
            systemPrompt = """
            You are a thoughtful learning tutor. Subject: \(subjectName). Lesson: \(lesson.title).
            Goal: \(lesson.objective)
            Theory: \(lesson.explanation)
            Mechanism: \(lesson.mechanism)
            Example: \(lesson.example)
            Model limitations: \(lesson.limitations)
            Answer in English. Explain clearly in steps at the learner's level. Use questions and hints to build understanding; do not immediately give away an exercise solution when the learner asks to learn. Do not invent sources or current facts.
            """
        }

        let recentConversation = messages.dropLast().suffix(12)
            .filter { !($0.role == .tutor && $0.isGoogleGrounded) }
            .map { message in
            let speaker = message.role == .learner
                ? (language == .ru ? "Ученик" : "Learner")
                : (language == .ru ? "Тьютор" : "Tutor")
            return "\(speaker): \(message.text.prefix(1600))"
        }.joined(separator: "\n")
        let requestMessage = useWebSearch || recentConversation.isEmpty ? question : recentConversation

        requestTask = Task {
            do {
                let result = try await OrchestratorClient.streamChat(
                    message: requestMessage,
                    systemPrompt: systemPrompt,
                    retrievalQuery: "\(subjectName) \(lesson.title) \(question)",
                    subjectID: subjectID,
                    language: language,
                    mode: mode,
                    useWebSearch: useWebSearch,
                    groundingAgeConfirmed: groundingAgeConfirmed,
                    includeLocalSourcesInWebSearch: includeLocalSourcesInWebSearch,
                    onToken: { [weak self] token in self?.append(token, to: reply.id) },
                    onFinalAnswer: { [weak self] answer in self?.replace(answer, in: reply.id) }
                )
                completionLabel = [result.provider, result.model].filter { !$0.isEmpty }.joined(separator: " · ")
                if let index = messages.firstIndex(where: { $0.id == reply.id }) {
                    messages[index].sources = result.sources
                    messages[index].citationWarnings = result.citationWarnings
                    messages[index].googleSearchSuggestions = result.googleSearchSuggestions
                    messages[index].isGoogleGrounded = result.googleSearchSuggestions != nil
                }
            } catch is CancellationError {
                // Keep a partial answer visible when the learner stops generation.
            } catch OrchestratorClient.ClientError.serverError(let message) {
                discard(reply.id)
                errorMessage = message
            } catch {
                discard(reply.id)
                errorMessage = language == .ru
                    ? "Не удалось получить ответ. Проверь, запущен ли локальный оркестратор."
                    : "The tutor could not reply. Check that the local orchestrator is running."
            }
            isSending = false
            requestTask = nil
        }
    }

    func cancel() {
        requestTask?.cancel()
    }

    private func append(_ token: String, to messageID: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }
        messages[index].text += token
    }

    private func replace(_ text: String, in messageID: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }
        messages[index].text = text
    }

    private func discard(_ messageID: UUID) {
        messages.removeAll { $0.id == messageID }
    }
}

enum AppSection: Hashable {
    case today
    case subjects
    case subject(Subject)
    case lesson(Subject)
    case courseLesson(Subject, String)
    case customSubject(UUID)
    case customTopic(UUID, UUID)
    case builtInCustomTopic(Subject, UUID)
    case management
    case settings
}
