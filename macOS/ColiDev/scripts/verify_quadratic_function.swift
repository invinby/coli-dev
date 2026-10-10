import Foundation

@main
enum QuadraticFunctionVerification {
    static func main() {
        let upward = QuadraticFunctionPractice(a: 2, h: 1, k: -8)!
        precondition(close(upward.value(at: 0), -6), "Evaluate vertex form from parameters. / Вычислить значение вершинной формы по параметрам.")
        precondition(upward.vertexX == 1 && upward.vertexY == -8, "Read the vertex from vertex form. / Найти вершину по вершинной форме.")
        precondition(upward.opensUp && upward.width == .narrower, "Classify an upward narrow parabola. / Определить параболу, направленную вверх и более узкую.")
        precondition(upward.realRoots().count == 2, "Find two real x-intercepts. / Найти два действительных корня.")
        precondition(close(upward.realRoots()[0], -1) && close(upward.realRoots()[1], 3), "Sort the two roots. / Расположить два корня по возрастанию.")

        let downward = QuadraticFunctionPractice(a: -0.5, h: -2, k: 3)!
        precondition(!downward.opensUp && downward.width == .wider, "Classify a downward wide parabola. / Определить параболу, направленную вниз и более широкую.")
        precondition(close(downward.realRoots()[0], -4.449489742783178), "Find the first non-integer root. / Найти первый нецелый корень.")
        precondition(close(downward.realRoots()[1], 0.449489742783178), "Find the second non-integer root. / Найти второй нецелый корень.")

        let tangent = QuadraticFunctionPractice(a: 1, h: 2, k: 0)!
        precondition(
            tangent.width == .standard,
            "Classify the parent parabola width. / Определить ширину исходной параболы."
        )
        precondition(tangent.realRoots() == [2], "Report one root when the vertex lies on the x-axis. / Вернуть один корень, если вершина лежит на оси x.")
        let noRealRoots = QuadraticFunctionPractice(a: 1, h: 0, k: 1)!
        precondition(noRealRoots.realRoots().isEmpty, "Report no real roots above the x-axis. / Не возвращать действительные корни, если вершина выше оси x.")

        precondition(QuadraticFunctionPractice(a: 0, h: 1, k: 2) == nil, "Reject a degenerate constant function. / Отклонить вырожденную постоянную функцию.")
        precondition(QuadraticFunctionPractice(a: .infinity, h: 1, k: 2) == nil, "Reject non-finite parameters. / Отклонить не конечные параметры.")
        precondition(QuadraticFunctionPractice(a: 1, h: .nan, k: 2) == nil, "Reject a non-finite vertex. / Отклонить не конечную координату вершины.")
        print("Quadratic function checks passed. / Проверки квадратичной функции прошли.")
    }

    private static func close(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 1e-9
    }
}
