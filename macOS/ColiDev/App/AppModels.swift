import SwiftUI

// The first client slice uses a small, explicit local catalog. Provider/API
// integration stays behind a later service boundary so offline lessons work now.
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

    init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "colidev.language")
        language = AppLanguage(rawValue: savedLanguage ?? "") ?? .ru
        completedLessonIDs = Set(UserDefaults.standard.stringArray(forKey: "colidev.completedLessons") ?? [])
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

enum AppSection: Hashable {
    case today
    case subjects
    case subject(Subject)
    case settings
}
