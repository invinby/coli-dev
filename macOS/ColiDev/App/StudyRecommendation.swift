import Foundation

struct StudyLessonRoute: Codable, Equatable {
    let subjectID: String
    let resource: String

    var lessonID: String { "\(subjectID).\(resource)" }
}

struct StudyRoadmap: Equatable {
    let subjectID: String
    let lessonResources: [String]
    let progressionLevels: [[String]]

    init(
        subjectID: String,
        lessonResources: [String],
        progressionLevels: [[String]] = []
    ) {
        self.subjectID = subjectID
        var seen = Set<String>()
        self.lessonResources = lessonResources.filter { resource in
            !resource.isEmpty && seen.insert(resource).inserted
        }
        let availableResources = Set(self.lessonResources)
        var assignedResources = Set<String>()
        self.progressionLevels = progressionLevels.map { level in
            level.filter { resource in
                availableResources.contains(resource) && assignedResources.insert(resource).inserted
            }
        }.filter { !$0.isEmpty }
    }
}

enum CustomTopicStudyAddress: Equatable {
    case learnerSubject(subjectID: UUID, topicID: UUID)
    case builtInSubject(subjectID: String, topicID: UUID)
}

enum CustomTopicStudyRoute {
    private static let learnerSubjectPrefix = "custom-user:"
    private static let builtInSubjectPrefix = "custom-builtin:"
    private static let builtInSubjectIDs: Set<String> = [
        "mathematics", "english", "physics", "biology", "zoology", "programming",
    ]

    static func userTopic(subjectID: UUID, topicID: UUID) -> StudyLessonRoute {
        StudyLessonRoute(
            subjectID: learnerSubjectPrefix + subjectID.uuidString.lowercased(),
            resource: topicID.uuidString.lowercased()
        )
    }

    static func builtInTopic(subjectID: String, topicID: UUID) -> StudyLessonRoute {
        StudyLessonRoute(
            subjectID: builtInSubjectPrefix + subjectID,
            resource: topicID.uuidString.lowercased()
        )
    }

    static func address(
        for route: StudyLessonRoute,
        in curriculum: CustomCurriculum
    ) -> CustomTopicStudyAddress? {
        guard let topicID = UUID(uuidString: route.resource) else { return nil }

        if route.subjectID.hasPrefix(learnerSubjectPrefix) {
            let rawSubjectID = String(route.subjectID.dropFirst(learnerSubjectPrefix.count))
            guard let subjectID = UUID(uuidString: rawSubjectID),
                  curriculum.topic(subjectID: subjectID, topicID: topicID) != nil else { return nil }
            return .learnerSubject(subjectID: subjectID, topicID: topicID)
        }

        guard route.subjectID.hasPrefix(builtInSubjectPrefix) else { return nil }
        let subjectID = String(route.subjectID.dropFirst(builtInSubjectPrefix.count))
        guard builtInSubjectIDs.contains(subjectID),
              curriculum.topic(builtInSubjectID: subjectID, topicID: topicID) != nil else { return nil }
        return .builtInSubject(subjectID: subjectID, topicID: topicID)
    }

    static func roadmaps(from curriculum: CustomCurriculum) -> [StudyRoadmap] {
        var roadmaps = curriculum.subjects.compactMap { subject -> StudyRoadmap? in
            let resources = topicIDs(in: subject.topics)
            guard !resources.isEmpty else { return nil }
            return StudyRoadmap(
                subjectID: learnerSubjectPrefix + subject.id.uuidString.lowercased(),
                lessonResources: resources
            )
        }

        for subjectID in builtInSubjectIDs.sorted() {
            let resources = topicIDs(in: curriculum.topics(builtInSubjectID: subjectID))
            guard !resources.isEmpty else { continue }
            roadmaps.append(StudyRoadmap(
                subjectID: builtInSubjectPrefix + subjectID,
                lessonResources: resources
            ))
        }
        return roadmaps
    }

    private static func topicIDs(in topics: [CustomLearningTopic]) -> [String] {
        topics.flatMap { topic in
            [topic.id.uuidString.lowercased()] + topicIDs(in: topic.subtopics)
        }
    }
}

struct StudyCourseProgress: Equatable {
    let completedCount: Int
    let totalCount: Int

    var fractionCompleted: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    init(roadmaps: [StudyRoadmap], completedLessonIDs: Set<String>) {
        let lessonIDs = Set(roadmaps.flatMap { roadmap in
            roadmap.lessonResources.map { "\(roadmap.subjectID).\($0)" }
        })
        totalCount = lessonIDs.count
        completedCount = lessonIDs.intersection(completedLessonIDs).count
    }
}

