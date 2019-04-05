//
//  Created by Timur Bernikovich on 12/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class ChartAnimation: CABasicAnimation {
    var scheduled: TimeInterval = 0
    var startCallbackTimestamp: TimeInterval = 0
    var isStarted: Bool = false
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        if let chartAnimation = copy as? ChartAnimation {
            chartAnimation.scheduled = scheduled
            chartAnimation.startCallbackTimestamp = startCallbackTimestamp
            chartAnimation.isStarted = isStarted
        }
        return copy
    }
}

class ChartLineLayer: CAShapeLayer {
    var runningAnimation: ChartAnimation? {
        return runningAnimations.first
    }
    var runningAnimations: [ChartAnimation] = []
    func animationStarted(_ animation: ChartAnimation) {
        animation.startCallbackTimestamp = convertTime(CACurrentMediaTime(), from: nil)
        runningAnimations.append(animation)
    }
    func animationFinished(_ animation: ChartAnimation) {
        if let index = runningAnimations.firstIndex(where: { $0 == animation }) {
            runningAnimations.remove(at: index)
        }
    }
}

final class ChartView: BaseView {
    
    var isSimple = false
    
    private(set) var chart: Chart = .empty
    private(set) var visibleLines: [Line] = []
    private(set) var range: ClosedRange<CGFloat> = 0...1
    private(set) var lastKnownSize: CGSize = .zero
    
    // Containers for plot.
    // We display lines on background and text on foreground.
    private let backgroundPlotContainerView = UIView()
    private let foregroundPlotContainerView = UIView()
    
    // Containers for chart lines.
    // Used as UIScrollView but without roundsing offset to pixels.
    private let linesContainerCropView = UIView()
    private let linesContainerView = UIView()
    
    private var plotLineLayers: [PlotItemLayer] = []
    
    private var linePaths: [CGPath] = []
    private var lineLayers: [ChartLineLayer] = []
    
    private let plotCalculator = PlotCalculator(numberOfSteps: 5.5) // According to provided screenshots.
    private var plot: Plot?
    private var oldPlot: Plot?
    
    private let transformCalculator = TransformCalculator()
    private var valueBoxHandler: ChartValueBoxHandler?
    
    // https://stackoverflow.com/questions/41904724/using-available-with-stored-properties
    private var storedFeedbackGenerator: Any?
    @available(iOS 10.0, *)
    private var feedbackGenerator: UISelectionFeedbackGenerator {
        if let generator = storedFeedbackGenerator as? UISelectionFeedbackGenerator {
            return generator
        }

        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        storedFeedbackGenerator = generator
        return generator
    }
    
