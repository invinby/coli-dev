import Foundation

@main
enum CustomCurriculumVerification {
    static func main() throws {
        let biology = CustomCurriculumText(russian: "Биология", english: "Biology")
        var curriculum = CustomCurriculum()

        do {
            _ = try curriculum.addSubject(
                name: biology,
                description: CustomCurriculumText(russian: "", english: ""),
                reservedNames: [biology]
            )
            preconditionFailure("A built-in subject must not be duplicated. / Нельзя дублировать встроенный предмет.")
        } catch CustomCurriculumError.duplicateSubjectName {
        }

        let astronomy = try curriculum.addSubject(
            name: CustomCurriculumText(russian: "Астрономия", english: "Astronomy"),
            description: CustomCurriculumText(russian: "Космос и небесные тела", english: "Space and celestial objects"),
            reservedNames: [biology]
        )
        precondition(curriculum.subject(id: astronomy)?.name.english == "Astronomy")

        let orbits = try curriculum.addTopic(
            subjectID: astronomy,
            parentTopicID: nil,
            name: CustomCurriculumText(russian: "Орбиты", english: "Orbits"),
            learningOutcome: CustomCurriculumText(russian: "Объяснять движение тел", english: "Explain how bodies move"),
            notes: CustomCurriculumText(russian: "", english: "")
        )
        let ellipses = try curriculum.addTopic(
            subjectID: astronomy,
            parentTopicID: orbits,
            name: CustomCurriculumText(russian: "Эллиптические орбиты", english: "Elliptical orbits"),
            learningOutcome: CustomCurriculumText(russian: "", english: ""),
            notes: CustomCurriculumText(russian: "Первый закон Кеплера", english: "Kepler's first law")
        )
        let builtInBiologyTopic = try curriculum.addTopic(
            builtInSubjectID: "biology",
            parentTopicID: nil,
            name: CustomCurriculumText(russian: "Моя тема по биологии", english: "My biology topic"),
            learningOutcome: CustomCurriculumText(russian: "Связать строение и функцию", english: "Connect structure and function"),
            notes: CustomCurriculumText(russian: "Мои заметки", english: "My notes"),
            level: 4
        )
        precondition(curriculum.subject(id: astronomy)?.name.english == "Astronomy")
        precondition(curriculum.topics(builtInSubjectID: "biology").count == 1)
        precondition(curriculum.topic(builtInSubjectID: "biology", topicID: builtInBiologyTopic)?.level == 4)

        let duplicate = CustomCurriculumText(russian: "Путь по окружности", english: "orbits")
        do {
            _ = try curriculum.addTopic(
                subjectID: astronomy,
                parentTopicID: nil,
                name: duplicate,
                learningOutcome: CustomCurriculumText(russian: "", english: ""),
                notes: CustomCurriculumText(russian: "", english: "")
            )
            preconditionFailure("Sibling topic names must be unique across both languages. / Названия тем одного уровня не должны дублироваться на обоих языках.")
        } catch CustomCurriculumError.duplicateTopicName {
        }

        do {
            _ = try curriculum.addTopic(
                subjectID: astronomy,
                parentTopicID: UUID(),
                name: CustomCurriculumText(russian: "Случайная тема", english: "Orphan topic"),
                learningOutcome: CustomCurriculumText(russian: "", english: ""),
                notes: CustomCurriculumText(russian: "", english: "")
            )
            preconditionFailure("A topic cannot be attached to a missing parent. / Нельзя добавить подтему к отсутствующей теме.")
        } catch CustomCurriculumError.parentTopicNotFound {
        }

        let encoded = try JSONEncoder().encode(curriculum)
        let restored = try JSONDecoder().decode(CustomCurriculum.self, from: encoded)
        precondition(restored == curriculum, "The locally saved curriculum must retain its stable IDs and hierarchy. / Локальное сохранение должно сохранять ID и вложенность.")
        precondition(restored.topic(subjectID: astronomy, topicID: ellipses)?.name.russian == "Эллиптические орбиты")
        precondition(restored.topic(builtInSubjectID: "biology", topicID: builtInBiologyTopic)?.name.english == "My biology topic")

        let russianOutlineRequest = CustomTopicStudyPrompt.outlineDraft(languageCode: "ru")
        for requiredIdea in ["черновик", "предпосыл", "подтем", "практик", "визуал", "источник", "не сохраняй", "неподтверж", "colidev.topic-outline.v1", "только json", "английское"] {
            precondition(
                russianOutlineRequest.localizedCaseInsensitiveContains(requiredIdea),
                "The Russian study-plan draft must request a sourced, structured outline without saving it automatically. Missing: \(requiredIdea)"
            )
        }
        let englishOutlineRequest = CustomTopicStudyPrompt.outlineDraft(languageCode: "en")
        for requiredIdea in ["draft", "prerequisite", "subtopic", "practice", "visual", "source", "do not save", "unsupported", "colidev.topic-outline.v1", "only json", "russian and english"] {
            precondition(
                englishOutlineRequest.localizedCaseInsensitiveContains(requiredIdea),
                "The English study-plan draft must request a sourced, structured outline without saving it automatically. Missing: \(requiredIdea)"
            )
        }

        let outlineJSON = #"""
        {
          "type": "colidev.topic-outline.v1",
          "version": 1,
          "topics": [
            {
              "name": {"russian": "Основы", "english": "Foundations"},
              "learningOutcome": {"russian": "Понимать основы", "english": "Understand the foundations"},
              "notes": {"russian": "Практика: сравнить примеры. Визуализация: схема.", "english": "Practice: compare examples. Visual: a diagram."},
              "level": 1,
              "subtopics": [
                {
                  "name": {"russian": "Первые понятия", "english": "First concepts"},
                  "learningOutcome": {"russian": "Объяснить понятия", "english": "Explain the concepts"},
                  "notes": {"russian": "Источник требует проверки.", "english": "Source needs review."},
                  "level": 2,
                  "subtopics": []
                }
              ]
            },
            {
              "name": {"russian": "Практика", "english": "Practice"},
              "learningOutcome": {"russian": "Применить знания", "english": "Apply the knowledge"},
              "notes": {"russian": "Решить новую задачу.", "english": "Solve a new problem."},
              "level": 2,
              "subtopics": []
            }
          ]
        }
        """#
        let outline = try CustomTopicOutlineProposal.parse(outlineJSON)
        precondition(outline.topics.count == 2)
        precondition(outline.topics[0].name.russian == "Основы")
        precondition(outline.topics[0].subtopics.first?.name.english == "First concepts")
        let fencedOutline = try CustomTopicOutlineProposal.parse("```json\n\(outlineJSON)\n```")
        precondition(fencedOutline.topics.first?.learningOutcome.english == "Understand the foundations")

        do {
            _ = try CustomTopicOutlineProposal.parse(outlineJSON.replacingOccurrences(of: "\"version\": 1", with: "\"version\": 2"))
            preconditionFailure("An unsupported outline schema version must be rejected. / Нужно отклонять неподдерживаемую версию схемы плана.")
        } catch CustomTopicOutlineError.unsupportedVersion {
        }

        do {
            _ = try CustomTopicOutlineProposal.parse(outlineJSON.replacingOccurrences(of: "\"english\": \"Foundations\"", with: "\"english\": \"\""))
            preconditionFailure("A topic without a complete English title must not be importable. / Нельзя импортировать тему без английского названия.")
        } catch CustomTopicOutlineError.invalidBilingualContent {
        }

        do {
            _ = try CustomTopicOutlineProposal.parse(outlineJSON.replacingOccurrences(
                of: "\"english\": \"Practice: compare examples. Visual: a diagram.\"",
                with: "\"english\": \"\""
            ))
            preconditionFailure("Notes must have a full Russian and English version. / Заметки должны содержать полный текст на русском и английском.")
        } catch CustomTopicOutlineError.invalidBilingualContent {
        }

        do {
            _ = try CustomTopicOutlineProposal.parse(outlineJSON.replacingOccurrences(of: "\"level\": 1", with: "\"level\": 8"))
            preconditionFailure("An outline level outside the supported range must be rejected. / Уровень вне допустимого диапазона нужно отклонять.")
        } catch CustomTopicOutlineError.invalidLevel {
        }

        do {
            _ = try CustomTopicOutlineProposal.parse(outlineJSON.replacingOccurrences(
                of: "\"name\": {\"russian\": \"Практика\", \"english\": \"Practice\"}",
                with: "\"name\": {\"russian\": \"Практика\", \"english\": \"Foundations\"}"
            ))
            preconditionFailure("Sibling names must be unique across both languages. / Названия соседних тем не должны повторяться ни на одном языке.")
        } catch CustomTopicOutlineError.duplicateSiblingName {
        }

        do {
            _ = try CustomTopicOutlineProposal.parse("Plan draft:\n\(outlineJSON)")
            preconditionFailure("Prose around an outline must not be parsed as structured curriculum data. / Пояснительный текст вокруг плана нельзя импортировать как структуру курса.")
        } catch CustomTopicOutlineError.malformedJSON {
        }

        do {
            _ = try CustomTopicOutlineProposal.parse(String(repeating: "x", count: 65 * 1024))
            preconditionFailure("Oversized model output must be rejected before decoding. / Слишком большой ответ модели нужно отклонять до разбора.")
        } catch CustomTopicOutlineError.oversizedResponse {
        }

        var targetCurriculum = CustomCurriculum()
        let targetSubject = try targetCurriculum.addSubject(
            name: CustomCurriculumText(russian: "Астрономия", english: "Astronomy"),
            description: CustomCurriculumText(russian: "", english: ""),
            reservedNames: [biology]
        )
        let targetParent = try targetCurriculum.addTopic(
            subjectID: targetSubject,
            parentTopicID: nil,
            name: CustomCurriculumText(russian: "Моя тема", english: "My topic"),
            learningOutcome: CustomCurriculumText(russian: "", english: ""),
            notes: CustomCurriculumText(russian: "", english: "")
        )
        _ = try targetCurriculum.addTopic(
            subjectID: targetSubject,
            parentTopicID: targetParent,
            name: CustomCurriculumText(russian: "Практика", english: "Practice"),
            learningOutcome: CustomCurriculumText(russian: "", english: ""),
            notes: CustomCurriculumText(russian: "", english: "")
        )
        let beforeRejectedOutline = targetCurriculum
        do {
            _ = try targetCurriculum.addOutline(
                outline.topics,
                to: .learnerSubject(subjectID: targetSubject),
                parentTopicID: targetParent
            )
            preconditionFailure("A conflicting outline must be rejected without saving any earlier outline topics. / Конфликтующий план нужно отклонить целиком без частичного сохранения.")
        } catch CustomCurriculumError.duplicateTopicName {
        }
        precondition(targetCurriculum == beforeRejectedOutline, "Outline import must be atomic. / Импорт плана должен быть атомарным.")

        let savedIDs = try targetCurriculum.addOutline(
            outline.topics,
            to: .builtInSubject(subjectID: "biology"),
            parentTopicID: builtInBiologyTopic
        )
        precondition(savedIDs.count == 3)
        precondition(targetCurriculum.topic(builtInSubjectID: "biology", topicID: savedIDs[0])?.subtopics.first?.name.russian == "Первые понятия")

        precondition(curriculum.removeTopic(subjectID: astronomy, topicID: orbits))
        precondition(curriculum.subject(id: astronomy)?.topics.isEmpty == true)
        precondition(curriculum.removeTopic(builtInSubjectID: "biology", topicID: builtInBiologyTopic))
        precondition(curriculum.topics(builtInSubjectID: "biology").isEmpty)
        let preexisting = try JSONDecoder().decode(CustomCurriculum.self, from: Data(#"{"subjects":[]}"#.utf8))
        precondition(preexisting.subjects.isEmpty && preexisting.builtInTopics.isEmpty)
        print("Custom curriculum checks passed. / Проверки пользовательских курсов прошли.")
    }
}
