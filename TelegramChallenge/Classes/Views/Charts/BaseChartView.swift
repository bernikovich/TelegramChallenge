//
//  Created by Timur Bernikovich on 12/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

protocol ChartView: UIView, AppearanceSupport {
    func setupWithChart(_: Chart, in: ClosedRange<CGFloat>, animated: Bool)
    
    func setupVisibleColumns(_: [Column], animated: Bool)
    func updateWithRange(_: ClosedRange<CGFloat>, forceReload: Bool, animated: Bool)
    func clear()
}

class BaseChartView: BaseView {
    let isSimple: Bool
    
    // For subclasses only.
    var chart: Chart = .empty
    var visibleColumns: [Column] = []
    var range: ClosedRange<CGFloat> = 0...1
    var lastKnownSize: CGSize = .zero
    
    let gesturesView = UIView()
    
    // Containers for plot.
    let plotContainerView = UIView()
    
    // Containers for chart lines.
    // Used as UIScrollView but without roundsing offset to pixels.
    let contentView = UIView()
    let columnsContainerView = UIView()
    
    // https://stackoverflow.com/questions/41904724/using-available-with-stored-properties
    private var storedFeedbackGenerator: Any?
    @available(iOS 10.0, *)
    var feedbackGenerator: UISelectionFeedbackGenerator {
        if let generator = storedFeedbackGenerator as? UISelectionFeedbackGenerator {
            return generator
        }
        
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        storedFeedbackGenerator = generator
        return generator
    }
    
    init(simplified: Bool) {
        isSimple = simplified
        super.init(frame: .zero)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        addSubview(gesturesView)
        gesturesView.frame = bounds
        gesturesView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(contentView)
        contentView.clipsToBounds = false
        contentView.isUserInteractionEnabled = false
        
        contentView.addSubview(columnsContainerView)
        columnsContainerView.autoresizingMask = []
        columnsContainerView.isUserInteractionEnabled = false
        
        addSubview(plotContainerView)
        plotContainerView.isUserInteractionEnabled = false
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        gesturesView.addGestureRecognizer(panGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.numberOfTouchesRequired = 1
        gesturesView.addGestureRecognizer(tapGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let inset: CGFloat = isSimple ? 0 : SharedConstants.horizontalInset
        contentView.frame = CGRect(x: inset, y: 0, width: bounds.width - 2 * inset, height: bounds.height)
        plotContainerView.frame = contentView.frame
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        
    }

}

extension BaseChartView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
        let translation = pan.translation(in: pan.view)
        return abs(translation.x) > abs(translation.y)
    }
}

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

class ChartColumnLayer: CAShapeLayer {
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

struct StackBarSum {
    let values: [Int64]
    let minValue: Int64?
    let maxValue: Int64?
}

extension Column {
    func valuesRangeInRange(_ range: ClosedRange<CGFloat>) -> ClosedRange<Int64> {
        let slice = values[indexRange(for: range)]
        let minValue = slice.min() ?? 0
        let maxValue = slice.max() ?? 1
        return minValue...maxValue
    }
    
    func indexRange(for range: ClosedRange<CGFloat>) -> ClosedRange<Int> {
        let length = CGFloat(values.count)
        let lowerBound = Int(range.lowerBound * length)
        let upperBound = max(0, min(values.count, Int(ceil(range.upperBound * length))) - 1)
        return lowerBound...upperBound
    }
}

extension StackBarSum {
    func valuesRangeInRange(_ range: ClosedRange<CGFloat>) -> ClosedRange<Int64> {
        let length = CGFloat(values.count)
        let lowerBound = Int(range.lowerBound * length)
        let upperBound = min(values.count, Int(ceil(range.upperBound * length)))
        let slice = values[lowerBound..<upperBound]
        let minValue = slice.min() ?? 0
        let maxValue = slice.max() ?? 1
        return minValue...maxValue
    }
}

extension Legend {
    func indexRange(for range: ClosedRange<CGFloat>) -> ClosedRange<Int> {
        let length = CGFloat(values.count)
        let lowerBound = Int(range.lowerBound * length)
        let upperBound = max(0, min(values.count, Int(ceil(range.upperBound * length))) - 1)
        return lowerBound...upperBound
    }
}
