//
//  Created by Timur Bernikovich on 3/15/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

// Label with assosiated value can be used to
// find value index based label itself.
private protocol StringRepresentable {
    var string: String { get }
}
extension String: StringRepresentable {
    var string: String { return self }
}
private class Item: Equatable {
    let content: StringRepresentable
    init(content: StringRepresentable) {
        self.content = content
    }
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs === rhs
    }
}
private class LegendLabel: UILabel {
    var item: Item? {
        didSet {
            text = item?.content.string
        }
    }
}

final class LegendView: BaseView {

    private let scrollView = UIScrollView()
    private let leadingFadeView: GradientView = {
        let view = GradientView()
        view.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        view.gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        return view
    }()
    private let trailingFadeView: GradientView = {
        let view = GradientView()
        view.gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        view.gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        return view
    }()
    
    private var items: [Item] = []
    private var range: ClosedRange<CGFloat> = 0...1
    
    private let labelsPool = ReusableViewPool<LegendLabel>()
    private var labels: [LegendLabel] = []
    private var fadeLabels: [LegendLabel] = []
    
    override func setup() {
        super.setup()

        scrollView.isScrollEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        
        let fadeViewWidth: CGFloat = 20
        leadingFadeView.frame = CGRect(x: 0, y: 0, width: fadeViewWidth, height: bounds.height)
        leadingFadeView.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        addSubview(leadingFadeView)
        trailingFadeView.frame = CGRect(x: bounds.width - fadeViewWidth, y: 0, width: fadeViewWidth, height: bounds.height)
        trailingFadeView.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        addSubview(trailingFadeView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if scrollView.frame != bounds {
            scrollView.frame = bounds
            update(range: range)
        }
    }

    func setup(with values: [String]) {
        clean()
        items = values.map { Item(content: $0) }
    }

    func update(range: ClosedRange<CGFloat>) {
        guard range.lowerBound >= 0, range.upperBound <= 1 else {
            return
        }
        
        let selectedWidth = range.upperBound - range.lowerBound
        let contentWidth = scrollView.frame.width / selectedWidth
        
        scrollView.contentSize = CGSize(width: contentWidth, height: scrollView.frame.height)
        scrollView.contentOffset = CGPoint(x: contentWidth * range.lowerBound, y: 0)

        relayoutValues(range: range)
        self.range = range
    }
    
    func clean() {
        items = []
        labels.forEach {
            $0.removeFromSuperview()
            labelsPool.enqueue($0)
        }
        labels = []
        fadeLabels = []
    }

    private func relayoutValues(range: ClosedRange<CGFloat>) {
        let width = scrollView.contentSize.width - 2 * Constants.horizontalInset
        guard width > 0 else {
            return
        }

        let maxSpacing = (scrollView.frame.width - 2 * Constants.horizontalInset) / Constants.maxSpaceDelimeter
        let minItemsCount = width / maxSpacing
        let maxFilterFactor = Double(items.count) / Double(minItemsCount)
        let filterFactor = Int(pow(Double(2), round(log2(maxFilterFactor))))
        let filteredItems = items.reversed().enumerated()
            .filter { $0.offset % filterFactor == 0 }
            .map { $0.element }
            .reversed()

        let spacing = width / CGFloat(items.count - 1)

        let missingLabels: [LegendLabel] = filteredItems.compactMap {
            guard labelForItem($0) == nil else {
                return nil
            }
            
            let label = labelsPool.dequeue()
            label.alpha = 0
            label.font = UIFont.systemFont(ofSize: 12)
            label.item = $0
            label.sizeToFit()
            scrollView.addSubview(label)
            UIView.animate(withDuration: SharedConstants.animationDuration, animations: {
                label.alpha = 1
            })
            
            return label
        }
        labels += missingLabels
        if !missingLabels.isEmpty {
            apply(theme: Appearance.theme)
        }
        
        let labelsToRemove = labels.filter {
            if let item = $0.item {
                return !filteredItems.contains(item)
            } else {
                return true
            }
        }
        labels = labels.filter { !labelsToRemove.contains($0) }

        fadeLabels.append(contentsOf: labelsToRemove)
        UIView.animate(withDuration: SharedConstants.animationDuration, animations: {
            labelsToRemove.forEach { $0.alpha = 0 }
        }, completion: { [weak self] _ in
            labelsToRemove.forEach {
                $0.removeFromSuperview()
                if let index = self?.fadeLabels.firstIndex(of: $0) {
                    self?.fadeLabels.remove(at: index)
                }
                self?.labelsPool.enqueue($0)
            }
        })

        (labels + fadeLabels).forEach { label in
            let x = CGFloat(indexForLabel(label) ?? 0) * spacing + Constants.horizontalInset
            let y = scrollView.frame.height / 2
            label.center = CGPoint(x: x, y: y)
        }
    }

    private func labelForItem(_ item: Item) -> LegendLabel? {
        return labels.first { $0.item == item }
    }
    
    private func indexForLabel(_ label: LegendLabel) -> Int? {
        guard let item = label.item else {
            return nil
        }
        
        return items.firstIndex(of: item)
    }

}

extension LegendView: AppearanceSupport {
    func apply(theme: Theme) {
        let fadeGradient: [UIColor] = [theme.main, theme.main.withAlphaComponent(0)]
        leadingFadeView.gradientLayer.uiColors = fadeGradient
        trailingFadeView.gradientLayer.uiColors = fadeGradient
        
        (labels + fadeLabels).forEach {
            $0.textColor = theme.chartLineText
        }
    }
}

private enum Constants {

    static let maxSpaceDelimeter: CGFloat = 4
    static let horizontalInset: CGFloat = 36

}
