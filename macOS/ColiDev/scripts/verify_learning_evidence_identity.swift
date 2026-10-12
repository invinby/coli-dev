import Foundation

@main
enum LearningEvidenceIdentityVerification {
    static func main() {
        var missingRequirements: [String] = []

        let thermoregulationModel = source("macOS/ColiDev/App/ThermoregulationPractice.swift")
        require(
            thermoregulationModel,
            "static let heatStressThresholdQuestionID = \"zoology.comparative_thermoregulation_and_heat_stress.heat_stress_threshold_interpretation\"",
            "thermoregulation question ID",
            into: &missingRequirements
        )
        let learningViews = source("macOS/ColiDev/App/LearningViews.swift")
        require(
            learningViews,
            "itemID: ThermoregulationPractice.heatStressThresholdQuestionID",
            "thermoregulation attempt wiring",
            into: &missingRequirements
        )

        let quadraticPractice = source("macOS/ColiDev/App/QuadraticFunctionPractice.swift")
        require(
            quadraticPractice,
            "static let predictionQuestionID = \"mathematics.quadratic_functions_and_transformations.parabola_width_prediction\"",
            "quadratic prediction question ID",
            into: &missingRequirements
        )
        require(
            quadraticPractice,
            "itemID: Self.predictionQuestionID",
            "quadratic prediction evidence wiring",
            into: &missingRequirements
        )

        let statisticsModel = source("macOS/ColiDev/App/DescriptiveStatistics.swift")
        require(
            statisticsModel,
            "static let potentialOutlierQuestionID = \"mathematics.descriptive_statistics_and_potential_outliers.maximum_outlier_classification\"",
            "statistics question ID",
            into: &missingRequirements
        )
        require(
            source("macOS/ColiDev/App/StatisticsPracticeLab.swift"),
            "itemID: DescriptiveStatistics.potentialOutlierQuestionID",
            "statistics attempt wiring",
            into: &missingRequirements
        )

        let trigonometryModel = source("macOS/ColiDev/App/TrigonometricUnitCircle.swift")
        require(
            trigonometryModel,
            "static let sineSignQuestionID = \"mathematics.trigonometry_and_periodic_functions.unit_circle_sine_sign\"",
            "trigonometry question ID",
            into: &missingRequirements
        )
        require(
            source("macOS/ColiDev/App/TrigonometryUnitCircleLab.swift"),
            "itemID: TrigonometricUnitCircle.sineSignQuestionID",
            "trigonometry attempt wiring",
            into: &missingRequirements
        )

        let choiceModels = source("macOS/ColiDev/App/AnswerChoiceOrder.swift")
        let checkAttempt = region(
            choiceModels,
            from: "struct CurriculumCheckAttempt: Equatable {",
            to: "struct InteractivePredictionAttempt: Equatable {"
        )
        require(checkAttempt, "let itemID: String", "curriculum check question ID storage", into: &missingRequirements)
        require(checkAttempt, "itemID: itemID", "curriculum check answer evidence wiring", into: &missingRequirements)
        require(
            learningViews,
            "itemID: \\(lessonID).knowledge_check",
            "Markdown lesson check ID wiring",
            into: &missingRequirements
        )

        precondition(
            missingRequirements.isEmpty,
            "Learning evidence is missing stable question identity: \(missingRequirements.joined(separator: ", "))"
        )
        print("Learning evidence identity checks passed.")
    }

    private static func source(_ path: String) -> String {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            preconditionFailure("Required source file is missing: \(path)")
        }
        return contents
    }

    private static func require(_ contents: String, _ snippet: String, _ name: String, into failures: inout [String]) {
        if !contents.contains(snippet) {
            failures.append(name)
        }
    }

    private static func region(_ contents: String, from start: String, to end: String) -> String {
        guard let startRange = contents.range(of: start),
              let endRange = contents[startRange.upperBound...].range(of: end) else {
            preconditionFailure("Required source region is missing: \(start)")
        }
        return String(contents[startRange.lowerBound..<endRange.lowerBound])
    }
}
