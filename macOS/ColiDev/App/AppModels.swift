import SwiftUI
import Foundation

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

    var starterRoadmapTopic: String {
        switch self {
        case .mathematics: return "Coordinates, graphs, functions"
        case .english: return "Aspect, modal verbs, conditionals"
        case .physics: return "Forces and Newton's laws"
        case .biology: return "Cells, membranes, metabolism"
        case .zoology: return "Habitat, adaptation, behavior"
        case .programming: return "Conditionals, loops, functions"
        }
    }

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

    var eventID: String { id }

    enum CodingKeys: String, CodingKey {
        case id = "event_id"
        case lessonID = "lesson_id"
        case quality
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

@MainActor
final class LearningStore: ObservableObject {
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "colidev.language") }
    }
    @Published private(set) var completedLessonIDs: Set<String> {
        didSet { UserDefaults.standard.set(Array(completedLessonIDs), forKey: "colidev.completedLessons") }
    }
    @Published private(set) var aiHealth: OrchestratorHealth?
    @Published private(set) var isCheckingAI = false
    @Published private(set) var providerSecretStatuses: [String: ProviderSecretStatus] = [:]
    @Published private(set) var studyProgress: [String: StudyProgressRecord] = [:]
    @Published private(set) var dueReviewCount = 0
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

    func saveProviderSecret(_ apiKey: String, for provider: String) async throws {
        let status = try await OrchestratorClient.saveProviderSecret(apiKey, for: provider)
        providerSecretStatuses[provider] = status
        await refreshAIStatus()
    }

    func deleteProviderSecret(for provider: String) async throws {
        let status = try await OrchestratorClient.deleteProviderSecret(for: provider)
        providerSecretStatuses[provider] = status
        await refreshAIStatus()
    }

    func isComplete(_ subject: Subject) -> Bool {
        completedLessonIDs.contains(subject.lessonID)
    }

    func markComplete(_ subject: Subject) {
        completedLessonIDs.insert(subject.lessonID)
        queueStudyReview(for: subject)
    }

    func recordReview(for subject: Subject) {
        queueStudyReview(for: subject)
    }

    func isReviewDue(_ subject: Subject) -> Bool {
        guard let dueDate = studyProgress[subject.lessonID]?.dueDate else { return false }
        return dueDate <= Date()
    }

    func hasPendingReview(_ subject: Subject) -> Bool {
        pendingStudyReviews.contains(where: { $0.lessonID == subject.lessonID })
    }

    var nextDueSubject: Subject? {
        let dueRecord = studyProgress.values
            .filter { ($0.dueDate ?? .distantFuture) <= Date() }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first
        guard let lessonID = dueRecord?.lessonID else { return nil }
        return Subject.allCases.first(where: { $0.lessonID == lessonID })
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
                if record.completed,
                   let subject = Subject.allCases.first(where: { $0.lessonID == event.lessonID }) {
                    completedLessonIDs.insert(subject.lessonID)
                }
                pendingStudyReviews.removeAll(where: { $0.id == event.id })
            } catch {
                return
            }
        }

        do {
            let snapshot = try await OrchestratorClient.studyProgress()
            studyProgress = Dictionary(uniqueKeysWithValues: snapshot.records.map { ($0.lessonID, $0) })
            dueReviewCount = snapshot.records.filter { record in
                Subject.allCases.contains(where: { $0.lessonID == record.lessonID })
                    && (record.dueDate ?? .distantFuture) <= Date()
            }.count
            for subject in Subject.allCases where studyProgress[subject.lessonID]?.completed == true {
                completedLessonIDs.insert(subject.lessonID)
            }
        } catch {
            // Keep the local lesson state and queued review events while the backend is offline.
        }
    }

    var completedSubjectCount: Int {
        Subject.allCases.filter(isComplete).count
    }

    private func queueStudyReview(for subject: Subject) {
        guard !hasPendingReview(subject) else { return }
        pendingStudyReviews.append(StudyReviewEvent(
            id: UUID().uuidString.lowercased(),
            lessonID: subject.lessonID,
            quality: 4
        ))
        Task { await syncStudyProgress() }
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
    let ollamaEndpointLocal: Bool?
    let obsidianEndpointLocal: Bool?
    let sessionMode: String?
    let sessionCurrent: Int?
    let sessionMax: Int?
    let knowledgeDocumentCount: Int?
    let knowledgeIndexCheckedAt: String?

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
    var hasAutomaticRoute: Bool { hasCloudSession || hasLocalModel }

    enum CodingKeys: String, CodingKey {
        case status, online, provider
        case ollamaAvailable = "ollama_available"
        case ollamaModel = "ollama_model"
        case ollamaEmbeddingModel = "ollama_embedding_model"
        case ollamaModelReady = "ollama_model_ready"
        case geminiKeyConfigured = "gemini_key_configured"
        case ollamaEndpointLocal = "ollama_endpoint_local"
        case obsidianEndpointLocal = "obsidian_endpoint_local"
        case sessionMode = "session_mode"
        case sessionCurrent = "session_current"
        case sessionMax = "session_max"
        case knowledgeDocumentCount = "knowledge_document_count"
        case knowledgeIndexCheckedAt = "knowledge_index_checked_at"
    }
}

