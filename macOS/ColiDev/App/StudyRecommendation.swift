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

enum StudyRecommendationSelector {
    static func nextLesson(
        roadmaps: [StudyRoadmap],
        completedLessonIDs: Set<String>,
        resume: StudyLessonRoute?
    ) -> StudyLessonRoute? {
        if let resume,
           let roadmap = roadmaps.first(where: { $0.subjectID == resume.subjectID }),
           roadmap.lessonResources.contains(resume.resource),
           !completedLessonIDs.contains(resume.lessonID) {
            return resume
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

        return candidates.min { lhs, rhs in
            let leftCoverage = lhs.completedCount * rhs.totalCount
            let rightCoverage = rhs.completedCount * lhs.totalCount
            return leftCoverage == rightCoverage ? lhs.index < rhs.index : leftCoverage < rightCoverage
        }?.route
    }

    private struct Candidate {
        let index: Int
        let route: StudyLessonRoute
        let completedCount: Int
        let totalCount: Int
    }
}