struct StudyAssessmentProgressRecord: Equatable {
    let lessonID: String
    let assessmentCount: Int?
    let latestAssessment: StudyAssessmentEvidence?
    let latestAssessmentAt: String?

    init(
        lessonID: String,
        assessmentCount: Int?,
        latestAssessment: StudyAssessmentEvidence?,
        latestAssessmentAt: String? = nil
    ) {
        self.lessonID = lessonID
        self.assessmentCount = assessmentCount
        self.latestAssessment = latestAssessment
        self.latestAssessmentAt = latestAssessmentAt
    }
}

struct StudyAssessmentEvidenceSummary: Decodable, Equatable, Identifiable {
    let lessonID: String
    let assessmentCount: Int
    let taskTypeCounts: [String: Int]
    let latestAssessment: StudyAssessmentEvidence
    let latestAt: String

    var id: String { lessonID }

    enum CodingKeys: String, CodingKey {
        case lessonID = "lesson_id"
        case assessmentCount = "assessment_count"
        case taskTypeCounts = "task_type_counts"
        case latestAssessment = "latest_assessment"
        case latestAt = "latest_at"
    }
}

struct StudyKnowledgeEvidenceCoverage: Equatable {
    let totalTopicCount: Int
    let topicsWithChecks: Int
    let topicsNeedingPractice: Int
    let reportedErrorTopicCounts: [StudyErrorCategory: Int]

    init(
        roadmaps: [StudyRoadmap],
        records: [StudyAssessmentProgressRecord],
        additionalEvidence: [StudyAssessmentEvidenceSummary] = []
    ) {
        let topicIDs = Set(roadmaps.flatMap { roadmap in
            roadmap.lessonResources.map { "\(roadmap.subjectID).\($0)" }
        })
        totalTopicCount = topicIDs.count

        var recordsByLesson = Dictionary(uniqueKeysWithValues: records.map { ($0.lessonID, $0) })
        for summary in additionalEvidence {
            let previous = recordsByLesson[summary.lessonID]
            let summaryIsNewer = previous?.latestAssessmentAt.map { summary.latestAt > $0 } ?? true
            recordsByLesson[summary.lessonID] = StudyAssessmentProgressRecord(
                lessonID: summary.lessonID,
                assessmentCount: (previous?.assessmentCount ?? 0) + summary.assessmentCount,
                latestAssessment: summaryIsNewer ? summary.latestAssessment : previous?.latestAssessment,
                latestAssessmentAt: summaryIsNewer ? summary.latestAt : previous?.latestAssessmentAt
            )
        }

        var checkedTopicIDs = Set<String>()
        var practiceTopicIDs = Set<String>()
        var errorTopicIDsByCategory: [StudyErrorCategory: Set<String>] = [:]
        for record in recordsByLesson.values where topicIDs.contains(record.lessonID) {
            let hasRecordedCheck = (record.assessmentCount ?? 0) > 0
                || record.latestAssessment != nil
            guard hasRecordedCheck else { continue }
            checkedTopicIDs.insert(record.lessonID)

            if let assessment = record.latestAssessment,
               assessment.attempts > 1 || !assessment.firstTryCorrect {
                practiceTopicIDs.insert(record.lessonID)
            }
            for category in record.latestAssessment?.errorCategories ?? [] {
                errorTopicIDsByCategory[category, default: []].insert(record.lessonID)
            }
        }
        topicsWithChecks = checkedTopicIDs.count
        topicsNeedingPractice = practiceTopicIDs.count
        reportedErrorTopicCounts = errorTopicIDsByCategory.mapValues(\.count)
    }
}

enum StudyRecommendationReason: Equatable {
    case resume
    case practiceReview
    case recallReview
    case prerequisiteCheck
    case nextLesson
}

struct StudyRecommendation: Equatable {
    let route: StudyLessonRoute
    let reason: StudyRecommendationReason
}

enum StudyReviewActionPolicy {
    static func canRecord(isComplete: Bool, isReviewDue: Bool, hasAssessment: Bool) -> Bool {
        !isComplete || isReviewDue || hasAssessment
    }
}

struct StudyRecallEvidence: Equatable {
    let quality: Int
    let reviewedAt: String?
    let assessment: StudyAssessmentEvidence?

    init(quality: Int, reviewedAt: String?, assessment: StudyAssessmentEvidence? = nil) {
        self.quality = quality
        self.reviewedAt = reviewedAt
        self.assessment = assessment
    }
}

struct StudyProgressionEvidence: Equatable {
    let completedLessonIDs: Set<String>
    let successfulKnowledgeCheckLessonIDs: Set<String>

