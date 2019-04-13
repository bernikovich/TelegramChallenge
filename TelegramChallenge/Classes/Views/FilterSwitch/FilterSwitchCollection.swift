//
//  Created by Timur Bernikovich on 08/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class FilterSwitchCollection: BaseView {
    
    struct Item {
        let switchItems: [FilterSwitch.Item]
        var states: [Bool]
        let onSelectItem: ((Int) -> Void)
    }
    
    private enum UIConstants {
        static let lineSpacing: CGFloat = 8
        static let itemSpacing: CGFloat = 8
    }
    
    private var item: Item?
    private var previousViews: [FilterSwitch] = []
    
    private func onSelectItem(_ index: Int) {
        guard var item = item else {
            return
        }
        
        if index < item.states.count {
            item.states[index] = !item.states[index]
        }
        self.item = item
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
            view.isSelected = item.states[index]
            view.onSelect = { [weak self] in
                self?.onSelectItem(index)
                item.onSelectItem(index)
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
