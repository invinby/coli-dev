import Foundation

enum StudyFormatFeedbackChoice: String, CaseIterable, Codable, Equatable, Identifiable {
    case plainExplanation = "plain_explanation"
    case workedExample = "worked_example"
    case visualModel = "visual_model"
    case interactivePractice = "interactive_practice"
    case recallQuestion = "recall_question"
    case notSureYet = "not_sure_yet"

    var id: String { rawValue }

    var titleKey: String {
        "studyFormat.choice.\(rawValue)"
    }

    var symbol: String {
        switch self {
        case .plainExplanation: "text.alignleft"
        case .workedExample: "list.number"
        case .visualModel: "cube"
        case .interactivePractice: "hand.draw"
        case .recallQuestion: "questionmark.bubble"
        case .notSureYet: "ellipsis.circle"
        }
    }

    func tutorGuidance(languageCode: String) -> String? {
        let isRussian = languageCode == "ru"
        let guidance: String
        switch self {
        case .plainExplanation:
            guidance = isRussian
                ? "Предпочтителен короткий ответ простыми словами, затем детали по запросу."
                : "Prefer a short plain-language explanation first, then details when requested."
        case .workedExample:
            guidance = isRussian
                ? "Когда это подходит, начни с небольшого разобранного примера и поясни каждый шаг."
                : "When it fits, start with a small worked example and explain each step."
        case .visualModel:
            guidance = isRussian
                ? "Когда это подходит, помоги представить идею схемой, пространственным описанием или наглядной аналогией; не утверждай, что создал изображение или 3D-модель."
                : "When it fits, make the idea easier to picture with a diagram, spatial description, or visual analogy; do not claim to have created an image or 3D model."
        case .interactivePractice:
            guidance = isRussian
                ? "Когда это подходит, предложи одно короткое действие или прогноз до объяснения результата."
                : "When it fits, offer one brief action or prediction before explaining the result."
        case .recallQuestion:
            guidance = isRussian
                ? "Когда это подходит, предложи один необязательный вопрос на воспоминание, затем спокойно разбери ответ."
                : "When it fits, offer one optional retrieval question, then calmly discuss the answer."
        case .notSureYet:
            return nil
        }
        return guidance
    }
}

enum StudyFormatTutorPrompt {
    static func note(for choice: StudyFormatFeedbackChoice, languageCode: String) -> String? {
        guard let guidance = choice.tutorGuidance(languageCode: languageCode) else { return nil }
        if languageCode == "ru" {
            return "Формат, который ученик явно отмечал полезным в нескольких уроках: \(guidance) Используй его, когда он уместен; оставайся гибким и ставь точность выше предпочтения."
        }
        return "Format the learner explicitly selected as helpful across several lessons: \(guidance) Use it when appropriate, stay flexible, and prioritize accuracy over preference."
    }
}

struct StudyFormatPreferenceResponse: Codable, Equatable {
    let lessonID: String
    let subjectID: String?
    let choice: StudyFormatFeedbackChoice
    let recordedAt: Date

    enum CodingKeys: String, CodingKey {
        case lessonID = "lesson_id"
        case subjectID = "subject_id"
        case choice
        case recordedAt = "recorded_at"
    }
}

private struct StudyFormatPreferenceLessonKey: Hashable {
    let lessonID: String
    let subjectID: String?
}

struct StudyFormatPreferenceProfile: Codable, Equatable {
    static let maximumStoredResponses = 50
    private static let minimumLessonResponses = 3

    private(set) var responses: [StudyFormatPreferenceResponse]

    init(responses: [StudyFormatPreferenceResponse] = []) {
        var latestByLesson: [StudyFormatPreferenceLessonKey: StudyFormatPreferenceResponse] = [:]
        for response in responses {
            let lessonID = response.lessonID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !lessonID.isEmpty, lessonID.count <= 120 else { continue }
            let subjectID = response.subjectID?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard response.subjectID == nil || subjectID.map({ !$0.isEmpty && $0.count <= 120 }) == true else { continue }
            let normalized = StudyFormatPreferenceResponse(
                lessonID: lessonID,
                subjectID: subjectID,
                choice: response.choice,
                recordedAt: response.recordedAt
            )
            let key = StudyFormatPreferenceLessonKey(lessonID: lessonID, subjectID: subjectID)
            if let previous = latestByLesson[key], previous.recordedAt > normalized.recordedAt {
                continue
            }
            latestByLesson[key] = normalized
        }
        self.responses = Array(latestByLesson.values.sorted {
            $0.recordedAt < $1.recordedAt
        }.suffix(Self.maximumStoredResponses))
    }

    mutating func record(
        _ choice: StudyFormatFeedbackChoice,
        for lessonID: String,
        subjectID: String? = nil,
        at recordedAt: Date = Date()
    ) {
        let normalizedLessonID = lessonID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedLessonID.isEmpty, normalizedLessonID.count <= 120 else { return }
        let normalizedSubjectID = subjectID?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard subjectID == nil || normalizedSubjectID.map({ !$0.isEmpty && $0.count <= 120 }) == true else { return }
        responses.removeAll {
            $0.lessonID == normalizedLessonID
                && ($0.subjectID == normalizedSubjectID || $0.subjectID == nil)
        }
        responses.append(StudyFormatPreferenceResponse(
            lessonID: normalizedLessonID,
            subjectID: normalizedSubjectID,
            choice: choice,
            recordedAt: recordedAt
        ))
        responses.sort { $0.recordedAt < $1.recordedAt }
        if responses.count > Self.maximumStoredResponses {
            responses.removeFirst(responses.count - Self.maximumStoredResponses)
        }
    }

    mutating func clear() {
        responses.removeAll(keepingCapacity: false)
    }

    func selectedChoice(for lessonID: String) -> StudyFormatFeedbackChoice? {
        responses.last(where: { $0.lessonID == lessonID })?.choice
    }

    func selectedChoice(for lessonID: String, subjectID: String) -> StudyFormatFeedbackChoice? {
        responses.last(where: { $0.lessonID == lessonID && $0.subjectID == subjectID })?.choice
    }

    var mostFrequentlyHelpful: StudyFormatFeedbackChoice? {
        mostFrequentlyHelpful(in: responses.filter { $0.subjectID == nil })
    }

    func mostFrequentlyHelpful(forSubjectID subjectID: String) -> StudyFormatFeedbackChoice? {
        let normalizedSubjectID = subjectID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSubjectID.isEmpty, normalizedSubjectID.count <= 120 else { return nil }
        return mostFrequentlyHelpful(in: responses.filter { $0.subjectID == normalizedSubjectID })
    }

    func tutorPreference(forSubjectID subjectID: String) -> StudyFormatFeedbackChoice? {
        mostFrequentlyHelpful(forSubjectID: subjectID) ?? mostFrequentlyHelpful
    }

    private func mostFrequentlyHelpful(
        in responses: [StudyFormatPreferenceResponse]
    ) -> StudyFormatFeedbackChoice? {
        let counts = responses.reduce(into: [StudyFormatFeedbackChoice: Int]()) { result, response in
            guard response.choice != .notSureYet else { return }
            result[response.choice, default: 0] += 1
        }
        guard let highest = counts.values.max(), highest >= Self.minimumLessonResponses else { return nil }
        let leaders = counts.filter { $0.value == highest }
        guard leaders.count == 1 else { return nil }
        return leaders.first?.key
    }

    enum CodingKeys: String, CodingKey {
        case responses
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(responses: try container.decode([StudyFormatPreferenceResponse].self, forKey: .responses))
    }
}
