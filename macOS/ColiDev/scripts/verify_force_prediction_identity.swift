import Foundation

@main
enum ForcePredictionIdentityVerification {
    static func main() {
        let sourcePath = "macOS/ColiDev/App/LearningViews.swift"
        guard let source = try? String(contentsOfFile: sourcePath, encoding: .utf8) else {
            preconditionFailure("The learning view source must be available to verify the force prediction.")
        }
        let factoryMarker = "private static func makePrediction() -> InteractivePredictionAttempt {"
        guard let factoryStart = source.range(of: factoryMarker) else {
            preconditionFailure("The force-prediction factory must remain available.")
        }
        let factoryTail = source[factoryStart.upperBound...]
        guard let factoryEnd = factoryTail.range(of: "private func reading(") else {
            preconditionFailure("The force-prediction factory must have a clear boundary.")
        }
        let factory = factoryTail[..<factoryEnd.lowerBound]
        precondition(
            factory.contains("itemID: \"physics.net_force_and_acceleration.force_doubling_prediction\""),
            "the force-doubling answer must retain its stable question identity"
        )
        print("Force prediction identity check passed.")
    }
}
