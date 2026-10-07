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

        precondition(curriculum.removeTopic(subjectID: astronomy, topicID: orbits))
        precondition(curriculum.subject(id: astronomy)?.topics.isEmpty == true)
        print("Custom curriculum checks passed. / Проверки пользовательских курсов прошли.")
    }
}
