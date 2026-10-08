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

enum CustomTopicOutlineError: Error, Equatable {
    case malformedJSON
    case unsupportedSchema
    case unsupportedVersion
    case invalidBilingualContent
    case invalidLevel
    case duplicateSiblingName
    case emptyTopics
    case tooManyTopics
    case tooDeep
    case oversizedResponse
}

enum CustomTopicOutlineDestination: Equatable {
    case learnerSubject(subjectID: UUID)
    case builtInSubject(subjectID: String)
}

struct CustomTopicOutlineProposal: Equatable {
    let topics: [CustomTopicOutlineItem]

    static func parse(_ response: String) throws -> CustomTopicOutlineProposal {
        guard response.utf8.count <= 64 * 1024 else {
            throw CustomTopicOutlineError.oversizedResponse
        }

        let json = try extractJSON(from: response)
        guard let data = json.data(using: .utf8) else {
            throw CustomTopicOutlineError.malformedJSON
        }
        let envelope: Envelope
        do {
            envelope = try JSONDecoder().decode(Envelope.self, from: data)
        } catch {
            throw CustomTopicOutlineError.malformedJSON
        }
        guard envelope.type == "colidev.topic-outline.v1" else {
            throw CustomTopicOutlineError.unsupportedSchema
        }
        guard envelope.version == 1 else {
            throw CustomTopicOutlineError.unsupportedVersion
        }
        let proposal = CustomTopicOutlineProposal(topics: envelope.topics)
        try proposal.validate()
        return proposal
    }

    func validate() throws {
        guard !topics.isEmpty else {
            throw CustomTopicOutlineError.emptyTopics
        }
        guard topics.count <= 8 else {
            throw CustomTopicOutlineError.tooManyTopics
        }

        var itemCount = 0
        try Self.validate(topics, depth: 1, parentLevel: nil, itemCount: &itemCount)
    }

    private struct Envelope: Decodable {
        let type: String
        let version: Int
        let topics: [CustomTopicOutlineItem]
    }

    private static func extractJSON(from response: String) throws -> String {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
            return trimmed
        }

        let lowercased = trimmed.lowercased()
        guard lowercased.hasPrefix("```json"), trimmed.hasSuffix("```") else {
            throw CustomTopicOutlineError.malformedJSON
        }
        let openingLength = "```json".count
        let body = String(trimmed.dropFirst(openingLength).dropLast(3))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard body.hasPrefix("{") && body.hasSuffix("}") else {
            throw CustomTopicOutlineError.malformedJSON
        }
        return body
    }

    private static func validate(
        _ topics: [CustomTopicOutlineItem],
        depth: Int,
        parentLevel: Int?,
        itemCount: inout Int
    ) throws {
        guard !topics.isEmpty else { return }
        guard depth <= 4 else { throw CustomTopicOutlineError.tooDeep }

        var siblingNames = Set<String>()
        for topic in topics {
            itemCount += 1
            guard itemCount <= 32 else { throw CustomTopicOutlineError.tooManyTopics }
            guard topic.name.hasBothLanguages,
                  topic.learningOutcome.hasBothLanguages,
                  topic.notes.hasBothLanguages,
                  topic.name.russian.count <= 120,
                  topic.name.english.count <= 120,
                  topic.learningOutcome.russian.count <= 500,
                  topic.learningOutcome.english.count <= 500,
                  topic.notes.russian.count <= 2_500,
                  topic.notes.english.count <= 2_500 else {
                throw CustomTopicOutlineError.invalidBilingualContent
            }
            guard (1...7).contains(topic.level) else {
                throw CustomTopicOutlineError.invalidLevel
            }
            if let parentLevel, topic.level < parentLevel {
                throw CustomTopicOutlineError.invalidLevel
            }
            for normalizedName in topic.name.normalizedValues {
                guard siblingNames.insert(normalizedName).inserted else {
                    throw CustomTopicOutlineError.duplicateSiblingName
                }
            }
            try validate(topic.subtopics, depth: depth + 1, parentLevel: topic.level, itemCount: &itemCount)
        }
    }
}

struct CustomTopicOutlineItem: Decodable, Identifiable, Equatable {
    let id: UUID
    var name: CustomCurriculumText
    var learningOutcome: CustomCurriculumText
    var notes: CustomCurriculumText
    var level: Int
    var subtopics: [CustomTopicOutlineItem]

    var totalTopicCount: Int {
        1 + subtopics.reduce(0) { $0 + $1.totalTopicCount }
    }

    private enum CodingKeys: String, CodingKey {
        case name, learningOutcome, notes, level, subtopics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        name = try container.decode(CustomCurriculumText.self, forKey: .name)
        learningOutcome = try container.decode(CustomCurriculumText.self, forKey: .learningOutcome)
        notes = try container.decode(CustomCurriculumText.self, forKey: .notes)
        level = try container.decode(Int.self, forKey: .level)
        subtopics = try container.decode([CustomTopicOutlineItem].self, forKey: .subtopics)
    }
}

