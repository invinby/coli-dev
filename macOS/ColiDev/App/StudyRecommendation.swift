import Foundation

struct StudyLessonRoute: Codable, Equatable {
    let subjectID: String
    let resource: String

    var lessonID: String { "\(subjectID).\(resource)" }
}

struct StudyRoadmap: Equatable {
    let subjectID: String
    let lessonResources: [String]

    init(subjectID: String, lessonResources: [String]) {
        self.subjectID = subjectID
        var seen = Set<String>()
        self.lessonResources = lessonResources.filter { resource in
            !resource.isEmpty && seen.insert(resource).inserted
        }
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

enum StudyRecommendationReason: Equatable {
    case resume
    case recallReview
    case nextLesson
}

struct StudyRecommendation: Equatable {
    let route: StudyLessonRoute
    let reason: StudyRecommendationReason
}

struct StudyRecallEvidence: Equatable {
    let quality: Int
    let reviewedAt: String?
}

enum StudyRecommendationSelector {
    static func recommendation(
        roadmaps: [StudyRoadmap],
        completedLessonIDs: Set<String>,
        resume: StudyLessonRoute?,
        recallEvidence: [String: StudyRecallEvidence] = [:]
    ) -> StudyRecommendation? {
        if let resume,
           let roadmap = roadmaps.first(where: { $0.subjectID == resume.subjectID }),
           roadmap.lessonResources.contains(resume.resource),
           !completedLessonIDs.contains(resume.lessonID) {
            return StudyRecommendation(route: resume, reason: .resume)
        }

        let weakRecallCandidates = roadmaps.flatMap { roadmap in
            roadmap.lessonResources.enumerated().compactMap { _, resource -> RecallCandidate? in
                let route = StudyLessonRoute(subjectID: roadmap.subjectID, resource: resource)
                guard completedLessonIDs.contains(route.lessonID),
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
            return Candidate(
                index: index,
                route: StudyLessonRoute(subjectID: roadmap.subjectID, resource: firstUnfinished),
                completedCount: completedCount,
                totalCount: roadmap.lessonResources.count
            )
        }

        guard let next = candidates.min(by: { lhs, rhs in
            let leftCoverage = lhs.completedCount * rhs.totalCount
            let rightCoverage = rhs.completedCount * lhs.totalCount
            return leftCoverage == rightCoverage ? lhs.index < rhs.index : leftCoverage < rightCoverage
        })?.route else { return nil }
        return StudyRecommendation(route: next, reason: .nextLesson)
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
        let completedCount: Int
        let totalCount: Int
    }

    private struct RecallCandidate {
        let route: StudyLessonRoute
        let quality: Int
        let reviewedAt: String
    }
}
