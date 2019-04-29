//
//  Created by Timur Bernikovich on 3/12/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

enum TrimmerConstants {

    static let minVisibility: CGFloat = 0.10
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
    
    private let contentView = UIView()
    private let chartView: ChartView
    private let fadeView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        return view
    }()
    private let trimRangeView = TrimRangeView()
    private var trimType: TrimType?
    
    init(chartView: ChartView) {
        self.chartView = chartView
        super.init(frame: .zero)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func notifyDelegate() {
        delegate?.trimmerView(trimmerView: self, didUpdate: selectedRange)
    }

    override func setup() {
        super.setup()
        
        chartView.layer.cornerRadius = 6
        chartView.layer.masksToBounds = true
        chartView.mask = trimRangeView
        
        addSubview(contentView)
        contentView.addSubview(chartView)
        contentView.addSubview(fadeView)
        contentView.addSubview(trimRangeView)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        defer { maskChartView() }

        contentView.frame = bounds.insetBy(dx: SharedConstants.horizontalInset, dy: 0)
        
        let oldFrame = chartView.frame

        chartView.frame = contentView.bounds.insetBy(dx: 0, dy: TrimRangeView.verticalInset)
        fadeView.frame = chartView.frame

        guard oldFrame != chartView.frame else { return }
        relayoutTrimRangeView()
    }

    func redraw() {
        relayoutTrimRangeView()
        maskChartView()
    }
    
    func drawChart(_ chart: Chart, animated: Bool) {
        chartView.setupWithChart(chart, in: 0...1, animated: animated)
        notifyDelegate()
    }

    func setupVisibleColumns(_ visibleLines: [Column], animated: Bool = true) {
        chartView.setupVisibleColumns(visibleLines, animated: animated)
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

}

extension TrimmerView: AppearanceSupport {
    func apply(theme: Theme) {
        trimRangeView.apply(theme: theme)
        fadeView.backgroundColor = theme.chartTrimmerFade
    }
}

extension TrimmerView: UIGestureRecognizerDelegate {

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: trimRangeView)
        return trimRangeView.bounds
            .insetBy(dx: -TrimmerConstants.trimTapExpandOffset, dy: 0)
            .contains(location)
    }

}

private extension TrimmerView {

    func maskChartView() {
        let maskFrame = fadeView.convert(trimRangeView.frame, from: trimRangeView.superview ?? self).insetBy(dx: TrimRangeView.horizontalInset, dy: 0)
        fadeView.mask(withRect: maskFrame, inverse: true)
    }

    func trimRangeWidth(for visibility: CGFloat) -> CGFloat {
        return visibility * chartView.frame.width
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let newLocation = gesture.location(in: self)

        switch gesture.state {
        case .began:
            trimType = calculateTrimType(for: newLocation)
        case .changed:
            let translation = gesture.translation(in: self)
            gesture.setTranslation(.zero, in: self)
            let updates = calculateTrimFrameUpdates(delta: translation.x)
            applyTrimUpdates(x: updates.x, width: updates.width)
        case .cancelled, .ended:
            trimType = nil
        case .failed, .possible:
            break
        @unknown default:
            break
        }
    }

    private func applyTrimUpdates(x: CGFloat, width: CGFloat) {
        guard let trimType = self.trimType else { return }

        let minX: CGFloat = 0
        let maxX = chartView.frame.width - trimRangeView.frame.width
        let minWidth = trimRangeWidth(for: TrimmerConstants.minVisibility)
        let maxWidth = trimRangeWidth(for: TrimmerConstants.maxVisibility)

        let oldX = trimRangeView.frame.origin.x
        let oldWidth = trimRangeView.frame.width

        var proposedX = oldX + x
        var proposedWidth = oldWidth + width

        let threshold: CGFloat = 3
        switch trimType {
        case .leading:
            if proposedX <= minX || !(minWidth...maxWidth).contains(proposedWidth) {
                let xDelta = abs(proposedX - minX)
                let widthDelta = abs(proposedWidth - minWidth)
                let minDelta = min(xDelta, widthDelta)
                proposedX -= x.sign * minDelta
                proposedWidth -= width.sign * minDelta
            }
            if x < 0 {
                let previous = proposedX
                proposedX = proposedX.round(to: minX, threshold: threshold)
                let delta = proposedX - previous
                proposedWidth -= delta
            }
        case .trailing:
            let rightMaxWidth = maxWidth - oldX
            proposedWidth = (minWidth...rightMaxWidth).clamp(proposedWidth)
            if width > 0 {
                proposedWidth = proposedWidth.round(to: rightMaxWidth, threshold: threshold)
            }
        case .center:
            proposedX = (minX...maxX).clamp(proposedX)
            
            if abs(x) > 0 {
                proposedX = proposedX.round(to: x < 0 ? minX : maxX, threshold: threshold)
            }
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
        case .leading: return (delta, -delta)
        case .center: return (delta, 0)
        case .trailing: return (0, delta)
        }
    }

    private func calculateTrimType(for anchor: CGPoint) -> TrimType? {
        let convertedAnchor = trimRangeView.convert(anchor, from: self)
        switch convertedAnchor.x / trimRangeView.frame.width {
        case ..<0.25: return .leading
        case 0.25..<0.75: return .center
        case 0.75...: return .trailing
        default: return nil
        }
    }

    enum TrimType {
        case leading, center, trailing
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
