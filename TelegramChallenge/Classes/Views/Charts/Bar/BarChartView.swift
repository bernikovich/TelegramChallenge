//
//  Created by Timur Bernikovich on 08/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class BarChartView: BaseChartView, ChartView {
    
    private var plotLineLayers: [PlotLineLayer] = []
    
    private var columnPaths: [Path] = []
    private var columnLayers: [ChartColumnLayer] = []
    
    private var biggestColumnLayer: ChartColumnLayer?
    private let fadeLayer = ChartColumnLayer()
    private let fadeMaskLayer: ChartColumnLayer = {
        let layer = ChartColumnLayer()
        return layer
    }()
        
    // According to provided screenshots.
    private lazy var plotCalculator = PlotCalculator(numberOfSteps: SharedConstants.numberOfPlotLines,
                                                     numberOfChunks: isSimple ? 1 : 20,
                                                     zeroOrigin: true)
    
    private var stackBarSum: StackBarSum = StackBarSum(values: [], minValue: nil, maxValue: nil)
    private var plot: Plot?
    private var oldPlot: Plot?
    
    private let transformCalculator = TransformCalculator()
    private var valueBoxHandler: ValueBoxViewTransitionsHandler?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if lastKnownSize != bounds.size {
            redrawAll(animated: lastKnownSize != .zero)
            lastKnownSize = bounds.size
        }
    }
    
    func clear() {
        hideValueBox(animated: false)
        visibleColumns = []
        plotLineLayers.forEach { $0.removeFromSuperlayer() }
        plotLineLayers = []
        columnLayers.forEach { $0.removeFromSuperlayer() }
        columnLayers = []
        columnPaths = []
        plot = nil
        oldPlot = nil
    }
    
    func setupWithChart(_ chart: Chart, in range: ClosedRange<CGFloat> = 0...1, animated: Bool) {
        self.chart = chart
        self.visibleColumns = chart.columns
        self.range = range
        plotCalculator.updatePreloadedPlots(sum: stackBarSum)
        
        redrawAll(animated: animated)
    }
    
    func setupVisibleColumns(_ visibleColumns: [Column], animated: Bool = true) {
        guard self.visibleColumns != visibleColumns else {
            return
        }
        
        hideValueBox(animated: animated)
        self.visibleColumns = visibleColumns
        
        updatePaths()
        
        let hasData = !visibleColumns.isEmpty
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(animated ? SharedConstants.animationDuration : 0)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        for index in 0..<chart.columns.count {
            let layer = columnLayers[index]
            let path = columnPaths[index]
            
            let key = "pathAnimation"
            let animation = CABasicAnimation()
            animation.keyPath = "path"
            animation.fromValue = (layer.presentation() ?? layer).path
            animation.toValue = path.barCGPath
            animation.duration = animated ? SharedConstants.animationDuration : 0
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            if animated {
                layer.add(animation, forKey: key)
            }
            CATransaction.performWithoutAnimation {
                layer.path = path.barCGPath
            }
            
            if layer == biggestColumnLayer {
                if animated {
                    fadeLayer.add(animation, forKey: key)
                }
                CATransaction.performWithoutAnimation {
                    fadeLayer.path = path.barCGPath
                }
            }
        }
        CATransaction.commit()
        
        if hasData {
            plotCalculator.updatePreloadedPlots(sum: stackBarSum)
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
        
        let contentBounds = contentView.bounds
        
        // Update view that holds all chart line layers.
        let rangeLength = range.upperBound - range.lowerBound
        let chartWidth = ceil(Double(contentBounds.width) / Double(rangeLength))
        let offsetX = chartWidth * Double(range.lowerBound)
        columnsContainerView.frame = CGRect(
            origin: CGPoint(x: -offsetX, y: 0),
            size: CGSize(width: chartWidth, height: Double(contentBounds.height))
        )
        
        guard let plot = plot, lengthDelta > CGFloat.Magnitude.leastNonzeroMagnitude || forceReload || oldPlot != plot else {
            // No changes.
            return
        }

        let key = "transformAnimation"
        func createBasicAnimation() -> ChartAnimation {
            let animation = ChartAnimation()
            animation.keyPath = "transform"
            animation.duration = SharedConstants.animationDuration
            animation.timingFunction = SharedConstants.timingFunction
            return animation
        }
        func start(_ animation: ChartAnimation, on layer: ChartColumnLayer) {
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
        chart.columns.enumerated().forEach { index, line in
            let layer = columnLayers[index]

            // If layer is not visible and doesn't have hiding animation.
            var shouldStartNewAnimation = oldPlot != plot && animated || forceReload && animated
            if !visibleColumns.contains(line) && layer.opacity == 0 && (layer.animationKeys()?.isEmpty ?? true) {
                shouldStartNewAnimation = false
            }

            // Calculate new transformation.
            let horizontalTransform = transformCalculator.transformForApplyingRange(range, boundsWidth: contentBounds.width)
            let verticalTransform = transformCalculator.transformForApplyingBarPlot(plot, to: stackBarSum, boundsHeight: contentBounds.height)
            let transform = horizontalTransform.concatenating(verticalTransform)

            // Visible path.
            let visibleTransform = (layer.presentation() ?? layer).transform.affineTransform
            let updatedVisibleTransform = visibleTransform.applyingHorizontalTransform(horizontalTransform)

            // Check if there is currently runnning animation.
            let oldAnimation = layer.animation(forKey: key) as? ChartAnimation
            if oldAnimation != nil || shouldStartNewAnimation {
                let animation = createBasicAnimation()
                let layerTime = layer.convertTime(CACurrentMediaTime(), from: nil)
                animation.scheduled = layerTime
                animation.startCallbackTimestamp = layerTime
                animation.fromValue = updatedVisibleTransform.transform3D
                animation.toValue = transform.transform3D

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
                    let fromValue = (runningAnimation.fromValue as! CATransform3D).affineTransform
                    let toValue = (runningAnimation.toValue as! CATransform3D).affineTransform
                    let visibleTransform = fromValue.transforming(to: toValue, with: CGFloat(progress))
                    let updatedVisibleTransform = visibleTransform.applyingHorizontalTransform(horizontalTransform)
                    animation.fromValue = updatedVisibleTransform.transform3D

                    // NOTE: Shit is here.
                    // Old phones cannot animate path with large number
                    // of points correctly. Presentation layer delays updates too much.
                    let timeLeft = runningAnimation.duration - elapsedTime
                    if line.values.count < 300 || !UIDevice.isOld {
                        animation.duration = timeLeft
                    }

                    if timeLeft < 0 {
                        shouldRemoveAnimation = true
                    }
                }

                // Animation is already finished.
                CATransaction.performWithoutAnimation {
                    layer.transform = transform.transform3D
                }
                if shouldRemoveAnimation {
                    layer.removeAnimation(forKey: key)
                } else {
                    start(animation, on: layer)
                }
                
                if layer == biggestColumnLayer {
                    CATransaction.performWithoutAnimation {
                        fadeLayer.transform = transform.transform3D
                    }
                    if shouldRemoveAnimation {
                        fadeLayer.removeAnimation(forKey: key)
                    } else {
                        start(animation, on: fadeLayer)
                    }
                }
            } else {
                layer.removeAnimation(forKey: key)
                CATransaction.performWithoutAnimation {
                    layer.transform = transform.transform3D
                }
                if layer == biggestColumnLayer {
                    fadeLayer.removeAnimation(forKey: key)
                    CATransaction.performWithoutAnimation {
                        fadeLayer.transform = transform.transform3D
                    }
                }
            }
        }
        CATransaction.commit()
    }
    
    func redrawAll(animated: Bool) {
        updatePaths()
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
        
        columnLayers.forEach {
            $0.removeFromSuperlayer()
        }
        
        columnLayers = []
        updatePaths()
        
        chart.columns.enumerated().forEach { index ,column in
            let columnLayer = ChartColumnLayer()
            columnLayer.strokeColor = nil
            columnLayer.fillColor = UIColor(hexString: column.colorHex).cgColor
            columnLayer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
            columnLayer.opacity = visibleColumns.contains(column) ? 1 : 0
            columnLayer.anchorPoint = .zero
            columnsContainerView.layer.insertSublayer(columnLayer, at: 0)
            
            let path = columnPaths[index]
            columnLayer.path = path.barCGPath
            
            let verticalTransform = transformCalculator.transformForApplyingBarPlot(plot, to: stackBarSum, boundsHeight: contentView.bounds.size.height)
            let horizontalTransform = transformCalculator.transformForApplyingRange(range, boundsWidth: contentView.bounds.size.width)
            let transform = verticalTransform.concatenating(horizontalTransform)
            columnLayer.transform = transform.transform3D
            
            columnLayers.append(columnLayer)
        }
        
        biggestColumnLayer = columnLayers.last
        if let biggestColumnLayer = biggestColumnLayer, isSimple == false {
            fadeLayer.position = biggestColumnLayer.position
            fadeLayer.bounds = biggestColumnLayer.bounds
            fadeLayer.anchorPoint = .zero
            fadeLayer.path = biggestColumnLayer.path
            fadeLayer.transform = biggestColumnLayer.transform
            columnsContainerView.layer.addSublayer(fadeLayer)
            
            fadeMaskLayer.position = fadeLayer.position
            fadeMaskLayer.bounds = fadeLayer.bounds
            fadeLayer.mask = fadeMaskLayer
        }
    }
    
    private func updatePaths() {
        // We expect each column to have exactly same length as others.
        // Should be updated when visible columns change.
        var sumValues = [Int64](repeating: 0, count: chart.legend.values.count)
        for index in 0..<visibleColumns.count {
            let column = visibleColumns[index]
            column.values.enumerated().forEach {
                sumValues[$0.offset] += $0.element
            }
        }
        let stackBarSum = StackBarSum(values: sumValues, minValue: sumValues.min(), maxValue: sumValues.max())
        self.stackBarSum = stackBarSum
        
        var previousPath: Path?
        columnPaths = chart.columns.map {
            let isVisible = visibleColumns.contains($0)
            var path = transformCalculator.barPathForColumn($0, isVisible: isVisible, sum: stackBarSum)
            if let previousPath = previousPath {
                path = path.stackWithPath(previousPath)
            }
            previousPath = path
            return path
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
        let hiddenLayers = plotLineLayers.filter { $0.opacity == 0 }
        hiddenLayers.forEach {
            $0.removeFromSuperlayer()
        }
        plotLineLayers.removeAll { hiddenLayers.contains($0) }
        
        let oldLineValues = plotLineLayers.map { $0.value }
        let missingValues = plot.lineValues.filter {
            !oldLineValues.contains($0)
        }
        
        let neededLineLayers = plotLineLayers.filter { plot.lineValues.contains($0.value) }
        let unneededLineLayers = plotLineLayers.filter { !plot.lineValues.contains($0.value) }
        let newLineLayers: [PlotLineLayer] = missingValues.map {
            let layer = PlotLineLayer(value: $0, chartType: .bars)
            layer.opacity = 0
            layer.zPosition = CGFloat($0)
            plotContainerView.layer.addSublayer(layer)
            return layer
        }
        plotLineLayers += newLineLayers
        
        let allLineLayers = (neededLineLayers + unneededLineLayers + newLineLayers)
        
        // Update frames.
        // TODO: Need to think about ChartView frame update too.
        let height = ceil(plotContainerView.bounds.height / CGFloat(plot.range.upperBound - plot.range.lowerBound) * CGFloat(plot.step))
        allLineLayers.forEach { layer in
            let oldTransform = layer.transform
            layer.transform = CATransform3DIdentity
            layer.frame = CGRect(
                x: 0,
                y: plotContainerView.bounds.height - height,
                width: plotContainerView.bounds.width,
                height: height
            )
            layer.transform = oldTransform
        }
        
        allLineLayers.forEach { linePlotLayer in
            let transformToValue = transformCalculator.transformForValueLine(value: linePlotLayer.value, plot: plot, boundsHeight: plotContainerView.bounds.height).transform3D
            guard animated else {
                linePlotLayer.opacity = 1
                linePlotLayer.transform = transformToValue
                return
            }
            let isNew = newLineLayers.contains(linePlotLayer)
            let isUnneeded = unneededLineLayers.contains(linePlotLayer)
            
            var animations: [CAAnimation] = []
            
            let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
            
            let opacityFromValue: Float = isNew ? 0.1 : (linePlotLayer.presentation() ?? linePlotLayer).opacity
            let opacityToValue: Float = isUnneeded ? 0 : 1
            let opacityMidValue: Float = isNew ? 0.4 : opacityToValue
            
            opacityAnimation.values = [opacityFromValue, opacityMidValue, opacityToValue]
            opacityAnimation.keyTimes = [0, 0.5, 1]
            animations.append(opacityAnimation)
            
            let transformAnimation = CAKeyframeAnimation(keyPath: "transform")
            let previousValue = transformCalculator.transformForValueLine(value: linePlotLayer.value, plot: oldPlot ?? plot, boundsHeight: plotContainerView.bounds.height).transform3D
            let transformFromValue = isNew ? previousValue : (linePlotLayer.presentation() ?? linePlotLayer).transform
            transformAnimation.values = [transformFromValue, transformToValue]
            transformAnimation.keyTimes = [0, 1]
            animations.append(transformAnimation)
            
            CATransaction.performWithoutAnimation {
                linePlotLayer.opacity = opacityToValue
                linePlotLayer.transform = transformToValue
            }
            
            let animation = CAAnimationGroup()
            animation.animations = animations
            animation.duration = SharedConstants.animationDuration
            animation.timingFunction = SharedConstants.timingFunction
            linePlotLayer.add(animation, forKey: "appearanceAnimation")
        }
    }
    
    @objc override func handleTap(_ gesture: UITapGestureRecognizer) {
        if valueBoxHandler == nil {
            updateBoxView(state: .began, gesture: gesture)
        } else {
            hideValueBox(animated: true)
        }
    }
    
    @objc override func handlePan(_ gesture: UIPanGestureRecognizer) {
        updateBoxView(state: gesture.state, gesture: gesture)
    }

}

private extension BarChartView {
    
    func hideValueBox(animated: Bool) {
        fadeLayer.opacity = 0
        valueBoxHandler?.hide(animated: animated)
        valueBoxHandler = nil
    }
    
    private func updateBoxView(state: UIGestureRecognizer.State, gesture: UIGestureRecognizer) {
        guard let plot = plot, !isSimple else {
            return
        }
        
        let parent = self
        let location = gesture.location(in: columnsContainerView)
        let index = Int(round((location.x / columnsContainerView.frame.width) * CGFloat(chart.legend.values.count - 1)))
        let indexRange = chart.legend.indexRange(for: range)
        let safeIndex = indexRange.clamp(index)
        let x = gesture.location(in: parent).x
        
        let pointWidth = CGFloat(1) / CGFloat(chart.legend.values.count)
        let maskRect = CGRect(x: CGFloat(safeIndex) * pointWidth, y: 0, width: pointWidth, height: 1)
        let path = UIBezierPath(rect: maskRect)
        path.append(UIBezierPath(rect: fadeMaskLayer.bounds))
        fadeMaskLayer.fillRule = .evenOdd
        fadeMaskLayer.path = path.cgPath
        
        weak var weakSelf = self
        func update(handler: ValueBoxViewTransitionsHandler) {
            let view = handler.view
            let newDate = chart.legend.values[safeIndex]
            let oldDate = view.lastDate
            let updated = oldDate != newDate
            view.update(date: newDate, columns: visibleColumns, index: safeIndex)
            
            let isPresenting = oldDate == nil
            let range = plot.range
            let delta = CGFloat(range.upperBound - range.lowerBound)
            let linePercent = CGFloat(stackBarSum.values[safeIndex] - range.lowerBound) / delta
            
            ValueBoxViewPositionHandler.updatePosition(
                of: view,
                in: parent,
                isPresenting: isPresenting,
                touchX: x,
                linePercent: linePercent)

            if #available(iOS 10.0, *) {
                if updated {
                    weakSelf?.feedbackGenerator.selectionChanged()
                }
            }
        }
        
        switch state {
        case .began:
            if let oldHandler = valueBoxHandler {
                update(handler: oldHandler)
            } else {
                let handler = ValueBoxViewTransitionsHandler(style: .stacked)
                valueBoxHandler = handler
                parent.addSubview(handler.view)
                update(handler: handler)
                handler.show()
                fadeLayer.opacity = 1
            }
        case .changed:
            guard let handler = valueBoxHandler else {
                return
            }
            update(handler: handler)
        case .cancelled, .ended, .failed, .possible:
            break
        @unknown default:
            break
        }
    }
    
}

extension BarChartView: AppearanceSupport {
    func apply(theme: Theme) {
        backgroundColor = theme.main
        plotLineLayers.forEach {
            $0.apply(theme: theme)
        }
        fadeLayer.fillColor = theme.barChartFade.cgColor
    }
}
