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

        print("Visual system verified: six distinct subject accents with light/dark variants")
    }
}
