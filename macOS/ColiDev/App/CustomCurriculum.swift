import Foundation

struct CustomCurriculumText: Codable, Equatable {
    var russian: String
    var english: String

    func value(in languageCode: String) -> String {
        let preferred = languageCode == "ru" ? russian : english
        let alternate = languageCode == "ru" ? english : russian
        let cleaned = preferred.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? alternate.trimmingCharacters(in: .whitespacesAndNewlines) : cleaned
    }

    fileprivate var trimmed: CustomCurriculumText {
        CustomCurriculumText(
            russian: russian.trimmingCharacters(in: .whitespacesAndNewlines),
            english: english.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    fileprivate var normalizedValues: Set<String> {
        [russian, english]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")) }
            .reduce(into: Set<String>()) { $0.insert($1) }
    }

    fileprivate var hasBothLanguages: Bool {
        !russian.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct CustomLearningTopic: Codable, Identifiable, Equatable {
    var id: UUID
    var name: CustomCurriculumText
    var learningOutcome: CustomCurriculumText
    var notes: CustomCurriculumText
    var level: Int
    var subtopics: [CustomLearningTopic]

    init(
        id: UUID = UUID(),
        name: CustomCurriculumText,
        learningOutcome: CustomCurriculumText,
        notes: CustomCurriculumText,
        level: Int = 1,
        subtopics: [CustomLearningTopic] = []
    ) {
        self.id = id
        self.name = name
        self.learningOutcome = learningOutcome
        self.notes = notes
        self.level = min(max(level, 1), 7)
        self.subtopics = subtopics
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, learningOutcome, notes, level, subtopics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(CustomCurriculumText.self, forKey: .name)
        learningOutcome = try container.decodeIfPresent(CustomCurriculumText.self, forKey: .learningOutcome)
            ?? CustomCurriculumText(russian: "", english: "")
        notes = try container.decodeIfPresent(CustomCurriculumText.self, forKey: .notes)
            ?? CustomCurriculumText(russian: "", english: "")
        level = min(max(try container.decodeIfPresent(Int.self, forKey: .level) ?? 1, 1), 7)
        subtopics = try container.decodeIfPresent([CustomLearningTopic].self, forKey: .subtopics) ?? []
    }

    var totalTopicCount: Int {
        1 + subtopics.reduce(0) { $0 + $1.totalTopicCount }
    }
}

struct CustomLearningSubject: Codable, Identifiable, Equatable {
    var id: UUID
    var name: CustomCurriculumText
    var description: CustomCurriculumText
    var topics: [CustomLearningTopic]

    init(
        id: UUID = UUID(),
        name: CustomCurriculumText,
        description: CustomCurriculumText,
        topics: [CustomLearningTopic] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.topics = topics
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, topics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(CustomCurriculumText.self, forKey: .name)
        description = try container.decodeIfPresent(CustomCurriculumText.self, forKey: .description)
            ?? CustomCurriculumText(russian: "", english: "")
        topics = try container.decodeIfPresent([CustomLearningTopic].self, forKey: .topics) ?? []
    }

    var totalTopicCount: Int {
        topics.reduce(0) { $0 + $1.totalTopicCount }
    }
}

enum CustomCurriculumError: Error, Equatable {
    case missingSubjectName
    case duplicateSubjectName
    case missingTopicName
    case duplicateTopicName
    case subjectNotFound
    case parentTopicNotFound
}

struct CustomCurriculum: Codable, Equatable {
    var subjects: [CustomLearningSubject] = []
    var builtInTopics: [String: [CustomLearningTopic]] = [:]

    private enum CodingKeys: String, CodingKey {
        case subjects
        case builtInTopics
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subjects = try container.decodeIfPresent([CustomLearningSubject].self, forKey: .subjects) ?? []
        builtInTopics = try container.decodeIfPresent([String: [CustomLearningTopic]].self, forKey: .builtInTopics) ?? [:]
    }

    @discardableResult
    mutating func addSubject(
        name: CustomCurriculumText,
        description: CustomCurriculumText,
        reservedNames: [CustomCurriculumText]
    ) throws -> UUID {
        let name = name.trimmed
        let description = description.trimmed
        guard name.hasBothLanguages else { throw CustomCurriculumError.missingSubjectName }
        let normalized = name.normalizedValues
        let reserved = reservedNames.reduce(into: Set<String>()) { $0.formUnion($1.normalizedValues) }
        let existing = subjects.reduce(into: Set<String>()) { $0.formUnion($1.name.normalizedValues) }
        guard normalized.isDisjoint(with: reserved.union(existing)) else {
            throw CustomCurriculumError.duplicateSubjectName
        }

        let subject = CustomLearningSubject(name: name, description: description)
        subjects.append(subject)
        return subject.id
    }

    func subject(id: UUID) -> CustomLearningSubject? {
        subjects.first { $0.id == id }
    }

    @discardableResult
    mutating func addTopic(
        subjectID: UUID,
        parentTopicID: UUID?,
        name: CustomCurriculumText,
        learningOutcome: CustomCurriculumText,
        notes: CustomCurriculumText,
        level: Int = 1
    ) throws -> UUID {
        guard let subjectIndex = subjects.firstIndex(where: { $0.id == subjectID }) else {
            throw CustomCurriculumError.subjectNotFound
        }
        return try Self.insertTopic(
            name: name,
            learningOutcome: learningOutcome,
            notes: notes,
            level: level,
            parentTopicID: parentTopicID,
            into: &subjects[subjectIndex].topics
        )
    }

    @discardableResult
    mutating func addTopic(
        builtInSubjectID: String,
        parentTopicID: UUID?,
        name: CustomCurriculumText,
        learningOutcome: CustomCurriculumText,
        notes: CustomCurriculumText,
        level: Int = 1
    ) throws -> UUID {
        let availableSubjects: Set<String> = ["mathematics", "english", "physics", "biology", "zoology", "programming"]
        guard availableSubjects.contains(builtInSubjectID) else { throw CustomCurriculumError.subjectNotFound }
        var topics = builtInTopics[builtInSubjectID] ?? []
        let id = try Self.insertTopic(
            name: name,
            learningOutcome: learningOutcome,
            notes: notes,
            level: level,
            parentTopicID: parentTopicID,
            into: &topics
        )
        builtInTopics[builtInSubjectID] = topics
        return id
    }

    func topic(subjectID: UUID, topicID: UUID) -> CustomLearningTopic? {
        guard let subject = subject(id: subjectID) else { return nil }
        guard let index = Self.topicIndex(id: topicID, in: subject.topics) else { return nil }
        return Self.topics(at: index, in: subject.topics)
    }

    func topics(builtInSubjectID: String) -> [CustomLearningTopic] {
        builtInTopics[builtInSubjectID] ?? []
    }

    func topicCount(builtInSubjectID: String) -> Int {
        topics(builtInSubjectID: builtInSubjectID).reduce(0) { $0 + $1.totalTopicCount }
    }

    func topic(builtInSubjectID: String, topicID: UUID) -> CustomLearningTopic? {
        let topics = self.topics(builtInSubjectID: builtInSubjectID)
        guard let index = Self.topicIndex(id: topicID, in: topics) else { return nil }
        return Self.topics(at: index, in: topics)
    }

    @discardableResult
    mutating func removeTopic(subjectID: UUID, topicID: UUID) -> Bool {
        guard let subjectIndex = subjects.firstIndex(where: { $0.id == subjectID }) else { return false }
        return Self.removeTopic(id: topicID, from: &subjects[subjectIndex].topics)
    }

    @discardableResult
    mutating func removeTopic(builtInSubjectID: String, topicID: UUID) -> Bool {
        guard var topics = builtInTopics[builtInSubjectID], Self.removeTopic(id: topicID, from: &topics) else {
            return false
        }
        builtInTopics[builtInSubjectID] = topics
        return true
    }

    @discardableResult
    mutating func removeSubject(id: UUID) -> Bool {
        guard let index = subjects.firstIndex(where: { $0.id == id }) else { return false }
        subjects.remove(at: index)
        return true
    }

    private static func topicIndex(id: UUID, in topics: [CustomLearningTopic]) -> [Int]? {
        for (index, topic) in topics.enumerated() {
            if topic.id == id { return [index] }
            if let childPath = topicIndex(id: id, in: topic.subtopics) { return [index] + childPath }
        }
        return nil
    }

    private static func insertTopic(
        name: CustomCurriculumText,
        learningOutcome: CustomCurriculumText,
        notes: CustomCurriculumText,
        level: Int,
        parentTopicID: UUID?,
        into topics: inout [CustomLearningTopic]
    ) throws -> UUID {
        let name = name.trimmed
        let learningOutcome = learningOutcome.trimmed
        let notes = notes.trimmed
        guard name.hasBothLanguages else { throw CustomCurriculumError.missingTopicName }
        var siblingTopics: [CustomLearningTopic]
        if let parentTopicID {
            guard let parentIndex = topicIndex(id: parentTopicID, in: topics) else {
                throw CustomCurriculumError.parentTopicNotFound
            }
            siblingTopics = self.topics(at: parentIndex, in: topics).subtopics
        } else {
            siblingTopics = topics
        }
        let normalized = name.normalizedValues
        let existing = siblingTopics.reduce(into: Set<String>()) { $0.formUnion($1.name.normalizedValues) }
        guard normalized.isDisjoint(with: existing) else { throw CustomCurriculumError.duplicateTopicName }

        let topic = CustomLearningTopic(name: name, learningOutcome: learningOutcome, notes: notes, level: level)
        if let parentTopicID {
            mutateTopic(id: parentTopicID, in: &topics) { $0.subtopics.append(topic) }
        } else {
            topics.append(topic)
        }
        return topic.id
    }

    private static func topics(at path: [Int], in topics: [CustomLearningTopic]) -> CustomLearningTopic {
        let topic = topics[path[0]]
        guard path.count > 1 else { return topic }
        return self.topics(at: Array(path.dropFirst()), in: topic.subtopics)
    }

    private static func mutateTopic(id: UUID, in topics: inout [CustomLearningTopic], mutation: (inout CustomLearningTopic) -> Void) {
        guard let index = topics.firstIndex(where: { $0.id == id }) else {
            for index in topics.indices {
                mutateTopic(id: id, in: &topics[index].subtopics, mutation: mutation)
            }
            return
        }
        mutation(&topics[index])
    }

    private static func removeTopic(id: UUID, from topics: inout [CustomLearningTopic]) -> Bool {
        if let index = topics.firstIndex(where: { $0.id == id }) {
            topics.remove(at: index)
            return true
        }
        for index in topics.indices where removeTopic(id: id, from: &topics[index].subtopics) {
            return true
        }
        return false
    }
}
