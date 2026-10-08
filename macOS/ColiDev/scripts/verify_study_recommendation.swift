import Foundation

@main
enum StudyRecommendationVerification {
    static func main() {
        let roadmaps = [
            StudyRoadmap(subjectID: "mathematics", lessonResources: ["fractions", "geometry", "algebra"]),
            StudyRoadmap(subjectID: "english", lessonResources: ["verbs", "conditionals"]),
            StudyRoadmap(subjectID: "biology", lessonResources: ["cells", "genes"]),
        ]

        let completed = Set([
            "mathematics.fractions", "english.verbs", "intro.mathematics", "mathematics.not_in_roadmap",
        ])
        let progress = StudyCourseProgress(roadmaps: roadmaps, completedLessonIDs: completed)
        precondition(
            progress.completedCount == 2 && progress.totalCount == 7,
            "Course progress must count completed linked lessons, not subject introductions or unrelated records. / Прогресс курса должен считать завершённые уроки дорожных карт, а не вводные карточки предметов или посторонние записи."
        )
        precondition(
            abs(progress.fractionCompleted - (2.0 / 7.0)) < 0.000_001,
            "Course completion must use the linked lesson total. / Завершённость курса должна считаться по общему числу связанных уроков."
        )
        let emptyProgress = StudyCourseProgress(roadmaps: [], completedLessonIDs: completed)
        precondition(
            emptyProgress.totalCount == 0 && emptyProgress.fractionCompleted == 0,
            "An empty curriculum must report zero completion without division errors. / Для пустого учебного плана нужно показывать нулевой прогресс без ошибки деления."
        )

        let next = StudyRecommendationSelector.nextLesson(
            roadmaps: roadmaps,
            completedLessonIDs: completed,
            resume: nil
        )
        precondition(
            next == StudyLessonRoute(subjectID: "biology", resource: "cells"),
            "The next step must choose the least-covered subject and its first unfinished lesson. / Следующий шаг должен выбрать наименее пройденный предмет и первый незавершённый урок."
        )

        let difficultRecall = StudyRecommendationSelector.recommendation(
            roadmaps: roadmaps,
            completedLessonIDs: completed,
            resume: nil,
            recallEvidence: [
                "mathematics.fractions": StudyRecallEvidence(
                    quality: 2,
                    reviewedAt: "2026-10-08T10:00:00Z"
                ),
            ]
        )
        precondition(
            difficultRecall == StudyRecommendation(
                route: StudyLessonRoute(subjectID: "mathematics", resource: "fractions"),
                reason: .recallReview
            ),
            "A completed lesson with difficult self-rated recall must be recommended before a new topic. / После сложной самооценки воспоминания нужно рекомендовать повторить пройденную тему до перехода к новой."
        )

        let confidentRecall = StudyRecommendationSelector.recommendation(
            roadmaps: roadmaps,
            completedLessonIDs: completed,
            resume: nil,
            recallEvidence: [
                "mathematics.fractions": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z"
                ),
            ]
        )
        precondition(
            confidentRecall == StudyRecommendation(
                route: StudyLessonRoute(subjectID: "biology", resource: "cells"),
                reason: .nextLesson
            ),
            "A confident self-rating must not force a repeat before the next unfinished topic. / Уверенная самооценка не должна заставлять ученика повторять тему вместо перехода к следующему незавершённому уроку."
        )

        let resume = StudyLessonRoute(subjectID: "mathematics", resource: "geometry")
        let continued = StudyRecommendationSelector.nextLesson(
            roadmaps: roadmaps,
            completedLessonIDs: completed,
            resume: resume
        )
        precondition(
            continued == resume,
            "Continue must resume the learner's unfinished lesson. / Продолжение должно открывать последний незавершённый урок."
        )

        let resumedBeforeReview = StudyRecommendationSelector.recommendation(
            roadmaps: roadmaps,
            completedLessonIDs: completed,
            resume: resume,
            recallEvidence: [
                "mathematics.fractions": StudyRecallEvidence(quality: 1, reviewedAt: nil),
            ]
        )
        precondition(
            resumedBeforeReview == StudyRecommendation(route: resume, reason: .resume),
            "Continue must preserve an unfinished lesson ahead of recall-based review suggestions. / Незавершённый урок должен оставаться выше рекомендации повторить другую тему."
        )

        let allCompleted = Set([
            "mathematics.fractions", "mathematics.geometry", "mathematics.algebra",
            "english.verbs", "english.conditionals", "biology.cells", "biology.genes",
        ])
        let noNextStep = StudyRecommendationSelector.nextLesson(
            roadmaps: roadmaps,
            completedLessonIDs: allCompleted,
            resume: resume
        )
        precondition(
            noNextStep == nil,
            "The planner must not send a completed course back to an arbitrary first lesson. / План не должен возвращать с завершённого курса на случайный первый урок."
        )

        print("Study recommendation checks passed. / Проверки рекомендаций к обучению прошли.")
    }
}
