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
        for requiredIdea in ["черновик", "предпосыл", "подтем", "упражнен", "визуал", "источник", "не сохраняй"] {
            precondition(
                russianOutlineRequest.localizedCaseInsensitiveContains(requiredIdea),
                "The Russian study-plan draft must request a sourced, structured outline without saving it automatically. Missing: \(requiredIdea)"
            )
        }
        let englishOutlineRequest = CustomTopicStudyPrompt.outlineDraft(languageCode: "en")
        for requiredIdea in ["draft", "prerequisite", "subtopic", "exercise", "visual", "source", "do not save"] {
            precondition(
                englishOutlineRequest.localizedCaseInsensitiveContains(requiredIdea),
                "The English study-plan draft must request a sourced, structured outline without saving it automatically. Missing: \(requiredIdea)"
            )
        }

        precondition(curriculum.removeTopic(subjectID: astronomy, topicID: orbits))
        precondition(curriculum.subject(id: astronomy)?.topics.isEmpty == true)
        precondition(curriculum.removeTopic(builtInSubjectID: "biology", topicID: builtInBiologyTopic))
        precondition(curriculum.topics(builtInSubjectID: "biology").isEmpty)
        let preexisting = try JSONDecoder().decode(CustomCurriculum.self, from: Data(#"{"subjects":[]}"#.utf8))
        precondition(preexisting.subjects.isEmpty && preexisting.builtInTopics.isEmpty)
        print("Custom curriculum checks passed. / Проверки пользовательских курсов прошли.")
    }
}
