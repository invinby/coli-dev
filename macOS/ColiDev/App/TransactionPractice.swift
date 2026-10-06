import Foundation

enum TransactionScenario: String, CaseIterable, Identifiable, Hashable {
    case commitTransfer
    case rollbackAfterDebit

    var id: String { rawValue }
    var titleKey: String { "lab.transaction.scenario.\(rawValue)" }
}

enum TransactionStage: String, Equatable {
    case ready
    case begun
    case debited
    case interrupted
    case credited
    case committed
    case rolledBack

    var titleKey: String { "lab.transaction.stage.\(rawValue)" }
    var isFinished: Bool { self == .committed || self == .rolledBack }
}

struct TransactionSnapshot: Equatable {
    let sourceBalance: Int
    let destinationBalance: Int
    let committedSourceBalance: Int
    let committedDestinationBalance: Int
    let amount: Int
    let stage: TransactionStage
    let traceKey: String

    var committedTotal: Int { committedSourceBalance + committedDestinationBalance }
    var workingTotal: Int { sourceBalance + destinationBalance }
    var transactionIsOpen: Bool { !stage.isFinished && stage != .ready }
}

enum TransactionPractice {
    static let initialSource = 80
    static let initialDestination = 20
    static let transferAmount = 30

    static func initialSnapshot() -> TransactionSnapshot {
        TransactionSnapshot(
            sourceBalance: initialSource,
            destinationBalance: initialDestination,
            committedSourceBalance: initialSource,
            committedDestinationBalance: initialDestination,
            amount: transferAmount,
            stage: .ready,
            traceKey: "lab.transaction.trace.ready"
        )
    }

    static func advance(_ snapshot: TransactionSnapshot, scenario: TransactionScenario) -> TransactionSnapshot {
        switch snapshot.stage {
        case .ready:
            return copy(snapshot, stage: .begun, traceKey: "lab.transaction.trace.begin")
        case .begun:
            guard snapshot.sourceBalance >= snapshot.amount else { return snapshot }
            return copy(snapshot, source: snapshot.sourceBalance - snapshot.amount, stage: .debited, traceKey: "lab.transaction.trace.debit")
        case .debited where scenario == .rollbackAfterDebit:
            return copy(snapshot, stage: .interrupted, traceKey: "lab.transaction.trace.interrupted")
        case .debited:
            return copy(snapshot, destination: snapshot.destinationBalance + snapshot.amount, stage: .credited, traceKey: "lab.transaction.trace.credit")
        case .credited:
            return TransactionSnapshot(
                sourceBalance: snapshot.sourceBalance,
                destinationBalance: snapshot.destinationBalance,
                committedSourceBalance: snapshot.sourceBalance,
                committedDestinationBalance: snapshot.destinationBalance,
                amount: snapshot.amount,
                stage: .committed,
                traceKey: "lab.transaction.trace.commit"
            )
        case .interrupted:
            return rollback(snapshot)
        case .committed, .rolledBack:
            return snapshot
        }
    }

    static func rollback(_ snapshot: TransactionSnapshot) -> TransactionSnapshot {
        guard snapshot.transactionIsOpen else { return snapshot }
        return TransactionSnapshot(
            sourceBalance: snapshot.committedSourceBalance,
            destinationBalance: snapshot.committedDestinationBalance,
            committedSourceBalance: snapshot.committedSourceBalance,
            committedDestinationBalance: snapshot.committedDestinationBalance,
            amount: snapshot.amount,
            stage: .rolledBack,
            traceKey: "lab.transaction.trace.rollback"
        )
    }

    static func nextActionKey(for snapshot: TransactionSnapshot, scenario: TransactionScenario) -> String? {
        switch snapshot.stage {
        case .ready: return "lab.transaction.action.begin"
        case .begun: return "lab.transaction.action.debit"
        case .debited: return scenario == .rollbackAfterDebit ? "lab.transaction.action.interrupt" : "lab.transaction.action.credit"
        case .interrupted: return "lab.transaction.action.rollback"
        case .credited: return "lab.transaction.action.commit"
        case .committed, .rolledBack: return nil
        }
    }

    private static func copy(
        _ snapshot: TransactionSnapshot,
        source: Int? = nil,
        destination: Int? = nil,
        stage: TransactionStage,
        traceKey: String
    ) -> TransactionSnapshot {
        TransactionSnapshot(
            sourceBalance: source ?? snapshot.sourceBalance,
            destinationBalance: destination ?? snapshot.destinationBalance,
            committedSourceBalance: snapshot.committedSourceBalance,
            committedDestinationBalance: snapshot.committedDestinationBalance,
            amount: snapshot.amount,
            stage: stage,
            traceKey: traceKey
        )
    }
}
