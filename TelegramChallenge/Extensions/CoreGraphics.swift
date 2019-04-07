//
//  Created by Timur Bernikovich on 22/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import CoreGraphics
import QuartzCore
import UIKit

extension CGAffineTransform {
    func transforming(to targetTransform: CGAffineTransform, with progress: CGFloat) -> CGAffineTransform {
        let a = self.a * (1 - progress) + targetTransform.a * progress
        let b = self.b * (1 - progress) + targetTransform.b * progress
        let c = self.c * (1 - progress) + targetTransform.c * progress
        let d = self.d * (1 - progress) + targetTransform.d * progress
        let tx = self.tx * (1 - progress) + targetTransform.tx * progress
        let ty = self.ty * (1 - progress) + targetTransform.ty * progress
        return CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
    }
}

extension CGAffineTransform {
    var transform3D: CATransform3D {
        return CATransform3DMakeAffineTransform(self)
    }
}

extension CATransform3D {
    var affineTransform: CGAffineTransform {
        return CATransform3DGetAffineTransform(self)
    }
}

extension CATransaction {
    static func performWithoutAnimation(_ closure: (() -> ())) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        closure()
        CATransaction.commit()
    }
}

extension CALayer {
    func add<Animation: CAAnimation>(_ animation: Animation, forKey key: String?,
                                      beginClosure: ((Animation) -> ())? = nil,
                                      completionClosure: ((Animation, Bool) -> ())? = nil) {
        let delegate = AnimationDelegate<Animation>()
        delegate.beginClosure = beginClosure
        delegate.completionClosure = completionClosure
        animation.delegate = delegate
        add(animation, forKey: key)
    }
}
extension CGFloat {
    static let epsilon: CGFloat = 0.00000001
}

extension CGPath {    
    func fittedToWidth(_ width: CGFloat) -> CGPath {
        let points = getPathElementsPoints()
        guard let max = points.map({ $0.x }).max(), max > CGFloat.epsilon else {
            return self
        }
        
        var transform = CGAffineTransform(scaleX: width / max, y: 1)
        return self.copy(using: &transform) ?? self
    }
    
    func transformingPolyline(to targetPolyline: CGPath, with progress: CGFloat) -> CGPath {
        let points = self.getPathElementsPoints()
        let targetPoints = targetPolyline.getPathElementsPoints()
        guard points.count == targetPoints.count else {
            return self
        }
        
        let transformedPoints: [CGPoint] = zip(points, targetPoints).map { point, targetPoint in
            let x: CGFloat = point.x * (1 - progress) + targetPoint.x * progress
            let y: CGFloat = point.y * (1 - progress) + targetPoint.y * progress
            return CGPoint(x: x, y: y)
        }
        
        let path = UIBezierPath()
        transformedPoints.enumerated().forEach { index, point in
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path.cgPath
    }
    
    private func forEach( body: @escaping @convention(block) (CGPathElement) -> Void) {
        typealias Body = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
            let body = unsafeBitCast(info, to: Body.self)
            body(element.pointee)
        }
        
        let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
        self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
    }
    private func getPathElementsPoints() -> [CGPoint] {
        var arrayPoints: [CGPoint]! = [CGPoint]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayPoints.append(element.points[2])
            default: break
            }
        }
        return arrayPoints
    }
}

fileprivate class AnimationDelegate<Animation: CAAnimation>: NSObject, CAAnimationDelegate {
    var beginClosure: ((Animation) -> ())?
    var completionClosure: ((Animation, Bool) -> ())?
    
    func animationDidStart(_ animation: CAAnimation) {
        if let animation = animation as? Animation {
            beginClosure?(animation)
        }
    }
    func animationDidStop(_ animation: CAAnimation, finished: Bool) {
        if let animation = animation as? Animation {
            completionClosure?(animation, finished)
        }
    }
}
