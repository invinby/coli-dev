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
        let checkCoverage = StudyKnowledgeEvidenceCoverage(
            roadmaps: roadmaps,
            records: [
                StudyAssessmentProgressRecord(
                    lessonID: "mathematics.fractions",
                    assessmentCount: 2,
                    latestAssessment: StudyAssessmentEvidence(
                        taskType: "knowledge_check",
                        attempts: 2,
                        firstTryCorrect: false,
                        hintsUsed: 0,
                        errorCategories: [.application, .foundation]
                    )
                ),
                StudyAssessmentProgressRecord(
                    lessonID: "english.verbs",
                    assessmentCount: 1,
                    latestAssessment: StudyAssessmentEvidence(
                        taskType: "knowledge_check",
                        attempts: 1,
                        firstTryCorrect: true,
                        hintsUsed: 0
                    )
                ),
                StudyAssessmentProgressRecord(
                    lessonID: "biology.cells",
                    assessmentCount: 0,
                    latestAssessment: nil
                ),
                StudyAssessmentProgressRecord(
                    lessonID: "intro.mathematics",
                    assessmentCount: 8,
                    latestAssessment: StudyAssessmentEvidence(
                        taskType: "knowledge_check",
                        attempts: 3,
                        firstTryCorrect: false,
                        hintsUsed: 0
                    )
                ),
                StudyAssessmentProgressRecord(
                    lessonID: "mathematics.not_in_roadmap",
                    assessmentCount: 3,
                    latestAssessment: nil
                ),
                StudyAssessmentProgressRecord(
                    lessonID: "english.conditionals",
                    assessmentCount: nil,
                    latestAssessment: StudyAssessmentEvidence(
                        taskType: "knowledge_check",
                        attempts: 1,
                        firstTryCorrect: true,
                        hintsUsed: 0
                    )
                ),
            ]
        )
        precondition(
            checkCoverage.totalTopicCount == 7
                && checkCoverage.topicsWithChecks == 3
                && checkCoverage.topicsNeedingPractice == 1
                && checkCoverage.reportedErrorTopicCounts[.application] == 1
                && checkCoverage.reportedErrorTopicCounts[.foundation] == 1,
            "Knowledge evidence must count only addressable roadmap topics and flag the latest check when it needed retries. / Свидетельства понимания должны учитывать только доступные темы плана и отмечать темы, где последняя проверка потребовала повторов."
        )
        let interactiveEvidence = StudyAssessmentEvidenceSummary(
            lessonID: "zoology.thermoregulation",
            assessmentCount: 2,
            taskTypeCounts: ["interactive_prediction": 2],
            passedTaskTypeCounts: [:],
            errorCategoryCounts: [:],
            latestAssessment: StudyAssessmentEvidence(
                taskType: "interactive_prediction",
                attempts: 2,
                firstTryCorrect: false,
                hintsUsed: 0
            ),
            latestAt: "2026-10-08T12:00:00Z"
        )
        let interactiveCoverage = StudyKnowledgeEvidenceCoverage(
            roadmaps: [StudyRoadmap(subjectID: "zoology", lessonResources: ["thermoregulation"])],
            records: [],
            additionalEvidence: [interactiveEvidence]
        )
        precondition(
            interactiveCoverage.topicsWithChecks == 1
                && interactiveCoverage.topicsNeedingPractice == 1,
            "Interactive assessment events must count as evidence coverage and flag retries without claiming mastery. / Интерактивные проверки должны учитываться как свидетельства и отмечать повторные попытки, не выдавая их за освоение темы."
        )
        let interactivePractice = StudyRecommendationSelector.recommendation(
            roadmaps: [StudyRoadmap(subjectID: "zoology", lessonResources: ["thermoregulation"])],
            completedLessonIDs: [],
            resume: nil,
            assessmentEvidence: [interactiveEvidence.lessonID: interactiveEvidence]
        )
        precondition(
            interactivePractice == StudyRecommendation(
                route: StudyLessonRoute(subjectID: "zoology", resource: "thermoregulation"),
                reason: .practiceReview
            ),
            "An unsuccessful interactive prediction must recommend its own topic even before lesson completion. / Неудачный интерактивный прогноз должен рекомендовать повторить именно эту тему, даже если урок ещё не отмечен пройденным."
        )
        let repeatedFoundationReport = StudyAssessmentEvidenceSummary(
            lessonID: "biology.cells",
            assessmentCount: 4,
            taskTypeCounts: ["knowledge_check": 4],
            passedTaskTypeCounts: ["knowledge_check": 2],
            errorCategoryCounts: ["foundation": 2],
            latestAssessment: StudyAssessmentEvidence(
                taskType: "knowledge_check",
                attempts: 1,
                firstTryCorrect: false,
                hintsUsed: 0,
                errorCategories: [.foundation],
                passed: false
            ),
            latestAt: "2026-10-08T13:00:00Z"
        )
        let genericRetry = StudyAssessmentEvidenceSummary(
            lessonID: "biology.genes",
            assessmentCount: 4,
            taskTypeCounts: ["knowledge_check": 4],
            passedTaskTypeCounts: [:],
            errorCategoryCounts: [:],
            latestAssessment: StudyAssessmentEvidence(
                taskType: "knowledge_check",
                attempts: 5,
                firstTryCorrect: false,
                hintsUsed: 0,
                passed: false
            ),
            latestAt: "2026-10-08T13:30:00Z"
        )
        let repeatedDifficultyRecommendation = StudyRecommendationSelector.recommendation(
            roadmaps: [StudyRoadmap(subjectID: "biology", lessonResources: ["cells", "genes"])],
            completedLessonIDs: [],
            resume: nil,
            assessmentEvidence: [
                repeatedFoundationReport.lessonID: repeatedFoundationReport,
                genericRetry.lessonID: genericRetry,
            ]
        )
        precondition(
            repeatedDifficultyRecommendation?.route.lessonID == "biology.cells",
            "A repeated self-reported difficulty on the latest failed topic must take priority over a generic retry count. / Повторная самооценка трудности по последней непройденной теме должна быть приоритетнее общего числа повторных попыток."
        )
        let emptyCoverage = StudyKnowledgeEvidenceCoverage(roadmaps: [], records: [])
        precondition(
            emptyCoverage.totalTopicCount == 0
                && emptyCoverage.topicsWithChecks == 0
                && emptyCoverage.topicsNeedingPractice == 0,
            "An empty curriculum must report no knowledge evidence without inventing a mastery score. / Пустой учебный план должен показывать отсутствие свидетельств, не придумывая оценку освоения."
        )
        precondition(
            !StudyReviewActionPolicy.canRecord(isComplete: true, isReviewDue: false, hasAssessment: false)
                && StudyReviewActionPolicy.canRecord(isComplete: true, isReviewDue: false, hasAssessment: true)
                && StudyReviewActionPolicy.canRecord(isComplete: true, isReviewDue: true, hasAssessment: false)
                && StudyReviewActionPolicy.canRecord(isComplete: false, isReviewDue: false, hasAssessment: false),
            "A completed lesson can save early practice only after a new checked answer; due reviews and first completions stay available. / Пройденный урок можно досрочно записать как тренировку только после нового проверенного ответа; просроченный повтор и первое прохождение остаются доступны."
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

        let practiceReview = StudyRecommendationSelector.recommendation(
            roadmaps: roadmaps,
            completedLessonIDs: completed,
            resume: nil,
            recallEvidence: [
                "mathematics.fractions": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: StudyAssessmentEvidence(
                        taskType: "knowledge_check",
                        attempts: 2,
                        firstTryCorrect: false,
                        hintsUsed: 0
                    )
                ),
            ]
        )
        precondition(
            practiceReview == StudyRecommendation(
                route: StudyLessonRoute(subjectID: "mathematics", resource: "fractions"),
                reason: .practiceReview
            ),
            "A checked topic solved after retries must be recommended for practice even when self-rated recall is high. / Тему, проверочный вопрос которой решён после повторов, нужно предложить закрепить даже при высокой самооценке воспоминания."
        )

        let confidentRecall = StudyRecommendationSelector.recommendation(
            roadmaps: roadmaps,
            completedLessonIDs: completed,
            resume: nil,
            recallEvidence: [
                "mathematics.fractions": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: StudyAssessmentEvidence(
                        taskType: "knowledge_check",
                        attempts: 1,
                        firstTryCorrect: true,
                        hintsUsed: 0
                    )
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

        var customCurriculum = CustomCurriculum()
        let customSubjectID = try! customCurriculum.addSubject(
            name: CustomCurriculumText(russian: "Астрономия", english: "Astronomy"),
            description: CustomCurriculumText(russian: "Космос", english: "Space"),
            reservedNames: []
        )
        let customTopicID = try! customCurriculum.addTopic(
            subjectID: customSubjectID,
            parentTopicID: nil,
            name: CustomCurriculumText(russian: "Орбиты", english: "Orbits"),
            learningOutcome: CustomCurriculumText(russian: "Понимать орбиты", english: "Understand orbits"),
            notes: CustomCurriculumText(russian: "", english: "")
        )
        let customSubtopicID = try! customCurriculum.addTopic(
            subjectID: customSubjectID,
            parentTopicID: customTopicID,
            name: CustomCurriculumText(russian: "Эллипсы", english: "Ellipses"),
            learningOutcome: CustomCurriculumText(russian: "Изучать эллипсы", english: "Study ellipses"),
            notes: CustomCurriculumText(russian: "", english: "")
        )
        let builtInCustomTopicID = try! customCurriculum.addTopic(
            builtInSubjectID: "biology",
            parentTopicID: nil,
            name: CustomCurriculumText(russian: "Мой эксперимент", english: "My experiment"),
            learningOutcome: CustomCurriculumText(russian: "Планировать опыт", english: "Plan an experiment"),
            notes: CustomCurriculumText(russian: "", english: "")
        )
        let customRoadmaps = CustomTopicStudyRoute.roadmaps(from: customCurriculum)
        let userTopicRoute = CustomTopicStudyRoute.userTopic(
            subjectID: customSubjectID,
            topicID: customTopicID
        )
        let userSubtopicRoute = CustomTopicStudyRoute.userTopic(
            subjectID: customSubjectID,
            topicID: customSubtopicID
        )
        let builtInTopicRoute = CustomTopicStudyRoute.builtInTopic(
            subjectID: "biology",
            topicID: builtInCustomTopicID
        )
        precondition(
            customRoadmaps.count == 2
                && customRoadmaps[0].lessonResources == [customTopicID.uuidString.lowercased(), customSubtopicID.uuidString.lowercased()]
                && customRoadmaps[1].lessonResources == [builtInCustomTopicID.uuidString.lowercased()],
            "User-created subjects and added built-in topics must become ordered study roadmaps. / Пользовательские предметы и добавленные темы встроенных предметов должны становиться упорядоченными учебными планами."
        )
        precondition(
            CustomTopicStudyRoute.address(for: userTopicRoute, in: customCurriculum)
                == .learnerSubject(subjectID: customSubjectID, topicID: customTopicID)
                && CustomTopicStudyRoute.address(for: builtInTopicRoute, in: customCurriculum)
                    == .builtInSubject(subjectID: "biology", topicID: builtInCustomTopicID),
            "Custom study routes must resolve to their actual owner and topic. / Пользовательские маршруты должны разрешаться в соответствующий предмет и тему."
        )
        precondition(
            CustomTopicStudyRoute.address(
                for: CustomTopicStudyRoute.userTopic(subjectID: customSubjectID, topicID: UUID()),
                in: customCurriculum
            ) == nil,
            "Deleted or unknown custom topics must not resolve to an arbitrary screen. / Удалённая или неизвестная пользовательская тема не должна открывать произвольный экран."
        )

        let customResume = StudyRecommendationSelector.recommendation(
            roadmaps: customRoadmaps,
            completedLessonIDs: [],
            resume: userSubtopicRoute
        )
        precondition(
            customResume == StudyRecommendation(route: userSubtopicRoute, reason: .resume),
            "Continue must resume an unfinished user-created subtopic. / «Продолжить» должна возвращать к незавершённой пользовательской подтеме."
        )
        let customRecall = StudyRecommendationSelector.recommendation(
            roadmaps: customRoadmaps,
            completedLessonIDs: [userTopicRoute.lessonID],
            resume: nil,
            recallEvidence: [
                userTopicRoute.lessonID: StudyRecallEvidence(quality: 2, reviewedAt: "2026-10-08T10:00:00Z"),
            ]
        )
        precondition(
            customRecall == StudyRecommendation(route: userTopicRoute, reason: .recallReview),
            "Low recall on a user-created topic must recommend revisiting that topic. / Низкая самооценка пользовательской темы должна рекомендовать повторить именно её."
        )

        let stagedRoadmap = StudyRoadmap(
            subjectID: "biology",
            lessonResources: ["cells", "cell_cycle", "gene_expression"],
            progressionLevels: [["cells", "cell_cycle"], ["gene_expression"]]
        )
        let successfulCellCheck = StudyAssessmentEvidence(
            taskType: "knowledge_check",
            attempts: 1,
            firstTryCorrect: true,
            hintsUsed: 0
        )
        let passedCells = Set(["biology.cells", "biology.cell_cycle"])
        let oldSavedProgress = StudyProgressionEvidence(
            completedLessonIDs: passedCells,
            recallEvidence: [
                "biology.cells": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: successfulCellCheck
                ),
            ],
            assessmentEvidence: [:]
        )
        let missingLegacyCheck = StudyRecommendationSelector.recommendation(
            roadmaps: [stagedRoadmap],
            completedLessonIDs: passedCells,
            resume: nil,
            recallEvidence: [
                "biology.cells": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: successfulCellCheck
                ),
            ]
        )
        precondition(
            missingLegacyCheck == StudyRecommendation(
                route: StudyLessonRoute(subjectID: "biology", resource: "cell_cycle"),
                reason: .prerequisiteCheck
            ),
            "Completed legacy lessons without a saved knowledge check must offer a reachable check before the next level. / Для завершённого старого урока без сохранённой проверки нужно предложить доступное перепрохождение проверки перед следующим уровнем."
        )
        let lockedResume = StudyRecommendationSelector.recommendation(
            roadmaps: [stagedRoadmap],
            completedLessonIDs: passedCells,
            resume: StudyLessonRoute(subjectID: "biology", resource: "gene_expression"),
            recallEvidence: [
                "biology.cells": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: successfulCellCheck
                ),
            ]
        )
        precondition(
            lockedResume == StudyRecommendation(
                route: StudyLessonRoute(subjectID: "biology", resource: "cell_cycle"),
                reason: .prerequisiteCheck
            ),
            "A remembered advanced route must not bypass an unverified foundation. / Сохранённый маршрут к углублённой теме не должен обходить непроверенную основу."
        )
        precondition(
            !StudyProgressionPolicy.isAvailable(
                StudyLessonRoute(subjectID: "biology", resource: "gene_expression"),
                in: stagedRoadmap,
                evidence: oldSavedProgress
            ),
            "An advanced module must remain locked until every linked prerequisite has a successful knowledge check. / Продвинутый модуль должен оставаться закрытым, пока по каждой связанной предпосылке нет успешной проверки знаний."
        )

        let interactivePredictionOnly = StudyAssessmentEvidenceSummary(
            lessonID: "biology.cell_cycle",
            assessmentCount: 1,
            taskTypeCounts: ["interactive_prediction": 1],
            passedTaskTypeCounts: [:],
            errorCategoryCounts: [:],
            latestAssessment: StudyAssessmentEvidence(
                taskType: "interactive_prediction",
                attempts: 1,
                firstTryCorrect: true,
                hintsUsed: 0
            ),
            latestAt: "2026-10-08T11:00:00Z"
        )
        let predictionDoesNotUnlock = StudyProgressionEvidence(
            completedLessonIDs: passedCells,
            recallEvidence: [
                "biology.cells": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: successfulCellCheck
                ),
            ],
            assessmentEvidence: ["biology.cell_cycle": interactivePredictionOnly]
        )
        precondition(
            !StudyProgressionPolicy.isAvailable(
                StudyLessonRoute(subjectID: "biology", resource: "gene_expression"),
                in: stagedRoadmap,
                evidence: predictionDoesNotUnlock
            ),
            "An interactive prediction must not substitute for a knowledge check when unlocking an advanced level. / Интерактивный прогноз не должен заменять проверку знаний при открытии углублённого уровня."
        )
        let successfulSyncedCheck = StudyAssessmentEvidenceSummary(
            lessonID: "biology.cell_cycle",
            assessmentCount: 1,
            taskTypeCounts: ["knowledge_check": 1],
            passedTaskTypeCounts: ["knowledge_check": 1],
            errorCategoryCounts: [:],
            latestAssessment: successfulCellCheck,
            latestAt: "2026-10-08T11:00:00Z"
        )
        let syncedFoundation = StudyProgressionEvidence(
            completedLessonIDs: passedCells,
            recallEvidence: [
                "biology.cells": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: successfulCellCheck
                ),
            ],
            assessmentEvidence: ["biology.cell_cycle": successfulSyncedCheck]
        )
        precondition(
            StudyProgressionPolicy.isAvailable(
                StudyLessonRoute(subjectID: "biology", resource: "gene_expression"),
                in: stagedRoadmap,
                evidence: syncedFoundation
            ),
            "A synchronized successful knowledge check must unlock the next level. / Синхронизированная успешная проверка знаний должна открывать следующий уровень."
        )

        let failedSyncedCheck = StudyAssessmentEvidenceSummary(
            lessonID: "biology.cell_cycle",
            assessmentCount: 1,
            taskTypeCounts: ["knowledge_check": 1],
            passedTaskTypeCounts: [:],
            errorCategoryCounts: ["foundation": 1],
            latestAssessment: StudyAssessmentEvidence(
                taskType: "knowledge_check",
                attempts: 1,
                firstTryCorrect: false,
                hintsUsed: 0,
                errorCategories: [.foundation],
                passed: false
            ),
            latestAt: "2026-10-08T11:00:00Z"
        )
        let failedFoundation = StudyProgressionEvidence(
            completedLessonIDs: passedCells,
            recallEvidence: [
                "biology.cells": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: successfulCellCheck
                ),
            ],
            assessmentEvidence: ["biology.cell_cycle": failedSyncedCheck]
        )
        precondition(
            !StudyProgressionPolicy.isAvailable(
                StudyLessonRoute(subjectID: "biology", resource: "gene_expression"),
                in: stagedRoadmap,
                evidence: failedFoundation
            ),
            "A failed knowledge-check event must never unlock the next level. / Неудачная проверка знаний не должна открывать следующий уровень."
        )

        let passedFoundation = StudyProgressionEvidence(
            completedLessonIDs: passedCells,
            recallEvidence: [
                "biology.cells": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: successfulCellCheck
                ),
                "biology.cell_cycle": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T11:00:00Z",
                    assessment: successfulCellCheck
                ),
            ],
            assessmentEvidence: [:]
        )
        let advancedRecommendation = StudyRecommendationSelector.recommendation(
            roadmaps: [stagedRoadmap],
            completedLessonIDs: passedCells,
            resume: nil,
            recallEvidence: [
                "biology.cells": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: successfulCellCheck
                ),
                "biology.cell_cycle": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T11:00:00Z",
                    assessment: successfulCellCheck
                ),
            ]
        )
        precondition(
            StudyProgressionPolicy.isAvailable(
                StudyLessonRoute(subjectID: "biology", resource: "gene_expression"),
                in: stagedRoadmap,
                evidence: passedFoundation
            ) && advancedRecommendation == StudyRecommendation(
                route: StudyLessonRoute(subjectID: "biology", resource: "gene_expression"),
                reason: .nextLesson
            ),
            "Passing every foundation check must unlock and recommend the next level. / Успешные проверки всех уроков базы должны открыть и рекомендовать следующий уровень."
        )
        let fullyCompletedStages = Set([
            "biology.cells", "biology.cell_cycle", "biology.gene_expression",
        ])
        let completedLegacyStage = StudyRecommendationSelector.recommendation(
            roadmaps: [stagedRoadmap],
            completedLessonIDs: fullyCompletedStages,
            resume: nil,
            recallEvidence: [
                "biology.cells": StudyRecallEvidence(
                    quality: 5,
                    reviewedAt: "2026-10-08T10:00:00Z",
                    assessment: successfulCellCheck
                ),
            ]
        )
        precondition(
            completedLegacyStage == StudyRecommendation(
                route: StudyLessonRoute(subjectID: "biology", resource: "cell_cycle"),
                reason: .prerequisiteCheck
            ),
            "A fully completed legacy roadmap with locked levels must still recommend the missing prerequisite check. / Полностью пройденная старая карта с закрытым уровнем всё равно должна предлагать недостающую проверку предпосылки."
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
