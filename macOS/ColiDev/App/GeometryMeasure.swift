import Foundation

enum GeometryShape: String, CaseIterable, Hashable {
    case rectangle
    case rightTriangle
}

/// Area and perimeter for a rectangle or a right triangle with perpendicular legs.
struct GeometryMeasure {
    let base: Double
    let height: Double
    let shape: GeometryShape

    init(base: Double, height: Double, shape: GeometryShape) {
        precondition(base.isFinite && base > 0 && height.isFinite && height > 0)
        self.base = base
        self.height = height
        self.shape = shape
    }

    var area: Double {
        let rectangleArea = base * height
        return shape == .rectangle ? rectangleArea : rectangleArea / 2
    }

    var areaNeedsRoundingForDisplay: Bool {
        needsRoundingForHundredths(area)
    }

    var perimeter: Double {
        switch shape {
        case .rectangle:
            2 * (base + height)
        case .rightTriangle:
            base + height + hypot(base, height)
        }
    }

    var perimeterNeedsRoundingForDisplay: Bool {
        needsRoundingForHundredths(perimeter)
    }

    var diagonal: Double { hypot(base, height) }

    private func needsRoundingForHundredths(_ value: Double) -> Bool {
        let hundredths = value * 100
        guard hundredths.isFinite else { return true }
        return abs(hundredths - hundredths.rounded()) > 1e-8
    }
}
