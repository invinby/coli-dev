import Foundation

@main
enum SQLQueryPracticeVerification {
    static func main() {
        let steps = SQLQueryPractice.steps
        precondition(steps.map(\.id) == [
            "programming.sql_schema.sessions_table",
            "programming.sql_queries.filter_and_order",
            "programming.sql_indexes.support_repeated_filter"
        ])
        precondition(Set(steps.map(\.id)).count == steps.count)
        for step in steps {
            precondition(step.optionKeys.count == 3)
            precondition(step.optionKeys.indices.contains(step.correctOptionIndex))
            precondition(SQLQueryPractice.isCorrect(step.correctOptionIndex, for: step.id))
            for option in step.optionKeys.indices where option != step.correctOptionIndex {
                precondition(!SQLQueryPractice.isCorrect(option, for: step.id))
            }
        }
        precondition(!SQLQueryPractice.isCorrect(-1, for: steps[0].id))
        precondition(!SQLQueryPractice.isCorrect(0, for: "programming.sql.unknown"))
        precondition(SQLQueryPractice.filteredSessions(minimumMinutes: 30).map(\.topic) == ["SQLite", "while"])
        precondition(SQLQueryPractice.filteredSessions(minimumMinutes: 30).map(\.minutes) == [50, 35])
        precondition(SQLQueryPractice.filteredSessions(minimumMinutes: 60).isEmpty)
        print("SQL schema/query practice model checks passed")
    }
}
