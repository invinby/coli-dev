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
            guidance?.contains("визу") == true
                && guidance?.contains("точность") == true
                && englishGuidance?.localizedCaseInsensitiveContains("visual") == true
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
    }
}
