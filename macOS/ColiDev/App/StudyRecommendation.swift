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
