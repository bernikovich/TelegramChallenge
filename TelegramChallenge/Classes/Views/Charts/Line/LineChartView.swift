//
//  Created by Timur Bernikovich on 12/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class LineChartView: BaseChartView, ChartView {
    
    private var plotLineLayers: [PlotLineLayer] = []
    
    private var columnPaths: [CGPath] = []
    private var columnLinePaths: [Path] = []
    private var columnLayers: [ChartColumnLayer] = []
    
    // According to provided screenshots.
    private lazy var plotCalculator = PlotCalculator(numberOfSteps: SharedConstants.numberOfPlotLines,
                                                     numberOfChunks: isSimple ? 1 : 20,
                                                     zeroOrigin: false)
    
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
        columnLinePaths = []
        plot = nil
        oldPlot = nil
    }
    
    func setupWithChart(_ chart: Chart, in range: ClosedRange<CGFloat> = 0...1, animated: Bool) {
        self.chart = chart
        self.visibleColumns = chart.columns
        self.range = range
        plotCalculator.updatePreloadedPlots(columns: visibleColumns)
        
        redrawAll(animated: animated)
    }
    
    func setupVisibleColumns(_ visibleColumns: [Column], animated: Bool = true) {
        guard self.visibleColumns != visibleColumns else {
            return
        }
        
        hideValueBox(animated: animated)
        self.visibleColumns = visibleColumns
        
        let hasData = !visibleColumns.isEmpty
        UIView.animate(withDuration: animated ? SharedConstants.animationDuration : 0) {
            zip(self.chart.columns, self.columnLayers).forEach { line, layer in
                layer.opacity = visibleColumns.contains(line) ? 1 : 0
            }
        }
        
        if hasData {
            plotCalculator.updatePreloadedPlots(columns: visibleColumns)
            updateWithRange(range, forceReload: true, animated: animated)
        }
    }
    
    func updateWithRange(_ range: ClosedRange<CGFloat>, forceReload: Bool, animated: Bool) {
        let helper = DebugHelper()
        
        // We hide value box on each range update.
        hideValueBox(animated: animated)
        
        helper.append()
        
        // Redraw plot if needed.
        let lengthDelta = abs((self.range.upperBound - self.range.lowerBound) - (range.upperBound - range.lowerBound))
        if self.range != range || forceReload {
            self.range = range
            helper.append()
            if updatePlot() {
                helper.append()
                redrawVerticalPlot(animated: animated)
            }
        }
        
        helper.append()
        
        let contentBounds = contentView.bounds
        
        // Update view that holds all chart line layers.
        let rangeLength = range.upperBound - range.lowerBound
        let chartWidth = ceil(Double(contentBounds.width) / Double(rangeLength))
        let offsetX = chartWidth * Double(range.lowerBound)
        columnsContainerView.frame = CGRect(
            origin: CGPoint(x: -offsetX, y: 0),
            size: CGSize(width: chartWidth, height: Double(contentBounds.height))
        )
        
        helper.append()
        
        guard let plot = plot, lengthDelta > CGFloat.Magnitude.leastNonzeroMagnitude || forceReload || oldPlot != plot else {
            // No changes.
            if helper.longest > 0.01 {
                print("NOO")
            }
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
        
        var t1: TimeInterval = 0
        var t2: TimeInterval = 0
        var t3: TimeInterval = 0
        var t4: TimeInterval = 0
        var t5: TimeInterval = 0
        var t6: TimeInterval = 0
        var t7: TimeInterval = 0
        var t8: TimeInterval = 0
        var t9: TimeInterval = 0
        var t10: TimeInterval = 0
        var t11: TimeInterval = 0
        var t11b: TimeInterval = 0
        var t12: TimeInterval = 0
        var t13: TimeInterval = 0
        var t14: TimeInterval = 0
        var t15: TimeInterval = 0
        var t16: TimeInterval = 0
        var t17: TimeInterval = 0
        var t18: TimeInterval = 0
        
        helper.append()
        
        // All horizontal changes should be applied without animation.
        // But we should handle the case when animation is running already.
        CATransaction.begin()
        chart.columns.enumerated().forEach { index, column in
            let inner0 = CACurrentMediaTime()
            
            let layer = columnLayers[index]
            let originalPath = columnPaths[index]
            let supaPath = columnLinePaths[index]//transformCalculator.pathForLine(column)
            
            let inner1 = CACurrentMediaTime()
            
            // If layer is not visible and doesn't have hiding animation.
            var shouldStartNewAnimation = oldPlot != plot && animated
            if !visibleColumns.contains(column) && layer.opacity == 0 && (layer.animationKeys()?.isEmpty ?? true) {
                shouldStartNewAnimation = false
            }
            
            let inner2 = CACurrentMediaTime()
            
            // Calculate new transformation.
            var horizontalTransform = transformCalculator.transformForApplyingRange(range, boundsWidth: contentBounds.width)
            
            let inner3 = CACurrentMediaTime()
            let verticalTransform = transformCalculator.transformForApplyingPlot(plot, to: supaPath, boundsHeight: contentBounds.height)
            
            let inner4 = CACurrentMediaTime()
            var transform = horizontalTransform.concatenating(verticalTransform)
            let newPath = originalPath.copy(using: &transform)
            
            let inner5 = CACurrentMediaTime()
            
            // Visible path.
            let visiblePath = (layer.presentation() ?? layer).path?.fittedToWidth(1)
            
            let inner6 = CACurrentMediaTime()
            let updatedVisiblePath = visiblePath?.copy(using: &horizontalTransform)
            
            let inner7 = CACurrentMediaTime()
            
            var inner8: TimeInterval = inner7
            var inner9: TimeInterval = inner7
            var inner10: TimeInterval = inner7
            var inner11: TimeInterval = inner7
            var inner11b: TimeInterval = inner7
            var inner12: TimeInterval = inner7
            var inner13: TimeInterval = inner7
            var inner14: TimeInterval = inner7
            var inner15: TimeInterval = inner7
            var inner16: TimeInterval = inner7
            var inner17: TimeInterval = inner7
            
            // Check if there is currently runnning animation.
            let oldAnimation = layer.animation(forKey: key) as? ChartAnimation
            if oldAnimation != nil || shouldStartNewAnimation {
                
                inner8 = CACurrentMediaTime()
                
                let animation = createBasicAnimation()
                let layerTime = layer.convertTime(CACurrentMediaTime(), from: nil)
                
                inner9 = CACurrentMediaTime()
                
                animation.scheduled = layerTime
                animation.startCallbackTimestamp = layerTime
                animation.fromValue = updatedVisiblePath
                animation.toValue = newPath
                
                inner10 = CACurrentMediaTime()
                

                
//                // CAAnimation doesn't update presentation instantly.
//                // It mean that presentation layer can update
//                // properties with delay.
//                var shouldRemoveAnimation = false
//                if let runningAnimation = layer.runningAnimation, !shouldStartNewAnimation {
//                    // I tried here all (scheduled, startedTimestamp, beginTime,
//                    // converted to CALayer's time beginTime).
//                    // It looks like scheduled is the nearest value to
//                    // the onscreen presentation.
//                    let animationStarted = runningAnimation.scheduled
//                    let elapsedTime = layerTime - animationStarted
//                    var progress = elapsedTime / runningAnimation.duration
//                    progress = min(1, max(0, progress))
//
//                    inner11 = CACurrentMediaTime()
//
//                    // Interpolate possible real value based on
//                    // time animation start, it's duration and from/to values.
//                    let fromValue = runningAnimation.fromValue as! CGPath
//                    inner11b = CACurrentMediaTime()
//                    let toValue = runningAnimation.toValue as! CGPath
//
//                    inner12 = CACurrentMediaTime()
//                    let visiblePath = fromValue.transformingPolyline(to: toValue, with: CGFloat(progress)).fittedToWidth(1)
//
//                    inner13 = CACurrentMediaTime()
//                    let updatedVisiblePath = visiblePath.copy(using: &horizontalTransform)
//                    animation.fromValue = updatedVisiblePath
//
//                    // NOTE: Shit is here.
//                    // Old phones cannot animate path with large number
//                    // of points correctly. Presentation layer delays updates too much.
//                    let timeLeft = runningAnimation.duration - elapsedTime
//                    if column.values.count < 300 || !UIDevice.isOld {
//                        animation.duration = timeLeft
//                    }
//
//                    inner14 = CACurrentMediaTime()
//
//                    if timeLeft < 0 {
//                        shouldRemoveAnimation = true
//                    }
//
//                    inner15 = CACurrentMediaTime()
//                }
                
                // Animation is already finished.
                CATransaction.performWithoutAnimation {
                    layer.path = newPath
                }
                
                inner16 = CACurrentMediaTime()
                if shouldRemoveAnimation {
                    layer.removeAnimation(forKey: key)
                } else {
                    start(animation, on: layer)
                }
                
                inner17 = CACurrentMediaTime()
            } else {
                layer.removeAnimation(forKey: key)
                CATransaction.performWithoutAnimation {
                    layer.path = newPath
                }
            }
            
            let inner18 = CACurrentMediaTime()
            
            
            t1 += inner1 - inner0
            t2 += inner2 - inner1
            t3 += inner3 - inner2
            t4 += inner4 - inner3
            t5 += inner5 - inner4
            t6 += inner6 - inner5
            t7 += inner7 - inner6
            t8 += inner8 - inner7
            t9 += inner9 - inner8
            t10 += inner10 - inner9
            t11 += inner11 - inner10
            t11b += inner11b - inner11
            t12 += inner12 - inner11b
            t13 += inner13 - inner12
            t14 += inner14 - inner13
            t15 += inner15 - inner14
            t16 += inner16 - inner15
            t17 += inner17 - inner16
            t18 += inner18 - inner17
            
        }
        CATransaction.commit()
        var t = [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t11b, t12, t13, t14, t15, t16, t17, t18]
        helper.append()
        if helper.longest > 0.01 {
            print("NOOO2")
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
        columnPaths = []
        
        chart.columns.forEach { column in
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
        guard let plot = plot, !isSimple else {
            return
        }
        
        let helper = DebugHelper()
        
        if !animated {
            plotLineLayers.forEach {
                $0.removeFromSuperlayer()
            }
            plotLineLayers.removeAll()
        }
        
        helper.append()
        
        let hiddenLayers = plotLineLayers.filter { $0.opacity == 0 }
        hiddenLayers.forEach {
            $0.removeFromSuperlayer()
        }
        plotLineLayers.removeAll { hiddenLayers.contains($0) }
        
        helper.append()
        
        let oldLineValues = plotLineLayers.map { $0.value }
        let missingValues = plot.lineValues.filter {
            !oldLineValues.contains($0)
        }
        
        helper.append()
        
        let neededLineLayers = plotLineLayers.filter { plot.lineValues.contains($0.value) }
        let unneededLineLayers = plotLineLayers.filter { !plot.lineValues.contains($0.value) }
        
        helper.append()
        
        let newLineLayers: [PlotLineLayer] = missingValues.map {
            let layer = PlotLineLayer(value: $0, chartType: .lines)
            layer.opacity = 0
            layer.zPosition = CGFloat($0)
            plotContainerView.layer.addSublayer(layer)
            return layer
        }
        plotLineLayers += newLineLayers
        
        helper.append()
        
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
        
        helper.append()
        
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
        
        helper.append()
        if helper.longest > 0.01 {
            print("V-PLOT")
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

private extension LineChartView {

    func hideValueBox(animated: Bool) {
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
            let range = plot.range
            let delta = CGFloat(range.upperBound - range.lowerBound)
            let linePercent = visibleColumns.map({ CGFloat($0.values[safeIndex] - range.lowerBound) / delta }).max() ?? 1
            
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

extension LineChartView: AppearanceSupport {
    func apply(theme: Theme) {
        backgroundColor = theme.main
        plotLineLayers.forEach {
            $0.apply(theme: theme)
        }
    }
}
