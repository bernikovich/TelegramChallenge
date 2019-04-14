//
//  Created by Timur Bernikovich on 13/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

// Can be rewritten with nesting 2 LineChartView instances.
final class TwoLinesChartView: BaseChartView, ChartView {
    
    var supportsColumnVisibilityChanges: Bool {
        return false
    }
    
    private var leadingPlotLineLayers: [PlotLineLayer] = []
    private var trailingPlotLineLayers: [PlotLineLayer] = []
    
    private var columnPaths: [CGPath] = []
    private var columnLayers: [ChartColumnLayer] = []
    
    private lazy var leadingPlotCalculator = PlotCalculator(
        numberOfSteps: SharedConstants.numberOfPlotLines,
        numberOfChunks: isSimple ? 1 : 20,
        zeroOrigin: false
    )
    private lazy var trailingPlotCalculator = PlotCalculator(
        numberOfSteps: SharedConstants.numberOfPlotLines,
        numberOfChunks: isSimple ? 1 : 20,
        zeroOrigin: false
    )
    
    private var leadingPlot: Plot?
    private var oldLeadingPlot: Plot?
    private var trailingPlot: Plot?
    private var oldTrailingPlot: Plot?
    
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
        
        leadingPlotLineLayers.forEach { $0.removeFromSuperlayer() }
        leadingPlotLineLayers = []
        trailingPlotLineLayers.forEach { $0.removeFromSuperlayer() }
        trailingPlotLineLayers = []
        
        columnPaths = []
        columnLayers.forEach { $0.removeFromSuperlayer() }
        columnLayers = []
        
