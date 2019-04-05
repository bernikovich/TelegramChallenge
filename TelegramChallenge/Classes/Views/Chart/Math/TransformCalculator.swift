//
//  Created by Timur Bernikovich on 19/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

struct Path {
    let points: [CGPoint]
    let values: [Int64]
}

extension Path {
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
}

class TransformCalculator {
    // Path represents line in 1x1 coordinates.
    func pathForLine(_ line: Line, coordinateSystemSize: CGSize = CGSize(width: 1, height: 1)) -> Path {
        let numberOfSegments = line.values.count - 1
        let segmentWidth = Double(coordinateSystemSize.width) / Double(max(1, numberOfSegments))
        
        let minValue = line.values.min() ?? 0
        let maxValue = line.values.max() ?? 1
        let verticalRange = minValue != maxValue ? Double(maxValue - minValue) : 1
        
        let points = line.values.enumerated().map { index, value -> CGPoint in
            let x = Double(index) * segmentWidth
            let y = Double(coordinateSystemSize.height) * (1 - Double(value - minValue) / verticalRange)
            return CGPoint(x: x, y: y)
        }
        
        return Path(points: points, values: line.values)
    }
    
    // Plot should be in 1x1 coordinates.
    func transformForApplyingPlot(_ plot: Plot, to path: Path, boundsHeight: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        
        // 1. Transform path to plot values.
        // 1.a Scale.
        let minValue = path.values.min() ?? 0
        let maxValue = path.values.max() ?? 1
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
        let translateY = ceil(boundsHeight / rangeLength * CGFloat(value - plot.range.lowerBound))
        return CGAffineTransform(translationX: 0, y: -translateY)
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
