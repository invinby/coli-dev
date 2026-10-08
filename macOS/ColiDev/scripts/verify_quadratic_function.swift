import Foundation

@main
enum QuadraticFunctionVerification {
    static func main() {
        let upward = QuadraticFunctionPractice(a: 2, h: 1, k: -8)!
        precondition(close(upward.value(at: 0), -6), "evaluate vertex form from parameters")
        precondition(upward.vertexX == 1 && upward.vertexY == -8, "read the vertex from vertex form")
        precondition(upward.opensUp && upward.width == .narrower, "classify an upward narrow parabola")
        precondition(upward.realRoots().count == 2, "find two real x-intercepts")
        precondition(close(upward.realRoots()[0], -1) && close(upward.realRoots()[1], 3), "sort the two roots")

        let downward = QuadraticFunctionPractice(a: -0.5, h: -2, k: 3)!
        precondition(!downward.opensUp && downward.width == .wider, "classify a downward wide parabola")
        precondition(close(downward.realRoots()[0], -4.449489742783178), "find the first non-integer root")
        precondition(close(downward.realRoots()[1], 0.449489742783178), "find the second non-integer root")

        let tangent = QuadraticFunctionPractice(a: 1, h: 2, k: 0)!
        precondition(tangent.realRoots() == [2], "report one root when the vertex lies on the x-axis")
        let noRealRoots = QuadraticFunctionPractice(a: 1, h: 0, k: 1)!
        precondition(noRealRoots.realRoots().isEmpty, "report no real roots above the x-axis")

        precondition(QuadraticFunctionPractice(a: 0, h: 1, k: 2) == nil, "reject a degenerate constant function")
        precondition(QuadraticFunctionPractice(a: .infinity, h: 1, k: 2) == nil, "reject non-finite parameters")
        precondition(QuadraticFunctionPractice(a: 1, h: .nan, k: 2) == nil, "reject a non-finite vertex")
        print("Quadratic function checks passed.")
    }

    private static func close(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 1e-9
    }
}
