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
            question: L10n.text("\(key).question", language),
            options: (0..<3).map { L10n.text("\(key).option\($0)", language) },
            answerIndex: Int(L10n.text("\(key).answer", language)) ?? 0,
            feedback: L10n.text("\(key).feedback", language)
        )
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

    func isComplete(_ subject: Subject) -> Bool {
        completedLessonIDs.contains(subject.lessonID)
    }

    func markComplete(_ subject: Subject) {
        completedLessonIDs.insert(subject.lessonID)
    }

    var completedSubjectCount: Int {
        Subject.allCases.filter(isComplete).count
    }
}

struct OrchestratorHealth: Decodable {
    let status: String
    let online: Bool
    let provider: String
    let ollamaAvailable: Bool
    let ollamaModel: String
    let ollamaModelReady: Bool?
    let sessionMode: String?
    let sessionCurrent: Int?
    let sessionMax: Int?

    var hasLocalModel: Bool { ollamaAvailable && (ollamaModelReady ?? false) }
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
        case ollamaModelReady = "ollama_model_ready"
        case sessionMode = "session_mode"
        case sessionCurrent = "session_current"
        case sessionMax = "session_max"
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

    enum CodingKeys: String, CodingKey {
        case message, language, mode
        case systemPrompt = "system_prompt"
    }
}

private struct TutorEvent: Decodable {
    let type: String
    let content: String?
    let provider: String?
    let model: String?
    let durationMS: Int?

    enum CodingKeys: String, CodingKey {
        case type, content, provider, model
        case durationMS = "duration_ms"
    }
}

struct TutorCompletion {
    let provider: String
    let model: String
    let durationMS: Int
}

@MainActor
enum OrchestratorClient {
    enum ClientError: Error {
        case invalidResponse
        case unavailable
        case serverError
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

    static func streamChat(
        message: String,
        systemPrompt: String,
        language: AppLanguage,
        mode: AIRoutingMode,
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
            mode: mode.rawValue
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
                throw ClientError.serverError
            case "done":
                completion = TutorCompletion(
                    provider: event.provider ?? "AI",
                    model: event.model ?? "",
                    durationMS: event.durationMS ?? 0
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

    func send(_ rawText: String) {
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
            Материал урока: \(lesson.explanation)
            Отвечай по-русски. Объясняй ясно и по шагам, подбирай глубину к вопросу. Помогай разобраться вопросами и подсказками; не выдавай решение задания сразу, если ученик просит научить. Не выдумывай источники и текущие факты.
            """
        } else {
            systemPrompt = """
            You are a thoughtful learning tutor. Subject: \(subjectName). Lesson: \(lesson.title).
            Goal: \(lesson.objective)
            Lesson material: \(lesson.explanation)
            Answer in English. Explain clearly in steps at the learner's level. Use questions and hints to build understanding; do not immediately give away an exercise solution when the learner asks to learn. Do not invent sources or current facts.
            """
        }

        let recentConversation = messages.dropLast().suffix(12).map { message in
            let speaker = message.role == .learner
                ? (language == .ru ? "Ученик" : "Learner")
                : (language == .ru ? "Тьютор" : "Tutor")
            return "\(speaker): \(message.text.prefix(1600))"
        }.joined(separator: "\n")
        let requestMessage = recentConversation.isEmpty ? question : recentConversation

        requestTask = Task {
            do {
                let result = try await OrchestratorClient.streamChat(
                    message: requestMessage,
                    systemPrompt: systemPrompt,
                    language: language,
                    mode: mode,
                    onToken: { [weak self] token in self?.append(token, to: reply.id) }
                )
                completionLabel = [result.provider, result.model].filter { !$0.isEmpty }.joined(separator: " · ")
            } catch is CancellationError {
                // Keep a partial answer visible when the learner stops generation.
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
    case settings
}
