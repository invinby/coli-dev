import Foundation

struct SQLSessionRecord: Equatable {
    let topic: String
    let minutes: Int
}

struct SQLQueryStep: Equatable, Identifiable {
    let id: String
    let promptKey: String
    let optionKeys: [String]
    let correctOptionIndex: Int
    let explanationKey: String
    let sqlKey: String
}

enum SQLQueryPractice {
    static let sampleSessions = [
        SQLSessionRecord(topic: "algorithms", minutes: 15),
        SQLSessionRecord(topic: "while", minutes: 35),
        SQLSessionRecord(topic: "SQLite", minutes: 50),
        SQLSessionRecord(topic: "Git", minutes: 20)
    ]

    static let steps = [
        SQLQueryStep(
            id: "programming.sql_schema.sessions_table",
            promptKey: "lab.sql.schema.prompt",
            optionKeys: [
                "lab.sql.schema.choice.loose",
                "lab.sql.schema.choice.guarded",
                "lab.sql.schema.choice.mixedTypes"
            ],
            correctOptionIndex: 1,
            explanationKey: "lab.sql.schema.explanation",
            sqlKey: "lab.sql.schema.code"
        ),
        SQLQueryStep(
            id: "programming.sql_queries.filter_and_order",
            promptKey: "lab.sql.query.prompt",
            optionKeys: [
                "lab.sql.query.choice.filteredOrdered",
                "lab.sql.query.choice.allRows",
                "lab.sql.query.choice.filteredUnordered"
            ],
            correctOptionIndex: 0,
            explanationKey: "lab.sql.query.explanation",
            sqlKey: "lab.sql.query.code"
        ),
        SQLQueryStep(
            id: "programming.sql_indexes.support_repeated_filter",
            promptKey: "lab.sql.index.prompt",
            optionKeys: [
                "lab.sql.index.choice.topic",
                "lab.sql.index.choice.everything",
                "lab.sql.index.choice.minutes"
            ],
            correctOptionIndex: 2,
            explanationKey: "lab.sql.index.explanation",
            sqlKey: "lab.sql.index.code"
        )
    ]

    static func isCorrect(_ option: Int, for stepID: String) -> Bool {
        guard let step = steps.first(where: { $0.id == stepID }),
              step.optionKeys.indices.contains(option) else { return false }
        return option == step.correctOptionIndex
    }

    static func filteredSessions(minimumMinutes: Int) -> [SQLSessionRecord] {
        sampleSessions
            .filter { $0.minutes >= minimumMinutes }
            .sorted { $0.minutes > $1.minutes }
    }
}