    init(
        completedLessonIDs: Set<String>,
        recallEvidence: [String: StudyRecallEvidence],
        assessmentEvidence: [String: StudyAssessmentEvidenceSummary]
    ) {
        self.completedLessonIDs = completedLessonIDs

        var checkedLessonIDs = Set(recallEvidence.compactMap { lessonID, evidence in
            evidence.assessment?.taskType == "knowledge_check" ? lessonID : nil
        })
        checkedLessonIDs.formUnion(assessmentEvidence.values.compactMap { summary in
            (summary.taskTypeCounts["knowledge_check"] ?? 0) > 0 ? summary.lessonID : nil
        })
        successfulKnowledgeCheckLessonIDs = checkedLessonIDs
    }
}

enum StudyProgressionPolicy {
    static func prerequisiteRecommendation(
        for resource: String,
        in roadmap: StudyRoadmap,
        evidence: StudyProgressionEvidence
    ) -> StudyRecommendation? {
        guard let levelIndex = roadmap.progressionLevels.firstIndex(where: { $0.contains(resource) }) else {
            return nil
        }

        let prerequisiteResources = roadmap.progressionLevels.prefix(levelIndex).flatMap { $0 }
        guard !prerequisiteResources.isEmpty else { return nil }

        if let unfinishedResource = prerequisiteResources.first(where: {
            !evidence.completedLessonIDs.contains("\(roadmap.subjectID).\($0)")
        }) {
            return StudyRecommendation(
                route: StudyLessonRoute(subjectID: roadmap.subjectID, resource: unfinishedResource),
                reason: .nextLesson
            )
        }

        if let uncheckedResource = prerequisiteResources.first(where: {
            !evidence.successfulKnowledgeCheckLessonIDs.contains("\(roadmap.subjectID).\($0)")
        }) {
            return StudyRecommendation(
                route: StudyLessonRoute(subjectID: roadmap.subjectID, resource: uncheckedResource),
                reason: .prerequisiteCheck
            )
        }
        return nil
    }

    static func isAvailable(
        _ route: StudyLessonRoute,
        in roadmap: StudyRoadmap,
        evidence: StudyProgressionEvidence
    ) -> Bool {
        guard route.subjectID == roadmap.subjectID,
              roadmap.lessonResources.contains(route.resource) else { return true }
        return prerequisiteRecommendation(for: route.resource, in: roadmap, evidence: evidence) == nil
    }
}