    override func setup() {
        super.setup()
        
        addSubview(backgroundPlotContainerView)
        backgroundPlotContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundPlotContainerView.frame = bounds
        
        addSubview(linesContainerCropView)
        linesContainerCropView.clipsToBounds = true
        linesContainerCropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        linesContainerCropView.frame = bounds
        
        linesContainerCropView.addSubview(linesContainerView)
        linesContainerView.autoresizingMask = []
        
        addSubview(foregroundPlotContainerView)
        foregroundPlotContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        foregroundPlotContainerView.frame = bounds

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        foregroundPlotContainerView.addGestureRecognizer(panGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        foregroundPlotContainerView.addGestureRecognizer(tapGesture)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if lastKnownSize != bounds.size {
            redrawAll(animated: lastKnownSize != .zero)
            lastKnownSize = bounds.size
        }
    }

    func clear() {
        hideValueBox(animated: false)
        visibleLines = []
        plotLineLayers.forEach { $0.removeFromSuperlayer() }
        plotLineLayers = []
        lineLayers.forEach { $0.removeFromSuperlayer() }
        lineLayers = []
        linePaths = []
        plot = nil
        oldPlot = nil
    }
    
    func setupWithChart(_ chart: Chart, in range: ClosedRange<CGFloat> = 0...1, animated: Bool) {
        self.chart = chart
        self.visibleLines = chart.lines
        self.range = range
        self.plotCalculator.updatePreloadedPlots(lines: visibleLines)
        
        redrawAll(animated: animated)
    }
    
    func setupVisibleLines(_ visibleLines: [Line], animated: Bool = true) {
        guard self.visibleLines != visibleLines else {
            return
        }
        
        hideValueBox(animated: animated)
        self.visibleLines = visibleLines
        
        let hasData = !visibleLines.isEmpty
        UIView.animate(withDuration: animated ? SharedConstants.animationDuration : 0) {
            zip(self.chart.lines, self.lineLayers).forEach { line, layer in
                layer.opacity = visibleLines.contains(line) ? 1 : 0
            }
        }

        if hasData {
            self.plotCalculator.updatePreloadedPlots(lines: visibleLines)
            updateWithRange(range, forceReload: true, animated: animated)
        }
    }
    
    func updateWithRange(_ range: ClosedRange<CGFloat>, forceReload: Bool, animated: Bool) {
        // We hide value box on each range update.
        hideValueBox(animated: animated)

        // Redraw plot if needed.
        let lengthDelta = abs((self.range.upperBound - self.range.lowerBound) - (range.upperBound - range.lowerBound))
        if self.range != range || forceReload {
            self.range = range
            if updatePlot() {
                redrawVerticalPlot(animated: animated)
            }
        }

        // Update view that holds all chart line layers.
        let rangeLength = range.upperBound - range.lowerBound
        let chartWidth = ceil(Double(bounds.width) / Double(rangeLength))
        let offsetX = chartWidth * Double(range.lowerBound)
        linesContainerView.frame = CGRect(origin: CGPoint(x: -offsetX, y: 0), size: CGSize(width: chartWidth, height: Double(bounds.height)))

        guard let plot = plot, lengthDelta > CGFloat.Magnitude.leastNonzeroMagnitude || forceReload || oldPlot != plot else {
            // No changes.
            return
        }

        let key = "pathAnimation"
        func createBasicAnimation() -> ChartAnimation {
            let animation = ChartAnimation()
            animation.keyPath = "path"
            animation.duration = SharedConstants.animationDuration
            animation.timingFunction = SharedConstants.timingFunction
            return animation
        }
        func start(_ animation: ChartAnimation, on layer: ChartLineLayer) {
            layer.add(animation, forKey: key, beginClosure: { [weak layer] animation in
                animation.isStarted = true
                layer?.animationStarted(animation)
            }, completionClosure: { [weak layer] animation, _ in
                layer?.animationFinished(animation)
            })
        }

        // All horizontal changes should be applied without animation.
        // But we should handle the case when animation is running already.
        CATransaction.begin()
        chart.lines.enumerated().forEach { index, line in
            let layer = lineLayers[index]
            let originalPath = linePaths[index]
            let supaPath = transformCalculator.pathForLine(line)
            
            // If layer is not visible and doesn't have hiding animation.
            var shouldStartNewAnimation = oldPlot != plot && animated
            if !visibleLines.contains(line) && layer.opacity == 0 && (layer.animationKeys()?.isEmpty ?? true) {
                shouldStartNewAnimation = false
            }

            // Calculate new transformation.
            var horizontalTransform = transformCalculator.transformForApplyingRange(range, boundsWidth: bounds.width)
            let verticalTransform = transformCalculator.transformForApplyingPlot(plot, to: supaPath, boundsHeight: bounds.height)
            var transform = horizontalTransform.concatenating(verticalTransform)
            let newPath = originalPath.copy(using: &transform)

            // Visible path.
            let visiblePath = (layer.presentation() ?? layer).path?.fittedToWidth(1)
            let updatedVisiblePath = visiblePath?.copy(using: &horizontalTransform)
            
            // Check if there is currently runnning animation.
            let oldAnimation = layer.animation(forKey: key) as? ChartAnimation
            if oldAnimation != nil || shouldStartNewAnimation {
                let animation = createBasicAnimation()
                let layerTime = layer.convertTime(CACurrentMediaTime(), from: nil)
                animation.scheduled = layerTime
                animation.startCallbackTimestamp = layerTime
                animation.fromValue = updatedVisiblePath
                animation.toValue = newPath
                CATransaction.performWithoutAnimation {
                    layer.path = newPath
                }
                
                // CAAnimation doesn't update presentation instantly.
                // It mean that presentation layer can update
                // properties with delay.
                var shouldRemoveAnimation = false
                if let runningAnimation = layer.runningAnimation, !shouldStartNewAnimation {
                    // I tried here all (scheduled, startedTimestamp, beginTime,
                    // converted to CALayer's time beginTime).
                    // It looks like scheduled is the nearest value to
                    // the onscreen presentation.
                    let animationStarted = runningAnimation.scheduled
                    let elapsedTime = layerTime - animationStarted
                    var progress = elapsedTime / runningAnimation.duration
                    progress = min(1, max(0, progress))
                    
                    // Interpolate possible real value based on
                    // time animation start, it's duration and from/to values.
                    let fromValue = runningAnimation.fromValue as! CGPath
                    let toValue = runningAnimation.toValue as! CGPath
                    let visiblePath = fromValue.transformingPolyline(to: toValue, with: CGFloat(progress)).fittedToWidth(1)
                    let updatedVisiblePath = visiblePath.copy(using: &horizontalTransform)
                    animation.fromValue = updatedVisiblePath
                    
                    // NOTE: Shit is here.
                    // Old phones cannot animate path with large number
                    // of points correctly. Presentation layer delays updates too much.
                    let timeLeft = runningAnimation.duration - elapsedTime
                    let fastDevice = UIDevice.current.userInterfaceIdiom == .phone && min(UIScreen.main.bounds.height, UIScreen.main.bounds.width) > 320
                    if line.values.count < 300 || fastDevice {
                        animation.duration = timeLeft
                    }
                    
                    if timeLeft < 0 {
                        shouldRemoveAnimation = true
                    }
                }

                // Animation is already finished.
                if shouldRemoveAnimation {
                    layer.removeAnimation(forKey: key)
                } else {
                    start(animation, on: layer)
                }
            } else {
                layer.removeAnimation(forKey: key)
                CATransaction.performWithoutAnimation {
                    layer.path = newPath
                }
            }
        }
        CATransaction.commit()
    }
    
    func redrawAll(animated: Bool) {
        updatePlot()
        redrawVerticalPlot(animated: animated)
        redrawLines()
        updateWithRange(range, forceReload: false, animated: animated)
    }
    
    @discardableResult
    private func updatePlot() -> Bool {
        let newPlot = plotCalculator.verticalPlot(for: range)
        if newPlot == plot {
            oldPlot = plot
            return false
        }
        
        oldPlot = plot
        plot = newPlot
        return true
    }
    
    func redrawLines() {
        guard let plot = plot else {
            return
        }
        
        lineLayers.forEach {
            $0.removeFromSuperlayer()
        }
        
        lineLayers = []
        linePaths = []
        
        chart.lines.forEach { line in
            let lineLayer = ChartLineLayer()
            lineLayer.lineJoin = .round
            lineLayer.lineCap = .round
            lineLayer.lineWidth = isSimple ? 1 : 2
            lineLayer.strokeColor = UIColor(hexString: line.colorHex).cgColor
            lineLayer.fillColor = nil
            lineLayer.frame = CGRect(origin: .zero, size: linesContainerView.bounds.size)
            lineLayer.opacity = visibleLines.contains(line) ? 1 : 0
            linesContainerView.layer.insertSublayer(lineLayer, at: 0)
            
            let path = transformCalculator.pathForLine(line)
            let verticalTransform = transformCalculator.transformForApplyingPlot(plot, to: path, boundsHeight: bounds.size.height)
            let horizontalTransform = transformCalculator.transformForApplyingRange(range, boundsWidth: bounds.size.width)
            var transform = verticalTransform.concatenating(horizontalTransform)
            lineLayer.path = path.cgPath.copy(using: &transform)
            
            lineLayers.append(lineLayer)
            linePaths.append(path.cgPath)
        }
    }
    
    private func redrawVerticalPlot(animated: Bool) {
        guard let plot = plot, !isSimple else {
            return
        }

        if !animated {
            plotLineLayers.forEach {
                $0.removeFromSuperlayer()
            }
            plotLineLayers.removeAll()
        }
        let hiddenLayers = plotLineLayers.filter { $0.text.opacity == 0 }
        hiddenLayers.forEach {
            $0.removeFromSuperlayer()
        }
        plotLineLayers.removeAll { hiddenLayers.map({ $0.text }).contains($0.text) }

        let oldLineValues = plotLineLayers.map { $0.value }
        let missingValues = plot.lineValues.filter {
            !oldLineValues.contains($0)
        }
        
        let neededLineLayers = plotLineLayers.filter { plot.lineValues.contains($0.value) }
        let unneededLineLayers = plotLineLayers.filter { !plot.lineValues.contains($0.value) }
        let newLineLayers: [PlotItemLayer] = missingValues.map {
            let text = PlotTextLayer(value: $0)
            let line = PlotLineLayer(value: $0)
            text.opacity = 0
            line.opacity = 0
            line.isOpaque = true
            line.zPosition = CGFloat($0)
            backgroundPlotContainerView.layer.addSublayer(line)
            foregroundPlotContainerView.layer.addSublayer(text)
            return PlotItemLayer(text: text, line: line)
        }
        plotLineLayers += newLineLayers
        
        let allLineLayers = (neededLineLayers + unneededLineLayers + newLineLayers)
        
        // Update frames.
        // TODO: Need to think about ChartView frame update too.
        let height = ceil(bounds.height / CGFloat(plot.range.upperBound - plot.range.lowerBound) * CGFloat(plot.step))
        allLineLayers.forEach {
            func applyTransform(to layer: CALayer) {
                let oldTransform = layer.transform
                layer.transform = CATransform3DIdentity
                layer.frame = CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
                layer.transform = oldTransform
            }
            applyTransform(to: $0.text)
            applyTransform(to: $0.line)
        }
        
        allLineLayers.forEach { lineItemLayer in
            let transformToValue = transformCalculator.transformForValueLine(value: lineItemLayer.text.value, plot: plot, boundsHeight: bounds.height).transform3D
            guard animated else {
                lineItemLayer.apply(opacity: 1)
                lineItemLayer.apply(transform: transformToValue)
                return
            }
            let isNew = newLineLayers.map({ $0.text }).contains(lineItemLayer.text)
            let isUnneeded = unneededLineLayers.map({ $0.text }).contains(lineItemLayer.text)
            
            var animations: [CAAnimation] = []
            
            let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
            
            let opacityFromValue: Float = isNew ? 0.1 : (lineItemLayer.text.presentation() ?? lineItemLayer.text).opacity
            let opacityToValue: Float = isUnneeded ? 0 : 1
            let opacityMidValue: Float = isNew ? 0.4 : opacityToValue
            
            opacityAnimation.values = [opacityFromValue, opacityMidValue, opacityToValue]
            opacityAnimation.keyTimes = [0, 0.5, 1]
            animations.append(opacityAnimation)

            let transformAnimation = CAKeyframeAnimation(keyPath: "transform")
            let previousValue = transformCalculator.transformForValueLine(value: lineItemLayer.value, plot: oldPlot ?? plot, boundsHeight: bounds.height).transform3D
            let transformFromValue = isNew ? previousValue : (lineItemLayer.text.presentation() ?? lineItemLayer.text).transform
            transformAnimation.values = [transformFromValue, transformToValue]
            transformAnimation.keyTimes = [0, 1]
            animations.append(transformAnimation)
            
            CATransaction.performWithoutAnimation {
                lineItemLayer.apply(opacity: opacityToValue)
                lineItemLayer.apply(transform: transformToValue)
            }
            
            let animation = CAAnimationGroup()
            animation.animations = animations
            animation.duration = SharedConstants.animationDuration
            animation.timingFunction = SharedConstants.timingFunction
            lineItemLayer.text.add(animation, forKey: "appearanceAnimation")
            lineItemLayer.line.add(animation, forKey: "appearanceAnimation")
        }
    }
}

private extension ChartView {

