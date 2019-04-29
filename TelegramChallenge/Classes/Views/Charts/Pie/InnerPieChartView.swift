//
//  Created by Timur Bernikovich on 15/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

struct PieSegment {
    let identifier: String
    let color: UIColor
    let value: CGFloat
}

extension Collection where Element : Numeric {
    func sum() -> Element {
        return reduce(0, +)
    }
}

class InnerPieChartView: BaseView, AppearanceSupport {
    
    private var segments: [PieSegment] = []
    private var sliceLayers: [PieChartSliceLayer] = []
    private var sliceLabels: [UILabel] = []
    
    // Make circle smooth.
    private let maskLayer = CAShapeLayer()
    
    private var awaitingForNextAnimation: Bool = false
    private var isAnimating: Bool = false
    
    private var lastSize: CGSize = .zero
    
    override func setup() {
        super.setup()
        
        subscribeToAppearanceUpdates()
        
        // For drawRect.
        isOpaque = false
        
        maskLayer.contentsScale = UIScreen.main.scale
        layer.mask = maskLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if lastSize != bounds.size {
            lastSize = bounds.size
            let circleSize = min(bounds.width, bounds.height) - 2
            let circleRect = CGRect(centeredOn: bounds.center, size: CGSize(width: circleSize, height: circleSize))
            let path = UIBezierPath(ovalIn: circleRect)
            maskLayer.path = path.cgPath
            
            sliceLayers.forEach {
                $0.frame = bounds
            }
            updateWithSegements(segments, animated: false)
        }
    }
    
    private func startNextAnimationIfNeeded() {
        if awaitingForNextAnimation {
            updateWithSegements(segments, animated: true)
        }
    }
    
    func updateWithSegements(_ newSegments: [PieSegment], animated: Bool) {
        let oldIdentifiers = segments.map { $0.identifier }
        let newIdentifier = newSegments.map { $0.identifier }
        segments = newSegments
        
        var animated = animated
        if oldIdentifiers != newIdentifier {
            animated = false
            redraw()
        }
        
        if isAnimating && animated {
            awaitingForNextAnimation = true
            return
        }
        if !animated {
            isAnimating = false
            awaitingForNextAnimation = false
        }
        
        CATransaction.begin()
        if animated {
            CATransaction.setAnimationDuration(SharedConstants.animationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            isAnimating = true
            CATransaction.setCompletionBlock { [weak self] in
                self?.isAnimating = false
                self?.startNextAnimationIfNeeded()
            }
        } else {
            CATransaction.setDisableActions(true)
        }
        
        let startAngle: CGFloat = -0.1 * CGFloat.pi
        var previousEndAngle = startAngle
        var sumSlicePart: CGFloat = 0
        
        let sum = segments.map { $0.value }.sum()
        var percents: [Int: Double] = [:]
        segments.enumerated().forEach { index, segment in
            if sum > 0 {
                percents[index] = Double(segment.value) / Double(sum) * 100
            } else {
                percents[index] = 0
            }
        }
        let normalizedPercents = PercentCalculator.normalizePercents(percents)
        
        segments.enumerated().forEach { index, segment in
            let layer = sliceLayers[index]
            let label = sliceLabels[index]
            let percent = normalizedPercents[index] ?? 0
            
            let slicePart = sum > 0 ? (segment.value / sum) : 0
            sumSlicePart += slicePart
            
            let endAngle = startAngle + 2 * CGFloat.pi * sumSlicePart
            let midAngle = (endAngle + previousEndAngle) / 2
            previousEndAngle = endAngle
            layer.startAngle = startAngle
            layer.endAngle = endAngle
            
            let minCenterOffset: CGFloat = 0.45
            let maxCenterOffset: CGFloat = 0.85
            let minScale: CGFloat = 1
            let maxScale: CGFloat = 0.24
            
            let labelPercent = 1 - min(1, max(0, slicePart * 3))
            let offset = minCenterOffset + (maxCenterOffset - minCenterOffset) * labelPercent
            let scale = minScale + (maxScale - minScale) * labelPercent
            let radius = min(bounds.height, bounds.width) / 2
            label.text = "\(percent)%"
            label.sizeToFit()
            
            if animated {
                UIView.animate(withDuration: SharedConstants.animationDuration, animations: {
                    label.alpha = percent > 0 ? 1 : 0
                    label.center = self.bounds.center.projected(by: radius * offset, angle: midAngle)
                    label.transform = CGAffineTransform(scaleX: scale, y: scale)
                })
            } else {
                label.layer.removeAllAnimations()
                label.alpha = percent > 0 ? 1 : 0
                label.center = bounds.center.projected(by: radius * offset, angle: midAngle)
                label.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
        
        CATransaction.commit()
    }
    
    private func redraw() {
        sliceLayers.forEach {
            $0.removeFromSuperlayer()
        }
        sliceLabels.forEach {
            $0.removeFromSuperview()
        }
        
        sliceLayers = segments.enumerated().map { index, segment in
            let layer = PieChartSliceLayer()
            layer.muchWow = index == 1
            layer.fillColor = segment.color
            layer.frame = bounds
            return layer
        }
        sliceLabels = segments.map { _ in
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
            return label
        }
        
        sliceLayers.forEach {
            layer.insertSublayer($0, at: 0)
        }
        sliceLabels.forEach {
            addSubview($0)
        }
        
        apply(theme: Appearance.theme)
        isAnimating = false
        awaitingForNextAnimation = false
    }
    
    func apply(theme: Theme) {
        sliceLabels.forEach {
            $0.textColor = .white
        }
    }
    
}

private class PieChartSliceLayer: CALayer {
    
    var fillColor: UIColor = .gray
    var muchWow: Bool = false
    
    @NSManaged var startAngle: CGFloat
    @NSManaged var endAngle: CGFloat
    
    override init() {
        super.init()
        contentsScale = UIScreen.main.scale
        setNeedsDisplay()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        contentsScale = UIScreen.main.scale
        if let layer = layer as? PieChartSliceLayer {
            startAngle = layer.startAngle
            endAngle = layer.endAngle
            fillColor = layer.fillColor
            muchWow = layer.muchWow
        }
        setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentsScale = UIScreen.main.scale
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        setNeedsDisplay()
    }
    
    override func action(forKey event: String) -> CAAction? {
        if event == #keyPath(PieChartSliceLayer.startAngle) || event == #keyPath(PieChartSliceLayer.endAngle) {
            return makeAnimation(for: event)
        }
        return super.action(forKey: event)
    }
    
    private func makeAnimation(for key: String) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: key)
        animation.fromValue = presentation()?.value(forKey: key)
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = SharedConstants.animationDuration
        return animation
    }
    
    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(PieChartSliceLayer.startAngle) || key == #keyPath(PieChartSliceLayer.endAngle) {
            return true
        }
        
        return super.needsDisplay(forKey: key)
    }
    
    override func draw(in ctx: CGContext) {
        if muchWow {
            print("\(self)")
            print("start: \(startAngle)")
            print("end: \(endAngle)")
            print("---")
        }
        
        let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        let radius = min(center.x, center.y)
        
        ctx.beginPath()
        ctx.move(to: center)
        
        let point1 = CGPoint(x: center.x + radius * cos(startAngle), y: center.y + radius * sin(startAngle))
        ctx.addLine(to: point1)
        
        let clockswise = startAngle > endAngle
        ctx.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockswise)
        ctx.closePath()
        
        ctx.setFillColor(fillColor.cgColor)
        ctx.drawPath(using: .fill)
    }

}
