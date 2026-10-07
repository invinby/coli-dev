import Foundation

@main
enum StudyRecommendationVerification {
    static func main() {
        let roadmaps = [
            StudyRoadmap(subjectID: "mathematics", lessonResources: ["fractions", "geometry", "algebra"]),
            StudyRoadmap(subjectID: "english", lessonResources: ["verbs", "conditionals"]),
            StudyRoadmap(subjectID: "biology", lessonResources: ["cells", "genes"]),
        ]

        let completed = Set(["mathematics.fractions", "english.verbs"])
        let next = StudyRecommendationSelector.nextLesson(
            roadmaps: roadmaps,
            completedLessonIDs: completed,
            resume: nil
        )
        precondition(
            next == StudyLessonRoute(subjectID: "biology", resource: "cells"),
            "The next step must choose the least-covered subject and its first unfinished lesson. / Следующий шаг должен выбрать наименее пройденный предмет и первый незавершённый урок."
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
