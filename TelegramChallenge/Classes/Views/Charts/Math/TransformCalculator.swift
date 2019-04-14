//
//  Created by Timur Bernikovich on 19/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

struct Path {
    let points: [CGPoint]
    let values: [Int64]
    let minValue: Int64?
    let maxValue: Int64?
}

extension Path {
    
    func stackWithPath(_ path: Path) -> Path {
        guard points.count == path.points.count else {
            fatalError("Only path with same length can be stacked")
        }
        
        let stackedPoints = points.enumerated().map { index, point -> CGPoint in
            let y: CGFloat = 1 - (1 - point.y) - (1 - path.points[index].y)
            return CGPoint(x: point.x, y: y)
        }
        let stackedValues = values.enumerated().map { index, value in
            return value + path.values[index]
        }
        return Path(
            points: stackedPoints,
            values: stackedValues,
            minValue: stackedValues.min(),
            maxValue: stackedValues.max()
        )
    }
    
    var bezierPath: UIBezierPath {
        let path = UIBezierPath()
        points.enumerated().forEach { index, point in
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
    var cgPath: CGPath {
        return bezierPath.cgPath
    }
    
    var barBezierPath: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 1))
        points.enumerated().forEach { index, point in
            path.addLine(to: point)
        }
        path.addLine(to: CGPoint(x: 1, y: 1))
        path.close()
        return path
    }
    var barCGPath: CGPath {
        return barBezierPath.cgPath
    }

}

class TransformCalculator {

    // Path represents line in 1x1 coordinates.
    // Can be moved to background for optimization.
    func pathForLine(_ line: Column, coordinateSystemSize: CGSize = CGSize(width: 1, height: 1)) -> Path {
        let numberOfSegments = line.values.count - 1
        let segmentWidth = Double(coordinateSystemSize.width) / Double(max(1, numberOfSegments))
        
        let minValue = line.minValue ?? 0
        let maxValue = line.maxValue ?? 1
        let verticalRange = minValue != maxValue ? Double(maxValue - minValue) : 1
        
        let points = line.values.enumerated().map { index, value -> CGPoint in
            let x = Double(index) * segmentWidth
            let y = Double(coordinateSystemSize.height) * (1 - Double(value - minValue) / verticalRange)
            return CGPoint(x: x, y: y)
        }
        
        return Path(points: points, values: line.values, minValue: minValue, maxValue: maxValue)
    }
    
    // Plot should be in 1x1 coordinates.
    func transformForApplyingPlot(_ plot: Plot, to path: Path, boundsHeight: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        
        // 1. Transform path to plot values.
        // 1.a Scale.
        let minValue = path.minValue ?? 0
        let maxValue = path.maxValue ?? 1
        let verticalRange = minValue != maxValue ? Double(maxValue - minValue) : 1
        transform = transform.concatenating(CGAffineTransform(scaleX: 1, y: CGFloat(verticalRange)))
        
        // 1.b Translate.
        let insetTop = plot.range.upperBound - maxValue
        transform = transform.concatenating(CGAffineTransform(translationX: 0, y: CGFloat(insetTop)))
        
        // 2. Transform plot values to fit bounds.
        let boundsScaleY = boundsHeight / CGFloat(max(1, plot.range.upperBound - plot.range.lowerBound))
        transform = transform.concatenating(CGAffineTransform(scaleX: 1, y: boundsScaleY))
        
        return transform
    }
    
    // Plot should be in 1x1 coordinates.
    func transformForApplyingRange(_ range: ClosedRange<CGFloat>, boundsWidth: CGFloat) -> CGAffineTransform {
        let scaleX = boundsWidth / (range.upperBound - range.lowerBound)
        return CGAffineTransform(scaleX: scaleX, y: 1)
    }
    
    func transformForValueLine(value: Int64, plot: Plot, boundsHeight: CGFloat) -> CGAffineTransform {
        let rangeLength = CGFloat(plot.range.upperBound - plot.range.lowerBound)
        let translateY = round(boundsHeight / rangeLength * CGFloat(value - plot.range.lowerBound))
        return CGAffineTransform(translationX: 0, y: -translateY)
    }

}

