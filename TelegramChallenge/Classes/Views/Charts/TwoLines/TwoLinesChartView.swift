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
    
    private static let leadingPlotLineLayersPool = ReusablePool(creationClosure: { () -> PlotLineLayer in
        let layer = PlotLineLayer(value: 0, chartType: .twoLines)
        layer.textLayer.alignmentMode = .left
        layer.lineLayer.opacity = 0.5
        return layer
    })
    private var leadingPlotLineLayers: [PlotLineLayer] = []
    private static let trailingPlotLineLayersPool = ReusablePool(creationClosure: { () -> PlotLineLayer in
        let layer = PlotLineLayer(value: 0, chartType: .twoLines)
        layer.textLayer.alignmentMode = .right
        layer.lineLayer.opacity = 0.5
        return layer
    })
    private var trailingPlotLineLayers: [PlotLineLayer] = []
    
    private var columnPaths: [CGPath] = []
    private var columnLinePaths: [Path] = []
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
        
        leadingPlotLineLayers.forEach {
            $0.removeFromSuperlayer()
            type(of: self).leadingPlotLineLayersPool.enqueue($0)
        }
        leadingPlotLineLayers = []
        trailingPlotLineLayers.forEach {
            $0.removeFromSuperlayer()
            type(of: self).trailingPlotLineLayersPool.enqueue($0)
        }
        trailingPlotLineLayers = []
        
        columnPaths = []
        columnLinePaths = []
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

        chart.columns.enumerated().forEach { index, column in
            let layer = columnLayers[index]
            let originalPath = columnPaths[index]
            let supaPath = columnLinePaths[index]
            
            let isLeadingColumn = index == 0
            let oldPlot = isLeadingColumn ? oldLeadingPlot : oldTrailingPlot
            let plot = isLeadingColumn ? leadingPlot : trailingPlot
            
            // If layer is not visible and doesn't have hiding animation.
            var shouldStartNewAnimation = oldPlot != plot && animated
            if !visibleColumns.contains(column) && layer.opacity == 0 && (layer.animationKeys()?.isEmpty ?? true) {
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

                CATransaction.performWithoutAnimation {
                    layer.path = newPath
                }
                start(animation, on: layer)
            } else {
                layer.removeAnimation(forKey: key)
                CATransaction.performWithoutAnimation {
                    layer.path = newPath
                }
            }
        }
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
            let cgPath = path.cgPath
            columnLayer.path = cgPath.copy(using: &transform)
            
            columnLayers.append(columnLayer)
            columnPaths.append(cgPath)
            columnLinePaths.append(path)
        }
    }
    
    private func redrawVerticalPlot(animated: Bool) {
        guard let leadingPlot = leadingPlot, let trailingPlot = trailingPlot, !isSimple else {
            return
        }
        
        redrawVerticalPlot(
            plot: leadingPlot,
            oldPlot: oldLeadingPlot,
            plotLineLayerPool: type(of: self).leadingPlotLineLayersPool,
            plotLineLayers: &leadingPlotLineLayers,
            plotColor: UIColor(hexString: chart.columns[0].colorHex),
            animated: animated
        )
        
        redrawVerticalPlot(
            plot: trailingPlot,
            oldPlot: oldTrailingPlot,
            plotLineLayerPool: type(of: self).trailingPlotLineLayersPool,
            plotLineLayers: &trailingPlotLineLayers,
            plotColor: UIColor(hexString: chart.columns[1].colorHex),
            animated: animated
        )
    }
        
    private func redrawVerticalPlot(
        plot: Plot,
        oldPlot: Plot?,
        plotLineLayerPool: ReusablePool<PlotLineLayer>,
        plotLineLayers: inout [PlotLineLayer],
        plotColor: UIColor,
        animated: Bool) {
        
        if !animated {
            plotLineLayers.forEach {
                $0.removeFromSuperlayer()
                plotLineLayerPool.enqueue($0)
            }
            plotLineLayers.removeAll()
        }
        
        let hiddenLayers = plotLineLayers.filter { $0.opacity == 0 }
        hiddenLayers.forEach {
            $0.removeFromSuperlayer()
            plotLineLayerPool.enqueue($0)
        }
        plotLineLayers.removeAll { hiddenLayers.contains($0) }
        
        let oldLineValues = plotLineLayers.map { $0.value }
        let missingValues = plot.lineValues.filter {
            !oldLineValues.contains($0)
        }
        
        let neededLineLayers = plotLineLayers.filter { plot.lineValues.contains($0.value) }
        let unneededLineLayers = plotLineLayers.filter { !plot.lineValues.contains($0.value) }
        let newLineLayers: [PlotLineLayer] = missingValues.map { value in
            let layer = plotLineLayerPool.dequeue()
            layer.textColor = plotColor
            CATransaction.performWithoutAnimation {
                layer.value = value
                layer.opacity = 0
                layer.zPosition = CGFloat(value)
            }
            plotContainerView.layer.addSublayer(layer)
            return layer
        }
        plotLineLayers += newLineLayers
        
        let allLineLayers = (neededLineLayers + unneededLineLayers + newLineLayers)
        
        // Update frames.
        // TODO: Need to think about ChartView frame update too.
        let height = ceil(plotContainerView.bounds.height / CGFloat(plot.range.upperBound - plot.range.lowerBound) * CGFloat(plot.step))
        allLineLayers.forEach { layer in
            CATransaction.performWithoutAnimation {
                layer.bounds = CGRect(x: 0, y: 0, width: plotContainerView.bounds.width, height: height)
                layer.position = CGPoint(x: layer.bounds.width / 2, y: plotContainerView.bounds.height - height / 2)
            }
        }
        
        allLineLayers.forEach { linePlotLayer in
            let transformToValue = transformCalculator.transformForValueLine(value: linePlotLayer.value, plot: plot, boundsHeight: plotContainerView.bounds.height).transform3D
            let isNew = newLineLayers.contains(linePlotLayer)
            let isUnneeded = unneededLineLayers.contains(linePlotLayer)
            let opacityToValue: Float = isUnneeded ? 0 : 1
            guard animated else {
                CATransaction.performWithoutAnimation {
                    linePlotLayer.opacity = opacityToValue
                    linePlotLayer.transform = transformToValue
                }
                return
            }
            
            var animations: [CAAnimation] = []
            
            let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
            
            let opacityFromValue: Float = isNew ? 0.1 : (linePlotLayer.presentation() ?? linePlotLayer).opacity
            
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
        lastValueBoxIndex = safeIndex
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
                handler.view.arrowLayer.isHidden = onSelectDetails == nil
                addGestureRecognizersToValueBox(handler.view)
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
