import Foundation

@main
enum TrigonometryModelVerification {
    static func main() {
        let quarterTurn = TrigonometricUnitCircle(angleRadians: .pi / 2)!
        precondition(close(quarterTurn.xCoordinate, 0), "At pi/2 the unit-circle x coordinate is zero. / При pi/2 координата x на единичной окружности равна нулю.")
        precondition(close(quarterTurn.yCoordinate, 1), "At pi/2 the unit-circle y coordinate is one. / При pi/2 координата y на единичной окружности равна единице.")
        precondition(close(quarterTurn.angleDegrees, 90), "Convert radians to degrees. / Перевести радианы в градусы.")
        precondition(close(quarterTurn.radiusSquared, 1), "The point remains on the unit circle. / Точка остаётся на единичной окружности.")

        let negativeQuarterTurn = TrigonometricUnitCircle(angleRadians: -.pi / 2)!
        precondition(close(negativeQuarterTurn.xCoordinate, 0), "At minus pi/2 the unit-circle x coordinate is zero. / При минус pi/2 координата x на единичной окружности равна нулю.")
        precondition(close(negativeQuarterTurn.yCoordinate, -1), "At minus pi/2 the unit-circle y coordinate is minus one. / При минус pi/2 координата y на единичной окружности равна минус единице.")

        let repeatedTurn = TrigonometricUnitCircle(angleRadians: .pi / 3 + 2 * .pi)!
        let oneTurn = TrigonometricUnitCircle(angleRadians: .pi / 3)!
        precondition(close(repeatedTurn.xCoordinate, oneTurn.xCoordinate), "Unit-circle coordinates repeat after 2pi. / Координаты на окружности повторяются через 2pi.")
        precondition(close(repeatedTurn.yCoordinate, oneTurn.yCoordinate), "Sine repeats after one full turn. / Синус повторяется после полного оборота.")
        precondition(close(TrigonometricUnitCircle.periodRadians, 2 * .pi), "Sine and cosine use a 2pi period. / Период синуса и косинуса равен 2pi.")

        precondition(TrigonometricUnitCircle(angleRadians: .infinity) == nil, "Reject an infinite angle. / Отклонить бесконечный угол.")
        precondition(TrigonometricUnitCircle(angleRadians: .nan) == nil, "Reject a NaN angle. / Отклонить угол NaN.")
        print("Trigonometry model checks passed. / Проверки модели тригонометрии прошли.")
    }

    private static func close(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 1e-9
    }
}
