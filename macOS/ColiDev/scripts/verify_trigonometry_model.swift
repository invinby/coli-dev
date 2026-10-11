import Foundation

@main
enum TrigonometryModelVerification {
    static func main() {
        let quarterTurn = TrigonometricUnitCircle(angleRadians: .pi / 2)!
        precondition(close(quarterTurn.xCoordinate, 0), "At pi/2 the unit-circle x coordinate is zero. / При pi/2 координата x на единичной окружности равна нулю.")
        precondition(close(quarterTurn.yCoordinate, 1), "At pi/2 the unit-circle y coordinate is one. / При pi/2 координата y на единичной окружности равна единице.")
        precondition(close(quarterTurn.angleDegrees, 90), "Convert radians to degrees. / Перевести радианы в градусы.")
        precondition(close(quarterTurn.radiusSquared, 1), "The point remains on the unit circle. / Точка остаётся на единичной окружности.")
        precondition(quarterTurn.sineSign == .positive, "A point above the horizontal axis has a positive sine. / Точка выше горизонтальной оси имеет положительный синус.")
        precondition(quarterTurn.sineSign.answerOriginalIndex == 2, "Positive sine maps to the positive answer. / Положительный синус соответствует положительному варианту ответа.")
        precondition(quarterTurn.sineSign.explanationKey == "lab.trigonometry.explanation.positive", "Positive sine selects its matching explanation. / Положительный синус выбирает соответствующий разбор.")

        let negativeQuarterTurn = TrigonometricUnitCircle(angleRadians: -.pi / 2)!
        precondition(close(negativeQuarterTurn.xCoordinate, 0), "At minus pi/2 the unit-circle x coordinate is zero. / При минус pi/2 координата x на единичной окружности равна нулю.")
        precondition(close(negativeQuarterTurn.yCoordinate, -1), "At minus pi/2 the unit-circle y coordinate is minus one. / При минус pi/2 координата y на единичной окружности равна минус единице.")
        precondition(negativeQuarterTurn.sineSign == .negative, "A point below the horizontal axis has a negative sine. / Точка ниже горизонтальной оси имеет отрицательный синус.")
        precondition(negativeQuarterTurn.sineSign.answerOriginalIndex == 0, "Negative sine maps to the negative answer. / Отрицательный синус соответствует отрицательному варианту ответа.")
        precondition(negativeQuarterTurn.sineSign.explanationKey == "lab.trigonometry.explanation.negative", "Negative sine selects its matching explanation. / Отрицательный синус выбирает соответствующий разбор.")

        let onAxis = TrigonometricUnitCircle(angleRadians: .pi)!
        precondition(onAxis.sineSign == .zero, "A point on the horizontal axis has zero sine. / Точка на горизонтальной оси имеет нулевой синус.")
        precondition(onAxis.sineSign.answerOriginalIndex == 1, "Zero sine maps to the zero answer. / Нулевой синус соответствует нулевому варианту ответа.")
        precondition(onAxis.sineSign.explanationKey == "lab.trigonometry.explanation.zero", "Zero sine selects its matching explanation. / Нулевой синус выбирает соответствующий разбор.")

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
