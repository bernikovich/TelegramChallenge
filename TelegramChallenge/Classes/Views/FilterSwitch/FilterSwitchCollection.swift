//
//  Created by Timur Bernikovich on 08/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class FilterSwitchCollection: BaseView {
    
    struct Item {
        let switchItems: [FilterSwitch.Item]
        var states: [Bool]
        let onSelectItem: ((Int) -> Bool) // true on success.
        let onLongPressItem: ((Int) -> Void)
    }
    
    private enum UIConstants {
        static let lineSpacing: CGFloat = 8
        static let itemSpacing: CGFloat = 8
    }
    
    private var item: Item?
    private var previousViews: [FilterSwitch] = []
    
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
    private var storedFailureGenerator: Any?
    @available(iOS 10.0, *)
    private var failureGenerator: UINotificationFeedbackGenerator {
        if let generator = storedFeedbackGenerator as? UINotificationFeedbackGenerator {
            return generator
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        storedFailureGenerator = generator
        return generator
    }
    
    private func relayout() {
        previousViews.forEach {
            $0.removeFromSuperview()
        }
        
        guard let item = item else {
            return
        }
        
        let containerWidth = bounds.width
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        previousViews = item.switchItems.enumerated().map { index, subitem in
            let view = FilterSwitch()
            view.setup(with: subitem)
            view.updateState(item.states[index], animated: false)
            view.onSelect = { [weak self] in
                let success = item.onSelectItem(index)
                if #available(iOS 10.0, *) {
                    if !success {
                        self?.failureGenerator.notificationOccurred(.error)
                    }
                }
            }
            view.onLongTap = {
                item.onLongPressItem(index)
            }
            
            let size = FilterSwitch.preferredSize(for: subitem)
            if lineWidth > 0 {
                lineWidth += UIConstants.itemSpacing
            }
            lineWidth += size.width
            if lineWidth > containerWidth {
                lineHeight += size.height
                lineHeight += UIConstants.lineSpacing
                lineWidth = size.width
            }
            
            view.frame = CGRect(origin: CGPoint(x: lineWidth - size.width, y: lineHeight), size: size)
            addSubview(view)
            return view
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        relayout()
    }
    
    func setup(with item: Item) {
        self.item = item
        relayout()
    }
    
    func updateStates(_ states: [Bool], animated: Bool) {
        guard var item = item, item.switchItems.count == states.count else {
            return
        }
        
        let isUpdated = item.states != states
        item.states = states
        self.item = item
        
        if #available(iOS 10.0, *) {
            if isUpdated {
                feedbackGenerator.selectionChanged()
            }
        }
        
        if item.states.count == previousViews.count {
            zip(item.states, previousViews).forEach { isSelected, view in
                view.updateState(isSelected, animated: animated)
            }
        }
    }
    
    static func preferredSize(for item: Item, containerWidth: CGFloat) -> CGFloat {
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        item.switchItems.forEach {
            let size = FilterSwitch.preferredSize(for: $0)
            if lineWidth > 0 {
                lineWidth += UIConstants.itemSpacing
            }
            lineWidth += size.width
            if lineWidth > containerWidth {
                lineHeight += size.height
                lineHeight += UIConstants.lineSpacing
                lineWidth = size.width
            }
        }
        if lineWidth > 0 {
            lineHeight += 30 // TODO: ???
            lineHeight += UIConstants.lineSpacing
        }
        return max(0, lineHeight - UIConstants.lineSpacing)
    }
    
}
