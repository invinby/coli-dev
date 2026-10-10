import Foundation

@main
enum ConstrainedOptimizationVerification {
    static func main() {
        for degrees in [45.0, 225.0] {
            let point = makePoint(degrees: degrees)
            precondition(point.extremum == .maximum, "Equal-sign diagonal points are maxima. / Точки диагонали одинаковых знаков — максимумы.")
            precondition(close(point.objective, 0.5), "Maximum objective is one half. / Максимум целевой функции равен одной второй.")
            precondition(close(point.lagrangeMultiplier!, 0.5), "Maximum Lagrange multiplier is one half. / Множитель Лагранжа в максимуме равен одной второй.")
            precondition(close(point.constraintValue, 1), "Selected point stays on the unit circle. / Выбранная точка остаётся на единичной окружности.")
        }

        for degrees in [135.0, 315.0] {
            let point = makePoint(degrees: degrees)
            precondition(point.extremum == .minimum, "Opposite-sign diagonal points are minima. / Точки диагонали разных знаков — минимумы.")
            precondition(close(point.objective, -0.5), "Minimum objective is negative one half. / Минимум целевой функции равен минус одной второй.")
            precondition(close(point.lagrangeMultiplier!, -0.5), "Minimum Lagrange multiplier is negative one half. / Множитель Лагранжа в минимуме равен минус одной второй.")
            precondition(close(point.constraintValue, 1), "Selected point stays on the unit circle. / Выбранная точка остаётся на единичной окружности.")
        }

        for degrees in [0.0, 90.0, 180.0, 270.0] {
            let point = makePoint(degrees: degrees)
            precondition(point.extremum == .nonStationary, "Axis intersections are not stationary. / Пересечения с осями не являются стационарными точками.")
            precondition(close(point.objective, 0), "Axis intersections have zero objective. / В точках на осях целевая функция равна нулю.")
            precondition(point.lagrangeMultiplier == nil, "Non-stationary points have no reported multiplier. / Для нестационарных точек множитель не указывается.")
        }

        let negativeAngle = makePoint(radians: -Double.pi / 4)
        precondition(close(negativeAngle.angleRadians, 7 * Double.pi / 4), "Negative angles normalize into one full turn. / Отрицательный угол нормализуется в полный оборот.")
        precondition(ConstrainedOptimizationPoint(angleRadians: .infinity) == nil, "Reject non-finite angles. / Отклонять бесконечные углы.")
        precondition(ConstrainedOptimizationPoint(angleRadians: .nan) == nil, "Reject NaN angles. / Отклонять углы NaN.")

        print("Constrained optimization checks passed. / Проверки условной оптимизации прошли.")
    }

    private static func makePoint(degrees: Double) -> ConstrainedOptimizationPoint {
        makePoint(radians: degrees * Double.pi / 180)
    }

    private static func makePoint(radians: Double) -> ConstrainedOptimizationPoint {
        guard let point = ConstrainedOptimizationPoint(angleRadians: radians) else {
            preconditionFailure("A finite angle must create a point. / Конечный угол должен создавать точку.")
        }
        return point
    }

    private static func close(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 1e-9
    }
}
