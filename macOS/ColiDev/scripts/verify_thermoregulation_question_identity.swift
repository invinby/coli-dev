import Foundation

@main
enum ThermoregulationQuestionIdentityVerification {
    static func main() {
        let modelPath = "macOS/ColiDev/App/ThermoregulationPractice.swift"
        guard let model = try? String(contentsOfFile: modelPath, encoding: .utf8) else {
            preconditionFailure("The thermoregulation model source must be available.")
        }
        let expectedID = "zoology.comparative_thermoregulation_and_heat_stress.heat_stress_threshold_interpretation"
        precondition(
            model.contains("static let heatStressThresholdQuestionID = \"\(expectedID)\""),
            "the threshold question must have a stable activity ID"
        )

        let viewPath = "macOS/ColiDev/App/LearningViews.swift"
        guard let views = try? String(contentsOfFile: viewPath, encoding: .utf8) else {
            preconditionFailure("The learning view source must be available.")
        }
        guard let labStart = views.range(of: "private struct ThermoregulationLab: View {") else {
            preconditionFailure("The thermoregulation lab must remain available.")
        }
        let labTail = views[labStart.upperBound...]
        let labEnd = labTail.range(of: "\nprivate struct ")
        let lab = labEnd.map { labTail[..<$0.lowerBound] } ?? labTail
        precondition(
            lab.contains("itemID: ThermoregulationPractice.heatStressThresholdQuestionID"),
            "the thermoregulation answer evidence must retain its stable activity ID"
        )
        print("Thermoregulation question identity check passed.")
    }
}
