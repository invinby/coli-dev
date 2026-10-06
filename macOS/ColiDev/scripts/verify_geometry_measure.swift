import Foundation

@main
enum GeometryMeasureVerification {
    static func main() {
        let tolerance = 1e-10

        let rectangle = GeometryMeasure(base: 6, height: 4, shape: .rectangle)
        expect(rectangle.area, equals: 24, tolerance: tolerance, "rectangle area")
        expect(rectangle.perimeter, equals: 20, tolerance: tolerance, "rectangle perimeter")
        expect(rectangle.diagonal, equals: sqrt(52), tolerance: tolerance, "rectangle diagonal")

        let rightTriangle = GeometryMeasure(base: 3, height: 4, shape: .rightTriangle)
        expect(rightTriangle.area, equals: 6, tolerance: tolerance, "right-triangle area")
        expect(rightTriangle.diagonal, equals: 5, tolerance: tolerance, "right-triangle hypotenuse")
        expect(rightTriangle.perimeter, equals: 12, tolerance: tolerance, "right-triangle perimeter")

        let scaledRectangle = GeometryMeasure(base: 12, height: 8, shape: .rectangle)
        expect(scaledRectangle.area, equals: rectangle.area * 4, tolerance: tolerance, "area scales by the square of the scale factor")
        expect(scaledRectangle.perimeter, equals: rectangle.perimeter * 2, tolerance: tolerance, "perimeter scales linearly")

        let matchingRightTriangle = GeometryMeasure(base: 6, height: 4, shape: .rightTriangle)
        expect(matchingRightTriangle.area, equals: rectangle.area / 2, tolerance: tolerance, "right triangle has half the area of its enclosing rectangle")

        print("Geometry measurement checks passed.")
    }

    private static func expect(
        _ actual: Double,
        equals expected: Double,
        tolerance: Double,
        _ name: String
    ) {
        precondition(actual.isFinite && abs(actual - expected) <= tolerance, "\(name): expected \(expected), got \(actual)")
    }
}
