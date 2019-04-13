//
//  Created by Timur Bernikovich on 12/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class TitleValueView: BaseView, AppearanceSupport {
    
    enum Source: Equatable {
        case column(Column)
        case all
    }
    
    let source: Source
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .natural
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        return label
    }()
    
    init(source: Source) {
        self.source = source
        super.init(frame: .zero)
        
        subscribeToAppearanceUpdates()
        
        addSubview(titleLabel)
        titleLabel.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        
        addSubview(valueLabel)
        valueLabel.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        
        switch source {
        case .all:
            titleLabel.text = "All"
        case let .column(column):
            titleLabel.text = column.name
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateWithValue(_ value: Int64) {
        valueLabel.text = "\(value)"
        
        let infiniteSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let titleSize = titleLabel.sizeThatFits(infiniteSize).ceiled()
        titleLabel.frame = CGRect(origin: .zero, size: CGSize(width: titleSize.width, height: bounds.height))
        let valueSize = valueLabel.sizeThatFits(infiniteSize).ceiled()
        let valueWidth = valueSize.width
        valueLabel.frame = CGRect(x: bounds.width - valueWidth, y: 0, width: valueWidth, height: bounds.height)
    }
    
    func preferredSize() -> CGSize {
        let infiniteSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let titleSize = titleLabel.sizeThatFits(infiniteSize).ceiled()
        let valueSize = valueLabel.sizeThatFits(infiniteSize).ceiled()
        return CGSize(width: titleSize.width + 4 + valueSize.width, height: max(titleSize.height, valueSize.height))
    }
    
    func apply(theme: Theme) {
        titleLabel.textColor = theme.chartBoxText
        switch source {
        case .all:
            valueLabel.textColor = theme.chartBoxText
        case let .column(column):
            valueLabel.textColor = UIColor(hexString: column.colorHex)
        }
    }
    
}
