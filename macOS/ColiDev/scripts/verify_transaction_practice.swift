import Foundation

@main
enum TransactionPracticeVerification {
    static func main() {
        var snapshot = TransactionPractice.initialSnapshot()
        precondition(snapshot.committedTotal == 100)
        precondition(snapshot.workingTotal == snapshot.committedTotal)
        precondition(!snapshot.transactionIsOpen)

        snapshot = TransactionPractice.advance(snapshot, scenario: .commitTransfer)
        precondition(snapshot.stage == .begun && snapshot.transactionIsOpen)
        snapshot = TransactionPractice.advance(snapshot, scenario: .commitTransfer)
        precondition(snapshot.stage == .debited)
        precondition(snapshot.sourceBalance == 50 && snapshot.destinationBalance == 20)
        precondition(snapshot.committedSourceBalance == 80 && snapshot.committedDestinationBalance == 20)
        precondition(snapshot.workingTotal == 70 && snapshot.committedTotal == 100)
        snapshot = TransactionPractice.advance(snapshot, scenario: .commitTransfer)
        precondition(snapshot.stage == .credited)
        precondition(snapshot.sourceBalance == 50 && snapshot.destinationBalance == 50)
        precondition(snapshot.workingTotal == 100)
        snapshot = TransactionPractice.advance(snapshot, scenario: .commitTransfer)
        precondition(snapshot.stage == .committed)
        precondition(snapshot.committedSourceBalance == 50 && snapshot.committedDestinationBalance == 50)
        precondition(snapshot.committedTotal == 100)
        precondition(TransactionPractice.advance(snapshot, scenario: .commitTransfer) == snapshot)

        var interrupted = TransactionPractice.initialSnapshot()
        interrupted = TransactionPractice.advance(interrupted, scenario: .rollbackAfterDebit)
        interrupted = TransactionPractice.advance(interrupted, scenario: .rollbackAfterDebit)
        interrupted = TransactionPractice.advance(interrupted, scenario: .rollbackAfterDebit)
        precondition(interrupted.stage == .interrupted)
        precondition(interrupted.sourceBalance == 50 && interrupted.destinationBalance == 20)
        interrupted = TransactionPractice.advance(interrupted, scenario: .rollbackAfterDebit)
        precondition(interrupted.stage == .rolledBack)
        precondition(interrupted.sourceBalance == 80 && interrupted.destinationBalance == 20)
        precondition(interrupted.committedTotal == 100 && interrupted.workingTotal == 100)
        precondition(TransactionPractice.rollback(interrupted) == interrupted)
        precondition(TransactionPractice.nextActionKey(for: interrupted, scenario: .rollbackAfterDebit) == nil)
        print("Transaction practice model checks passed")
    }
}