struct CustomCurriculum: Codable, Equatable {
    private static let builtInSubjectIDs: Set<String> = [
        "mathematics", "english", "physics", "biology", "zoology", "programming"
    ]

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
        guard Self.builtInSubjectIDs.contains(builtInSubjectID) else { throw CustomCurriculumError.subjectNotFound }
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

    @discardableResult
    mutating func addOutline(
        _ items: [CustomTopicOutlineItem],
        to destination: CustomTopicOutlineDestination,
        parentTopicID: UUID
    ) throws -> [UUID] {
        try CustomTopicOutlineProposal(topics: items).validate()

        switch destination {
        case .learnerSubject(let subjectID):
            guard subject(id: subjectID) != nil else { throw CustomCurriculumError.subjectNotFound }
            guard topic(subjectID: subjectID, topicID: parentTopicID) != nil else {
                throw CustomCurriculumError.parentTopicNotFound
            }
        case .builtInSubject(let subjectID):
            guard Self.builtInSubjectIDs.contains(subjectID) else { throw CustomCurriculumError.subjectNotFound }
            guard topic(builtInSubjectID: subjectID, topicID: parentTopicID) != nil else {
                throw CustomCurriculumError.parentTopicNotFound
            }
        }

        var updated = self
        var insertedIDs: [UUID] = []

        func insert(_ topics: [CustomTopicOutlineItem], under parentID: UUID) throws {
            for item in topics {
                let id: UUID
                switch destination {
                case .learnerSubject(let subjectID):
                    id = try updated.addTopic(
                        subjectID: subjectID,
                        parentTopicID: parentID,
                        name: item.name,
                        learningOutcome: item.learningOutcome,
                        notes: item.notes,
                        level: item.level
                    )
                case .builtInSubject(let subjectID):
                    id = try updated.addTopic(
                        builtInSubjectID: subjectID,
                        parentTopicID: parentID,
                        name: item.name,
                        learningOutcome: item.learningOutcome,
                        notes: item.notes,
                        level: item.level
                    )
                }
                insertedIDs.append(id)
                try insert(item.subtopics, under: id)
            }
        }

        try insert(items, under: parentTopicID)
        self = updated
        return insertedIDs
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

enum CustomTopicStudyPrompt {
    static func outlineDraft(languageCode: String) -> String {
        if languageCode == "ru" {
            return "Составь черновик структуры подтем для текущего предмета и темы по её названию, цели, заметкам и доступным источникам. Начни с необходимых предпосылок и располагай материал от базового к углублённому. Верни только JSON по схеме colidev.topic-outline.v1 версии 1, без поясняющего текста и без Markdown-ограждений. Формат: {\"type\":\"colidev.topic-outline.v1\",\"version\":1,\"topics\":[{\"name\":{\"russian\":\"...\",\"english\":\"...\"},\"learningOutcome\":{\"russian\":\"...\",\"english\":\"...\"},\"notes\":{\"russian\":\"Практика: ...; Визуализация: ...; Источники: ...; Что требует проверки: ...\",\"english\":\"Practice: ...; Visual: ...; Sources: ...; Needs review: ...\"},\"level\":1,\"subtopics\":[]}]. У каждой темы и подтемы обязательны русское и английское название, цель, заметки и уровень от 1 до 7. В заметках для каждой темы укажи подходящий пример практики, полезный визуальный формат и только реальные источники из текущего контекста; если источник недоступен, прямо напиши, что его нужно проверить. Неподтверждённые утверждения явно помечай для проверки. Не выдумывай ссылки, цитаты или научные факты. Включи предпосылки первыми, затем основы и постепенное углубление. Не отмечай тему освоенной и ничего не сохраняй: результат должен быть черновиком для проверки учеником."
        }

        return "Draft a subtopic structure for the current subject and topic using its title, goal, notes, and available sources. Start with necessary prerequisites and order the material from foundational to advanced. Return only JSON using schema colidev.topic-outline.v1 version 1, with no explanatory prose and no Markdown fences. Format: {\"type\":\"colidev.topic-outline.v1\",\"version\":1,\"topics\":[{\"name\":{\"russian\":\"...\",\"english\":\"...\"},\"learningOutcome\":{\"russian\":\"...\",\"english\":\"...\"},\"notes\":{\"russian\":\"Практика: ...; Визуализация: ...; Источники: ...; Что требует проверки: ...\",\"english\":\"Practice: ...; Visual: ...; Sources: ...; Needs review: ...\"},\"level\":1,\"subtopics\":[]}]. Every topic and subtopic must include Russian and English names, learning outcomes, notes, and a level from 1 to 7. In its notes, include an appropriate practice example, useful visual format, and only real sources from the current context; if a source is unavailable, state that it needs review. Label unsupported claims clearly for review. Do not invent links, quotations, or scientific facts. Put prerequisites first, then foundations and progressively advanced work. Do not mark the topic mastered or save anything; the response is a draft for the learner to review."
    }
}