    func hideValueBox(animated: Bool) {
        valueBoxHandler?.hide(animated: animated)
        valueBoxHandler = nil
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        if valueBoxHandler == nil {
            updateBoxView(state: .began, gesture: gesture)
        } else {
            hideValueBox(animated: true)
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        updateBoxView(state: gesture.state, gesture: gesture)
    }

    private func updateBoxView(state: UIGestureRecognizer.State, gesture: UIGestureRecognizer) {
        guard let plot = plot, !isSimple, let parent = superview else {
            return
        }
        let location = gesture.location(in: linesContainerView)
        let index = Int(round((location.x / linesContainerView.frame.width) * CGFloat(chart.legend.values.count - 1)))
        let safeIndex = (0...(chart.legend.values.count - 1)).clamp(index)
        let x = gesture.location(in: parent).x

        weak var weakSelf = self
        func update(handler: ChartValueBoxHandler) {
            let box = handler.box
            let newDate = chart.legend.values[safeIndex]
            let updated = box.lastDate != newDate
            box.update(date: newDate, lines: visibleLines, index: safeIndex)
            let clampedX = ((box.frame.width / 2 + 4)...(parent.frame.width - 4 - box.frame.width / 2)).clamp(x)
            box.center = CGPoint(x: clampedX, y: box.frame.height / 2 + 8)

            let lineX = (CGFloat(safeIndex) / CGFloat(chart.legend.values.count - 1)) * linesContainerView.frame.width
            let line = handler.line
            line.frame.size.height = linesContainerView.frame.height
            line.center = CGPoint(x: lineX, y: linesContainerView.frame.height / 2)
            line.setupWithLines(visibleLines, index: safeIndex, range: plot.range)
            
            if #available(iOS 10.0, *) {
                if updated {
                    weakSelf?.feedbackGenerator.selectionChanged()
                }
            }
        }

        switch state {
        case .began:
            valueBoxHandler?.hide(animated: true)
            let handler = ChartValueBoxHandler()
            valueBoxHandler = handler
            parent.addSubview(handler.box)
            linesContainerView.addSubview(handler.line)
            update(handler: handler)
            handler.show()
        case .changed:
            guard let handler = valueBoxHandler else {
                return
            }
            update(handler: handler)
        case .cancelled, .ended, .failed, .possible:
            valueBoxHandler?.hide(animated: true)
            break
        @unknown default:
            break
        }
    }

}

extension ChartView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let translation = pan.translation(in: pan.view)
        return abs(translation.x) > abs(translation.y)
    }
}

extension Line {
    func valuesInRange(_ range: ClosedRange<CGFloat>) -> [Int64] {
        let length = CGFloat(values.count)
        let lowerBound = Int(range.lowerBound * length)
        let upperBound = min(values.count, Int(range.upperBound * length))
        return Array(values[lowerBound..<upperBound])
    }
}

extension ChartView: AppearanceSupport {
    func apply(theme: Theme) {
        backgroundColor = theme.main
        plotLineLayers.forEach {
            $0.text.apply(theme: theme)
            $0.line.apply(theme: theme)
        }
    }
}