enum StudyRecommendationSelector {
    static func recommendation(
        roadmaps: [StudyRoadmap],
        completedLessonIDs: Set<String>,
        resume: StudyLessonRoute?,
        recallEvidence: [String: StudyRecallEvidence] = [:],
        assessmentEvidence: [String: StudyAssessmentEvidenceSummary] = [:]
    ) -> StudyRecommendation? {
        let progressionEvidence = StudyProgressionEvidence(
            completedLessonIDs: completedLessonIDs,
            recallEvidence: recallEvidence,
            assessmentEvidence: assessmentEvidence
        )

        if let resume,
           let roadmap = roadmaps.first(where: { $0.subjectID == resume.subjectID }),
           roadmap.lessonResources.contains(resume.resource),
           !completedLessonIDs.contains(resume.lessonID) {
            let prerequisite = StudyProgressionPolicy.prerequisiteRecommendation(
                for: resume.resource,
                in: roadmap,
                evidence: progressionEvidence
            )
            return prerequisite ?? StudyRecommendation(route: resume, reason: .resume)
        }

        let practiceCandidates = roadmaps.flatMap { roadmap in
            roadmap.lessonResources.compactMap { resource -> PracticeCandidate? in
                let route = StudyLessonRoute(subjectID: roadmap.subjectID, resource: resource)
                guard StudyProgressionPolicy.isAvailable(route, in: roadmap, evidence: progressionEvidence) else {
                    return nil
                }
                let recall = recallEvidence[route.lessonID]
                let interactive = assessmentEvidence[route.lessonID]
                let useInteractive: Bool
                if let interactive {
                    useInteractive = recall?.reviewedAt.map { interactive.latestAt > $0 } ?? true
                } else {
                    useInteractive = false
                }
                let assessment = useInteractive
                    ? interactive?.latestAssessment
                    : recall?.assessment ?? interactive?.latestAssessment
                let evidenceDate = useInteractive
                    ? interactive?.latestAt
                    : recall?.reviewedAt ?? interactive?.latestAt
                guard let assessment,
                      assessment.attempts > 1 || !assessment.firstTryCorrect else { return nil }
                return PracticeCandidate(
                    route: route,
                    attempts: assessment.attempts,
                    reviewedAt: evidenceDate ?? ""
                )
            }
        }
        if let needsPractice = practiceCandidates.min(by: { lhs, rhs in
            if lhs.attempts != rhs.attempts { return lhs.attempts > rhs.attempts }
            if lhs.reviewedAt != rhs.reviewedAt { return lhs.reviewedAt < rhs.reviewedAt }
            return lhs.route.lessonID < rhs.route.lessonID
        }) {
            return StudyRecommendation(route: needsPractice.route, reason: .practiceReview)
        }

        let weakRecallCandidates = roadmaps.flatMap { roadmap in
            roadmap.lessonResources.enumerated().compactMap { _, resource -> RecallCandidate? in
                let route = StudyLessonRoute(subjectID: roadmap.subjectID, resource: resource)
                guard StudyProgressionPolicy.isAvailable(route, in: roadmap, evidence: progressionEvidence),
                      completedLessonIDs.contains(route.lessonID),
                      let evidence = recallEvidence[route.lessonID],
                      evidence.quality < 3 else { return nil }
                return RecallCandidate(
                    route: route,
                    quality: evidence.quality,
                    reviewedAt: evidence.reviewedAt ?? ""
                )
            }
        }
        if let weakest = weakRecallCandidates.min(by: { lhs, rhs in
            if lhs.quality != rhs.quality { return lhs.quality < rhs.quality }
            if lhs.reviewedAt != rhs.reviewedAt { return lhs.reviewedAt < rhs.reviewedAt }
            return lhs.route.lessonID < rhs.route.lessonID
        }) {
            return StudyRecommendation(route: weakest.route, reason: .recallReview)
        }

        let candidates = roadmaps.enumerated().compactMap { index, roadmap -> Candidate? in
            guard let firstUnfinished = roadmap.lessonResources.first(where: {
                !completedLessonIDs.contains("\(roadmap.subjectID).\($0)")
            }) else { return nil }

            let completedCount = roadmap.lessonResources.reduce(into: 0) { count, resource in
                if completedLessonIDs.contains("\(roadmap.subjectID).\(resource)") {
                    count += 1
                }
            }
            let route = StudyLessonRoute(subjectID: roadmap.subjectID, resource: firstUnfinished)
            let requirement = StudyProgressionPolicy.prerequisiteRecommendation(
                for: firstUnfinished,
                in: roadmap,
                evidence: progressionEvidence
            )
            return Candidate(
                index: index,
                route: requirement?.route ?? route,
                reason: requirement?.reason ?? .nextLesson,
                completedCount: completedCount,
                totalCount: roadmap.lessonResources.count
            )
        }

        let completedStageCheckCandidates = roadmaps.enumerated().compactMap { index, roadmap -> Candidate? in
            guard !roadmap.lessonResources.isEmpty else { return nil }
            let completedCount = roadmap.lessonResources.reduce(into: 0) { count, resource in
                if completedLessonIDs.contains("\(roadmap.subjectID).\(resource)") {
                    count += 1
                }
            }
            guard completedCount == roadmap.lessonResources.count,
                  let requirement = roadmap.progressionLevels.dropFirst()
                    .flatMap({ $0 })
                    .compactMap({ resource in
                        StudyProgressionPolicy.prerequisiteRecommendation(
                            for: resource,
                            in: roadmap,
                            evidence: progressionEvidence
                        )
                    })
                    .first(where: { $0.reason == .prerequisiteCheck }) else { return nil }
            return Candidate(
                index: index,
                route: requirement.route,
                reason: requirement.reason,
                completedCount: completedCount,
                totalCount: roadmap.lessonResources.count
            )
        }

        let nextCandidates = candidates.isEmpty ? completedStageCheckCandidates : candidates
        guard let next = nextCandidates.min(by: { lhs, rhs in
            let leftCoverage = lhs.completedCount * rhs.totalCount
            let rightCoverage = rhs.completedCount * lhs.totalCount
            return leftCoverage == rightCoverage ? lhs.index < rhs.index : leftCoverage < rightCoverage
        }) else { return nil }
        return StudyRecommendation(route: next.route, reason: next.reason)
    }

    static func nextLesson(
        roadmaps: [StudyRoadmap],
        completedLessonIDs: Set<String>,
        resume: StudyLessonRoute?,
        recallEvidence: [String: StudyRecallEvidence] = [:]
    ) -> StudyLessonRoute? {
        recommendation(
            roadmaps: roadmaps,
            completedLessonIDs: completedLessonIDs,
            resume: resume,
            recallEvidence: recallEvidence
        )?.route
    }

    private struct Candidate {
        let index: Int
        let route: StudyLessonRoute
        let reason: StudyRecommendationReason
        let completedCount: Int
        let totalCount: Int
    }

    private struct RecallCandidate {
        let route: StudyLessonRoute
        let quality: Int
        let reviewedAt: String
    }

    private struct PracticeCandidate {
        let route: StudyLessonRoute
        let attempts: Int
        let reviewedAt: String
    }
}
