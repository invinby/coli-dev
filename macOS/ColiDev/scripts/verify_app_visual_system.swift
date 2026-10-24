import SwiftUI

@main
struct VerifyAppVisualSystem {
    static func main() {
        let coreSubjects = [
            "mathematics",
            "english",
            "physics",
            "biology",
            "zoology",
            "programming",
        ]

        let tokens = coreSubjects.map(ColiDevVisualSystem.subjectToken)
        precondition(tokens.count == 6, "Every core subject must have a visual token")
        precondition(Set(tokens.map(\.lightHex)).count == coreSubjects.count, "Light accents must be distinct")
        precondition(Set(tokens.map(\.darkHex)).count == coreSubjects.count, "Dark accents must be distinct")
        precondition(tokens.allSatisfy { $0.lightHex != $0.darkHex }, "Each accent needs composed light and dark variants")
        precondition(ColiDevVisualSystem.subjectToken("unknown").lightHex != 0, "Unknown subjects need a visible fallback accent")

        precondition(
            ColiDevVisualSystem.studyAccentToken(subjectID: "biology", resource: "intro").lightHex == 0x1F7652,
            "A built-in Biology lesson must keep the Biology accent."
        )
        precondition(
            ColiDevVisualSystem.studyAccentToken(subjectID: "intro", resource: "biology").lightHex == 0x1F7652,
            "The built-in subject intro route must use that subject's accent."
        )
        precondition(
            ColiDevVisualSystem.studyAccentToken(subjectID: "custom-builtin:mathematics").lightHex == 0x5747B8,
            "A learner-created topic inside Mathematics must inherit the Mathematics accent."
        )
        precondition(
            ColiDevVisualSystem.studyAccentToken(subjectID: "custom-user:9f4e").lightHex == 0x405F9B,
            "A custom subject must receive the readable fallback accent."
        )

        print("Visual system verified: six subject accents, route inheritance, and custom-subject fallback")
    }
}