        leadingPlot = nil
        oldLeadingPlot = nil
        trailingPlot = nil
        oldTrailingPlot = nil
    }
    
    func setupWithChart(_ chart: Chart, in range: ClosedRange<CGFloat> = 0...1, animated: Bool) {
        self.chart = chart
        self.visibleColumns = chart.columns
        self.range = range
        
        if chart.columns.count == 2 {
            leadingPlotCalculator.updatePreloadedPlots(columns: [chart.columns[0]])
            trailingPlotCalculator.updatePreloadedPlots(columns: [chart.columns[1]])
        }
        
        redrawAll(animated: animated)
    }
    
    func setupVisibleColumns(_ visibleColumns: [Column], animated: Bool = true) {

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
        
        guard let leadingPlot = leadingPlot, let trailingPlot = trailingPlot else {
            // No plot.
            return
        }
        
        guard lengthDelta > CGFloat.Magnitude.leastNonzeroMagnitude
            || forceReload
            || oldLeadingPlot != leadingPlot
            || oldTrailingPlot != trailingPlot else {
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
            let originalPath = columnPaths[index]
            let supaPath = transformCalculator.pathForLine(line)
            
            let isLeadingColumn = index == 0
            let oldPlot = isLeadingColumn ? oldLeadingPlot : oldTrailingPlot
            let plot = isLeadingColumn ? leadingPlot : trailingPlot
            
            // If layer is not visible and doesn't have hiding animation.
            var shouldStartNewAnimation = oldPlot != plot && animated
            if !visibleColumns.contains(line) && layer.opacity == 0 && (layer.animationKeys()?.isEmpty ?? true) {
                shouldStartNewAnimation = false
            }
            
            // Calculate new transformation.
            var horizontalTransform = transformCalculator.transformForApplyingRange(range, boundsWidth: contentBounds.width)
            let verticalTransform = transformCalculator.transformForApplyingPlot(plot, to: supaPath, boundsHeight: contentBounds.height)
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
                    if line.values.count < 300 || !UIDevice.isOld {
                        animation.duration = timeLeft
                    }
                    
                    if timeLeft < 0 {
                        shouldRemoveAnimation = true
                    }
                }
                
                // Animation is already finished.
                CATransaction.performWithoutAnimation {
                    layer.path = newPath
                }
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
        let newLeadingPlot = leadingPlotCalculator.verticalPlot(for: range)
        let newTrailingPlot = trailingPlotCalculator.verticalPlot(for: range)
        if newLeadingPlot == leadingPlot && newTrailingPlot == trailingPlot {
            oldLeadingPlot = leadingPlot
            oldTrailingPlot = trailingPlot
            return false
        }
        
        oldLeadingPlot = leadingPlot
        oldTrailingPlot = trailingPlot
        
        leadingPlot = newLeadingPlot
        trailingPlot = newTrailingPlot
        
        return true
    }
    
    func redrawLines() {
        guard let leadingPlot = leadingPlot, let trailingPlot = trailingPlot else {
            return
        }
        
        columnLayers.forEach {
            $0.removeFromSuperlayer()
        }
        
        columnLayers = []
        columnPaths = []
        
        chart.columns.enumerated().forEach { index, column in
            let isLeadingColumn = index == 0
            let plot = isLeadingColumn ? leadingPlot : trailingPlot
            
            let columnLayer = ChartColumnLayer()
            columnLayer.lineJoin = .round
            columnLayer.lineCap = .round
            columnLayer.lineWidth = isSimple ? 1 : 2
            columnLayer.strokeColor = UIColor(hexString: column.colorHex).cgColor
            columnLayer.fillColor = nil
            columnLayer.frame = CGRect(origin: .zero, size: columnsContainerView.bounds.size)
            columnLayer.opacity = visibleColumns.contains(column) ? 1 : 0
            columnsContainerView.layer.insertSublayer(columnLayer, at: 0)
            
            let path = transformCalculator.pathForLine(column)
            let verticalTransform = transformCalculator.transformForApplyingPlot(plot, to: path, boundsHeight: contentView.bounds.size.height)
            let horizontalTransform = transformCalculator.transformForApplyingRange(range, boundsWidth: contentView.bounds.size.width)
            var transform = verticalTransform.concatenating(horizontalTransform)
            columnLayer.path = path.cgPath.copy(using: &transform)
            
            columnLayers.append(columnLayer)
            columnPaths.append(path.cgPath)
        }
    }
    
    private func redrawVerticalPlot(animated: Bool) {
        guard let leadingPlot = leadingPlot, let trailingPlot = trailingPlot, !isSimple else {
            return
        }
        
        redrawVerticalPlot(
            plot: leadingPlot,
            oldPlot: oldLeadingPlot,
            plotLineLayers: &leadingPlotLineLayers,
            layerConfiguration: {
                $0.textColor = UIColor(hexString: chart.columns[0].colorHex)
                $0.textLayer.alignmentMode = .left
                $0.lineLayer.opacity = 0.5
        },
            animated: animated
        )
        
        redrawVerticalPlot(
            plot: trailingPlot,
            oldPlot: oldTrailingPlot,
            plotLineLayers: &trailingPlotLineLayers,
            layerConfiguration: {
                $0.textColor = UIColor(hexString: chart.columns[1].colorHex)
                $0.textLayer.alignmentMode = .right
                $0.lineLayer.opacity = 0.5
        },
            animated: animated
        )
    }
        
    private func redrawVerticalPlot(
        plot: Plot,
        oldPlot: Plot?,
        plotLineLayers: inout [PlotLineLayer],
        layerConfiguration: (PlotLineLayer) -> (),
        animated: Bool) {
        
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
            let layer = PlotLineLayer(value: $0, chartType: .lines)
            layerConfiguration(layer)
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

private extension TwoLinesChartView {
    
    func hideValueBox(animated: Bool) {
        valueBoxHandler?.hide(animated: animated)
        valueBoxHandler = nil
    }
    
    private func updateBoxView(state: UIGestureRecognizer.State, gesture: UIGestureRecognizer) {
        guard let leadingPlot = leadingPlot, let trailingPlot = trailingPlot, !isSimple else {
            return
        }
        
        let parent = self
        let location = gesture.location(in: columnsContainerView)
        let index = Int(round((location.x / columnsContainerView.frame.width) * CGFloat(chart.legend.values.count - 1)))
        let indexRange = chart.legend.indexRange(for: range)
        let safeIndex = indexRange.clamp(index)
        let x = gesture.location(in: parent).x
        
        weak var weakSelf = self
        func update(handler: ValueBoxViewTransitionsHandler) {
            let view = handler.view
            let newDate = chart.legend.values[safeIndex]
            let oldDate = view.lastDate
            let updated = oldDate != newDate
            view.update(date: newDate, columns: visibleColumns, index: safeIndex)
            
            let lineX = (CGFloat(safeIndex) / CGFloat(chart.legend.values.count - 1)) * columnsContainerView.frame.width
            let lineView = handler.lineView
            lineView.frame.size.height = columnsContainerView.frame.height
            lineView.center = CGPoint(x: lineX, y: columnsContainerView.frame.height / 2)
            
            if visibleColumns.count == 2 {
                lineView.setupWithLines(visibleColumns, ranges: [leadingPlot.range, trailingPlot.range], index: safeIndex)
            } else {
                // Not possible. Sorry for this code.
            }
            
            let isPresenting = oldDate == nil
            let linePercent: CGFloat = visibleColumns.enumerated().map({ index, column in
                let range = (index == 0 ? leadingPlot : trailingPlot).range
                let delta = CGFloat(range.upperBound - range.lowerBound)
                return CGFloat(column.values[safeIndex] - range.lowerBound) / delta
            }).max() ?? 1
            
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
                let handler = ValueBoxViewTransitionsHandler(style: .normal)
                valueBoxHandler = handler
                parent.addSubview(handler.view)
                columnsContainerView.addSubview(handler.lineView)
                update(handler: handler)
                handler.show()
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

extension TwoLinesChartView: AppearanceSupport {
    func apply(theme: Theme) {
        backgroundColor = theme.main
        (leadingPlotLineLayers + trailingPlotLineLayers).forEach {
            $0.apply(theme: theme)
        }
    }
}

