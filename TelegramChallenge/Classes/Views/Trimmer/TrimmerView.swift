//
//  Created by Timur Bernikovich on 3/12/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

enum TrimmerConstants {

    static let minVisibility: CGFloat = 0.15
    static let defaultVisibility: CGFloat = 0.25
    static let maxVisibility: CGFloat = 1

    fileprivate static let trimTapExpandOffset: CGFloat = 20

}

protocol TrimmerViewDelegate: AnyObject {
    func trimmerView(trimmerView: TrimmerView, didUpdate selectedRange: ClosedRange<CGFloat>)
}

final class TrimmerView: BaseView {

    weak var delegate: TrimmerViewDelegate?

    var selectedRange: ClosedRange<CGFloat> = ChartConstants.startChartVisibilityRange {
        didSet {
            guard oldValue != selectedRange else {
                return
            }
            notifyDelegate()
        }
    }
    
    private func notifyDelegate() {
        delegate?.trimmerView(trimmerView: self, didUpdate: selectedRange)
    }

    override func setup() {
        super.setup()
        self.chartView.mask = trimRangeView
        addSubview(chartView)
        addSubview(fadeView)
        addSubview(trimRangeView)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        defer { maskChartView() }

        let oldFrame = chartView.frame

        chartView.frame = bounds.insetBy(
            dx: 0,
            dy: TrimRangeView.verticalInset
        )
        fadeView.frame = chartView.frame

        guard oldFrame != chartView.frame else { return }
        relayoutTrimRangeView()
    }

    func redraw() {
        relayoutTrimRangeView()
        maskChartView()
    }
    
    func drawChart(_ chart: Chart, animated: Bool) {
        chartView.setupWithChart(chart, animated: animated)
        notifyDelegate()
    }

    func setupVisibleLines(_ visibleLines: [Line], animated: Bool = true) {
        chartView.setupVisibleLines(visibleLines, animated: animated)
    }

    private func relayoutTrimRangeView() {
        let visibility = selectedRange.upperBound - selectedRange.lowerBound
        let width = trimRangeWidth(for: visibility)
        trimRangeView.frame = CGRect(
            x: selectedRange.lowerBound * chartView.frame.width,
            y: 0,
            width: width,
            height: frame.height
        )
    }

    private let chartView = ChartView(simplified: true)
    private let fadeView = UIView()
    private let trimRangeView = TrimRangeView()
    private var gestureAnchor: CGPoint?
    private var trimType: TrimType?

}

extension TrimmerView: AppearanceSupport {
    func apply(theme: Theme) {
        trimRangeView.apply(theme: theme)
        fadeView.backgroundColor = theme.chartTrimmerFade
    }
}

extension TrimmerView: UIGestureRecognizerDelegate {

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: self)
        return trimRangeView.frame
            .insetBy(dx: -TrimmerConstants.trimTapExpandOffset, dy: 0)
            .contains(location)
    }

}

private extension TrimmerView {

    func maskChartView() {
        fadeView.mask(withRect: trimRangeView.frame, inverse: true)
    }

    func trimRangeWidth(for visibility: CGFloat) -> CGFloat {
        return visibility * chartView.frame.width
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let newLocation = gesture.location(in: self)

        switch gesture.state {
        case .began:
            gestureAnchor = newLocation
            trimType = calculateTrimType(for: newLocation)
        case .changed:
            guard let anchor = gestureAnchor else { break }

            let delta = newLocation.x - anchor.x

            let updates = calculateTrimFrameUpdates(delta: delta)
            applyTrimUpdates(x: updates.x, width: updates.width)
            gestureAnchor = newLocation

        case .cancelled, .ended:
            gestureAnchor = nil
            trimType = nil
        case .failed, .possible:
            break
        }
    }

    private func applyTrimUpdates(x: CGFloat, width: CGFloat) {
        guard let trimType = self.trimType else { return }

        let minX: CGFloat = 0
        let maxX = frame.width - trimRangeView.frame.width
        let minWidth = trimRangeWidth(for: TrimmerConstants.minVisibility)
        let maxWidth = trimRangeWidth(for: TrimmerConstants.maxVisibility)

        let oldX = trimRangeView.frame.origin.x
        let oldWidth = trimRangeView.frame.width

        var proposedX = oldX + x
        var proposedWidth = oldWidth + width

        let threshold: CGFloat = 2
        switch trimType {
        case .left:
            if proposedX <= minX || !(minWidth...maxWidth).contains(proposedWidth) {
                let xDelta = abs(proposedX - minX)
                let widthDelta = abs(proposedWidth - minWidth)
                let minDelta = min(xDelta, widthDelta)
                proposedX -= x.sign * minDelta
                proposedWidth -= width.sign * minDelta
                if x < 0 {
                    proposedX = proposedX.round(to: minX, threshold: threshold)
                }
            }
            
        case .right:
            let rightMaxWidth = maxWidth - oldX
            proposedWidth = (minWidth...rightMaxWidth).clamp(proposedWidth)
            if width > 0 {
                proposedWidth = proposedWidth.round(to: rightMaxWidth, threshold: threshold)
            }
        case .center:
            proposedX = (minX...maxX).clamp(proposedX)
            proposedX = proposedX.round(to: x < 0 ? minX : maxX, threshold: threshold)
        }

        trimRangeView.frame = CGRect(
            x: proposedX,
            y: trimRangeView.frame.origin.y,
            width: proposedWidth,
            height: trimRangeView.frame.height
        )

        maskChartView()

        let chartWidth = chartView.frame.width
        let selectedStart = trimRangeView.frame.origin.x
        let selectedEnd = selectedStart + trimRangeView.frame.width
        guard selectedEnd > selectedStart else {
            assertionFailure("Wrong trimmer selection")
            return
        }
        selectedRange = max(0, selectedStart / chartWidth)...min(1, selectedEnd / chartWidth)
    }

    private func calculateTrimFrameUpdates(delta: CGFloat) -> (x: CGFloat, width: CGFloat) {
        guard let trimType = self.trimType else { return (0, 0) }

        switch trimType {
        case .left: return (delta, -delta)
        case .center: return (delta, 0)
        case .right: return (0, delta)
        }
    }

    private func calculateTrimType(for anchor: CGPoint) -> TrimType? {
        let convertedAnchor = trimRangeView.convert(anchor, from: self)
        switch convertedAnchor.x / trimRangeView.frame.width {
        case ..<0.25: return .left
        case 0.25..<0.75: return .center
        case 0.75...
            : return .right
        default: return nil
        }
    }

    enum TrimType {
        case left, center, right
    }
}

private extension CGFloat {

    var sign: CGFloat {
        return self >= 0 ? 1 : -1
    }

    func round(to value: CGFloat, threshold: CGFloat) -> CGFloat {
        if abs(self - value) <= threshold {
            return value
        } else {
            return self
        }
    }
}