struct ProviderSecretStatus: Decodable, Identifiable {
    let provider: String
    let configured: Bool
    let source: String

    var id: String { provider }
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
    let language: String
    let mode: String
    let retrievalQuery: String
    let useWebSearch: Bool
    let groundingAgeConfirmed: Bool

    enum CodingKeys: String, CodingKey {
        case message, language, mode
        case systemPrompt = "system_prompt"
        case retrievalQuery = "retrieval_query"
        case useWebSearch = "use_web_search"
        case groundingAgeConfirmed = "grounding_age_confirmed"
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
    let sourceType: String?

    enum CodingKeys: String, CodingKey {
        case id, title, excerpt
        case retrievedAt = "retrieved_at"
        case path, location
        case modifiedAt = "modified_at"
        case sourceType = "source_type"
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

private struct TutorEvent: Decodable {
    let type: String
    let content: String?
    let provider: String?
    let model: String?
    let durationMS: Int?
    let sources: [TutorSource]?
    let googleSearchSuggestions: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case type, content, provider, model, sources, error
        case durationMS = "duration_ms"
        case googleSearchSuggestions = "google_search_suggestions"
    }
}

struct TutorCompletion {
    let provider: String
    let model: String
    let durationMS: Int
    let sources: [TutorSource]
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
        language: AppLanguage,
        mode: AIRoutingMode,
        useWebSearch: Bool = false,
        groundingAgeConfirmed: Bool = false,
        onToken: @MainActor (String) -> Void
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
            language: language.rawValue,
            mode: mode.rawValue,
            retrievalQuery: retrievalQuery,
            useWebSearch: useWebSearch,
            groundingAgeConfirmed: groundingAgeConfirmed
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
                completion = TutorCompletion(
                    provider: event.provider ?? "AI",
                    model: event.model ?? "",
                    durationMS: event.durationMS ?? 0,
                    sources: event.sources ?? [],
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
    var googleSearchSuggestions: String? = nil
    var isGoogleGrounded = false
}

@MainActor
final class TutorChatModel: ObservableObject {
    @Published private(set) var messages: [TutorMessage] = []
    @Published private(set) var isSending = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var completionLabel: String?
    private var requestTask: Task<Void, Never>?

    let subject: Subject
    let lesson: LessonContent
    let language: AppLanguage
    let mode: AIRoutingMode

    init(subject: Subject, lesson: LessonContent, language: AppLanguage, mode: AIRoutingMode) {
        self.subject = subject
        self.lesson = lesson
        self.language = language
        self.mode = mode
    }

    func send(
        _ rawText: String,
        useWebSearch: Bool = false,
        groundingAgeConfirmed: Bool = false
    ) {
        let question = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isSending else { return }

        errorMessage = nil
        completionLabel = nil
        messages.append(TutorMessage(role: .learner, text: question))
        let reply = TutorMessage(role: .tutor, text: "")
        messages.append(reply)
        isSending = true

        let subjectName = subject.title(in: language)
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
                    language: language,
                    mode: mode,
                    useWebSearch: useWebSearch,
                    groundingAgeConfirmed: groundingAgeConfirmed,
                    onToken: { [weak self] token in self?.append(token, to: reply.id) }
                )
                completionLabel = [result.provider, result.model].filter { !$0.isEmpty }.joined(separator: " · ")
                if let index = messages.firstIndex(where: { $0.id == reply.id }) {
                    messages[index].sources = result.sources
                    messages[index].googleSearchSuggestions = result.googleSearchSuggestions
                    messages[index].isGoogleGrounded = result.googleSearchSuggestions != nil
                }
            } catch is CancellationError {
                // Keep a partial answer visible when the learner stops generation.
            } catch OrchestratorClient.ClientError.serverError(let message) {
                errorMessage = message
            } catch {
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
}

enum AppSection: Hashable {
    case today
    case subjects
    case subject(Subject)
    case lesson(Subject)
    case settings
}