// Separate class.
extension TransformCalculator {
    
    // Path represents line in 1x1 coordinates.
    // Can be moved to background for optimization.
    func barPathForColumn(_ column: Column, isVisible: Bool, sum: StackBarSum) -> Path {
        let coordinateSystemSize = CGSize(width: 1, height: 1)
        let numberOfSegments = column.values.count
        let segmentWidth = Double(coordinateSystemSize.width) / Double(max(1, numberOfSegments))
        
        let minValue: Int64 = 0
        let maxValue = sum.maxValue ?? 1
        let verticalRange = minValue != maxValue ? Double(maxValue - minValue) : 1
        
        let points = column.values.enumerated().flatMap { index, value -> [CGPoint] in
            let x1 = Double(index) * segmentWidth
            let x2 = Double(index + 1) * segmentWidth
            let y = isVisible ? Double(coordinateSystemSize.height) * (1 - Double(value - minValue) / verticalRange) : 1
            return [CGPoint(x: x1, y: y), CGPoint(x: x2, y: y)]
        }
        
        return Path(points: points, values: column.values, minValue: minValue, maxValue: maxValue)
    }
    
    func transformForApplyingBarPlot(_ plot: Plot, to sum: StackBarSum, boundsHeight: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        
        // 1. Transform path to plot values.
        // 1.a Scale.
        let minValue: Int64 = 0
        let maxValue = sum.values.max() ?? 1
        let verticalRange = minValue != maxValue ? Double(maxValue - minValue) : 1
        transform = transform.concatenating(CGAffineTransform(scaleX: 1, y: CGFloat(verticalRange)))
        
        // 1.b Translate.
        let insetTop = plot.range.upperBound - maxValue
        transform = transform.concatenating(CGAffineTransform(translationX: 0, y: CGFloat(insetTop)))
        
        // 2. Transform plot values to fit bounds.
        let boundsScaleY = boundsHeight / CGFloat(max(1, plot.range.upperBound - plot.range.lowerBound))
        transform = transform.concatenating(CGAffineTransform(scaleX: 1, y: boundsScaleY))
        
        return transform
    }
    
}

// Separate class.
extension TransformCalculator {
    
    // Path represents line in 1x1 coordinates.
    // Can be moved to background for optimization.
    func percentPathForColumn(_ column: Column, isVisible: Bool, sum: StackBarSum) -> Path {
        let coordinateSystemSize = CGSize(width: 1, height: 1)
        let numberOfSegments = column.values.count - 1
        let segmentWidth = Double(coordinateSystemSize.width) / Double(max(1, numberOfSegments))

        let minValue: Int64 = 0
        let maxValue = sum.maxValue ?? 1
        let points = column.values.enumerated().map { index, value -> CGPoint in
            let x = Double(index) * segmentWidth
            let ySum = Double(sum.values[index])
            let y = isVisible ? Double(coordinateSystemSize.height) * (1 - Double(value - minValue) / ySum) : 1
            return CGPoint(x: x, y: y)
        }

        return Path(points: points, values: column.values, minValue: minValue, maxValue: maxValue)
    }
    
    func transformForApplyingPercentPlot(boundsHeight: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        
        // Transform plot values to fit bounds.
        let boundsScaleY = boundsHeight
        transform = transform.concatenating(CGAffineTransform(scaleX: 1, y: boundsScaleY))
        
        // http://www.raywenderlich.com/2033/core-graphics-101-lines-rectangles-and-gradients
        transform = transform.concatenating(CGAffineTransform(translationX: 0, y: -0.5))
        
        return transform
    }
    
}

extension TransformCalculator {
    func transformBetween(t1: CGAffineTransform, t2: CGAffineTransform, progress: CGFloat) -> CGAffineTransform {
        let a = t1.a * (1 - progress) + t2.a * progress
        let b = t1.b * (1 - progress) + t2.b * progress
        let c = t1.c * (1 - progress) + t2.c * progress
        let d = t1.d * (1 - progress) + t2.d * progress
        let tx = t1.tx * (1 - progress) + t2.tx * progress
        let ty = t1.ty * (1 - progress) + t2.ty * progress
        return CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
    }
}
