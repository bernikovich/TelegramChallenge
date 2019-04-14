//
//  Created by Timur Bernikovich on 13/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class PercentChartView: BaseChartView, ChartView {
    
    private var plotLineLayers: [PlotLineLayer] = []
    
    private var columnPaths: [Path] = []
    private var columnLayers: [ChartColumnLayer] = []
    
    private let plot = Plot(range: 0...100, step: 25)
    
    private let transformCalculator = TransformCalculator()
    private var valueBoxHandler: ValueBoxViewTransitionsHandler?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Simplified chart should take whole height.
        if !isSimple {
            let inset: CGFloat = 10
            var frame = contentView.frame
            frame.origin.y = inset
            frame.size.height = bounds.height - inset
            contentView.frame = frame
            plotContainerView.frame = contentView.frame
        }
        
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
    }
    
    func setupWithChart(_ chart: Chart, in range: ClosedRange<CGFloat> = 0...1, animated: Bool) {
        self.chart = chart
        self.visibleColumns = chart.columns
        self.range = range
        
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
        }
        CATransaction.commit()
        
        if hasData {
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
        
        guard lengthDelta > CGFloat.Magnitude.leastNonzeroMagnitude || forceReload else {
            // No changes.
            return
        }
        
        // All horizontal changes should be applied without animation.
        // But we should handle the case when animation is running already.
        chart.columns.enumerated().forEach { index, line in
            let layer = columnLayers[index]
            
            // Calculate new transformation.
            let horizontalTransform = transformCalculator.transformForApplyingRange(range, boundsWidth: contentBounds.width)
            let verticalTransform = transformCalculator.transformForApplyingPercentPlot(boundsHeight: contentBounds.height)
            let transform = horizontalTransform.concatenating(verticalTransform)
            CATransaction.performWithoutAnimation {
                layer.transform = transform.transform3D
            }
        }
    }
    
    func redrawAll(animated: Bool) {
        updatePaths()
        redrawVerticalPlot(animated: animated)
        redrawLines()
        updateWithRange(range, forceReload: false, animated: animated)
    }
    
    func redrawLines() {
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
            
            let verticalTransform = transformCalculator.transformForApplyingPercentPlot(boundsHeight: contentView.bounds.size.height)
            let horizontalTransform = transformCalculator.transformForApplyingRange(range, boundsWidth: contentView.bounds.size.width)
            let transform = verticalTransform.concatenating(horizontalTransform)
            columnLayer.transform = transform.transform3D
            
            columnLayers.append(columnLayer)
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
        
        var previousPath: Path?
        columnPaths = chart.columns.map {
            let isVisible = visibleColumns.contains($0)
            var path = transformCalculator.percentPathForColumn($0, isVisible: isVisible, sum: stackBarSum)
            if let previousPath = previousPath {
                path = path.stackWithPath(previousPath)
            }
            previousPath = path
            return path
        }
    }
    
    private func redrawVerticalPlot(animated: Bool) {
        guard !isSimple else {
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
                x: 0.5, // https://www.raywenderlich.com/475829-core-graphics-tutorial-lines-rectangles-and-gradients
                y: plotContainerView.bounds.height - height + 0.5,
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
            let previousValue = transformCalculator.transformForValueLine(value: linePlotLayer.value, plot: plot, boundsHeight: plotContainerView.bounds.height).transform3D
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

private extension PercentChartView {

    func hideValueBox(animated: Bool) {
        valueBoxHandler?.hide(animated: animated)
        valueBoxHandler = nil
    }
    
    private func updateBoxView(state: UIGestureRecognizer.State, gesture: UIGestureRecognizer) {
        guard !isSimple else {
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
            lineView.setupWithLines(visibleColumns, range: plot.range, index: safeIndex)
            
            let isPresenting = oldDate == nil
            
            ValueBoxViewPositionHandler.updatePosition(
                of: view,
                in: parent,
                isPresenting: isPresenting,
                touchX: x,
                linePercent: 1)
            
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
                let handler = ValueBoxViewTransitionsHandler(style: .percent)
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

extension PercentChartView: AppearanceSupport {
    func apply(theme: Theme) {
        backgroundColor = theme.main
        plotLineLayers.forEach {
            $0.apply(theme: theme)
        }
    }
}
