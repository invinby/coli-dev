import Foundation

@main
enum StudyFormatPreferenceVerification {
    static func main() throws {
        var profile = StudyFormatPreferenceProfile()
        precondition(
            profile.mostFrequentlyHelpful == nil,
            "A new learner must not receive an inferred format preference before giving feedback. / Для нового ученика нельзя придумывать предпочтение формата до обратной связи."
        )

        profile.record(.workedExample, for: "mathematics.fractions", at: Date(timeIntervalSince1970: 1))
        profile.record(.workedExample, for: "physics.motion", at: Date(timeIntervalSince1970: 2))
        precondition(
            profile.mostFrequentlyHelpful == nil,
            "One or two explicit lesson choices must not be treated as an established preference. / Один или два явных ответа ещё не должны считаться устойчивым предпочтением."
        )
        profile.record(.workedExample, for: "programming.variables", at: Date(timeIntervalSince1970: 3))
        precondition(
            profile.mostFrequentlyHelpful == .workedExample,
            "The same explicitly helpful format across three different lessons should become the explainable preference. / Если один формат отмечен полезным в трёх разных уроках, он должен стать объяснимым предпочтением."
        )

        profile.record(.visualModel, for: "mathematics.fractions", at: Date(timeIntervalSince1970: 4))
        precondition(
            profile.selectedChoice(for: "mathematics.fractions") == .visualModel
                && profile.mostFrequentlyHelpful == nil,
            "Changing feedback for one lesson must replace its old vote rather than double-counting it. / Новая оценка того же урока должна заменить прежнюю, а не засчитаться вторым голосом."
        )

        profile.record(.notSureYet, for: "biology.cells", at: Date(timeIntervalSince1970: 5))
        precondition(
            profile.mostFrequentlyHelpful == nil,
            "Not-sure feedback must not be counted as support for a learning format. / Ответ «пока не уверен» не должен повышать рейтинг формата."
        )

        let guidance = StudyFormatTutorPrompt.note(for: .visualModel, languageCode: "ru")
        let englishGuidance = StudyFormatTutorPrompt.note(for: .visualModel, languageCode: "en")
        precondition(
            guidance?.contains("схемой") == true
                && guidance?.contains("точность") == true
                && englishGuidance?.localizedCaseInsensitiveContains("diagram") == true
                && englishGuidance?.localizedCaseInsensitiveContains("accuracy") == true
                && StudyFormatTutorPrompt.note(for: .notSureYet, languageCode: "ru") == nil,
            "Tutor instructions must honor a confirmed choice in both languages while staying flexible, accurate, and silent when the learner is unsure. / Подсказка тьютору должна учитывать подтверждённый выбор на обоих языках, сохранять гибкость и точность и отсутствовать, если ученик не уверен."
        )

        let restored = try JSONDecoder().decode(
            StudyFormatPreferenceProfile.self,
            from: JSONEncoder().encode(profile)
        )
        precondition(
            restored == profile
                && restored.selectedChoice(for: "biology.cells") == .notSureYet,
            "Explicit format feedback must persist through local Codable storage without duplication or data loss. / Явная обратная связь о формате должна сохраняться локально без потери данных и повторного подсчёта."
        )

        var subjectProfile = StudyFormatPreferenceProfile()
        for index in 0..<3 {
            subjectProfile.record(
                .workedExample,
                for: "mathematics.topic.\(index)",
                subjectID: "mathematics",
                at: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
        for index in 0..<2 {
            subjectProfile.record(
                .visualModel,
                for: "english.topic.\(index)",
                subjectID: "english",
                at: Date(timeIntervalSince1970: TimeInterval(index + 3))
            )
        }
        precondition(
            subjectProfile.mostFrequentlyHelpful(forSubjectID: "mathematics") == .workedExample
                && subjectProfile.mostFrequentlyHelpful(forSubjectID: "english") == nil
                && subjectProfile.tutorPreference(forSubjectID: "english") == nil,
            "A preference needs three distinct lessons within the same subject and cannot leak from mathematics into English. / Для предпочтения нужны три разных урока в одном предмете; математика не должна влиять на английский."
        )
        subjectProfile.record(
            .visualModel,
            for: "english.topic.2",
            subjectID: "english",
            at: Date(timeIntervalSince1970: 5)
        )
        precondition(
            subjectProfile.mostFrequentlyHelpful(forSubjectID: "english") == .visualModel
                && subjectProfile.mostFrequentlyHelpful == nil,
            "Different subjects may have distinct confirmed formats without manufacturing a global default. / У разных предметов могут быть разные подтверждённые форматы без выдуманного общего значения."
        )
        let restoredSubjectProfile = try JSONDecoder().decode(
            StudyFormatPreferenceProfile.self,
            from: JSONEncoder().encode(subjectProfile)
        )
        precondition(
            restoredSubjectProfile == subjectProfile
                && restoredSubjectProfile.mostFrequentlyHelpful(forSubjectID: "mathematics") == .workedExample
                && restoredSubjectProfile.mostFrequentlyHelpful(forSubjectID: "english") == .visualModel,
            "Subject-specific choices must remain correctly scoped after local persistence and restore. / Предпочтения должны оставаться привязаны к своим предметам после локального сохранения и восстановления."
        )

        var sharedLessonProfile = StudyFormatPreferenceProfile()
        sharedLessonProfile.record(.workedExample, for: "shared.lesson", subjectID: "mathematics")
        sharedLessonProfile.record(.visualModel, for: "shared.lesson", subjectID: "english")
        sharedLessonProfile.record(.plainExplanation, for: "shared.lesson", subjectID: "mathematics")
        precondition(
            sharedLessonProfile.responses.count == 2
                && sharedLessonProfile.selectedChoice(for: "shared.lesson", subjectID: "mathematics") == .plainExplanation
                && sharedLessonProfile.selectedChoice(for: "shared.lesson", subjectID: "english") == .visualModel,
            "Changing feedback in one subject must not replace another subject’s choice for a same-named lesson. / Изменение выбора в одном предмете не должно стирать выбор другого предмета для одноимённого урока."
        )

        var legacyGlobalProfile = StudyFormatPreferenceProfile()
        for index in 0..<3 {
            legacyGlobalProfile.record(
                .plainExplanation,
                for: "legacy.lesson.\(index)",
                at: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
        for index in 0..<3 {
            legacyGlobalProfile.record(
                .workedExample,
                for: "mathematics.new.lesson.\(index)",
                subjectID: "mathematics",
                at: Date(timeIntervalSince1970: TimeInterval(index + 3))
            )
        }
        precondition(
            legacyGlobalProfile.mostFrequentlyHelpful == .plainExplanation
                && legacyGlobalProfile.tutorPreference(forSubjectID: "mathematics") == .workedExample
                && legacyGlobalProfile.tutorPreference(forSubjectID: "biology") == .plainExplanation,
            "A confirmed subject preference must override the legacy global fallback, which remains available to subjects without their own evidence. / Подтверждённое предпочтение предмета должно перекрывать старый общий формат, который остаётся запасным для остальных предметов."
        )

        let legacyJSON = Data("""
        {"responses":[{"lesson_id":"legacy.saved.lesson","choice":"plain_explanation","recorded_at":1}]}
        """.utf8)
        let decodedLegacy = try JSONDecoder().decode(StudyFormatPreferenceProfile.self, from: legacyJSON)
        precondition(
            decodedLegacy.responses.first?.subjectID == nil,
            "Profiles saved before subject-specific preferences must still decode as global feedback. / Профили, сохранённые до появления предметных предпочтений, должны декодироваться как общая обратная связь."
        )

        var boundedProfile = StudyFormatPreferenceProfile()
        for index in 0..<60 {
            boundedProfile.record(
                .notSureYet,
                for: "lesson.\(index)",
                at: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
        precondition(
            boundedProfile.responses.count == StudyFormatPreferenceProfile.maximumStoredResponses,
            "The on-device preference history must remain bounded. / История предпочтений на устройстве должна иметь ограниченный размер."
        )

        var resettableProfile = StudyFormatPreferenceProfile()
        for index in 0..<3 {
            resettableProfile.record(
                .workedExample,
                for: "reset.lesson.\(index)",
                at: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
        precondition(
            resettableProfile.mostFrequentlyHelpful == .workedExample,
            "Three explicit lesson choices should create a visible preference before it can be cleared. / Три явных выбора в разных уроках должны создать предпочтение, которое можно очистить."
        )
        resettableProfile.clear()
        precondition(
            resettableProfile.responses.isEmpty && resettableProfile.mostFrequentlyHelpful == nil,
            "Clearing preferences must remove all local feedback and stop guiding the tutor. / Очистка должна удалить всю локальную обратную связь и убрать подсказку о предпочтении для тьютора."
        )
    }
}
