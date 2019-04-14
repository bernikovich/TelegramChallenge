//
//  Created by Timur Bernikovich on 12/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class ValueBoxTitleValueView: BaseView, AppearanceSupport {
    
    enum Source: Equatable {
        case column(Column)
        case all
    }
    
    let source: Source
    var percentWidth: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    private let percentLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
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
        
        addSubview(percentLabel)
        percentLabel.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let infiniteSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        percentLabel.frame = CGRect(origin: .zero, size: CGSize(width: percentWidth, height: bounds.height))
        let titleSize = titleLabel.sizeThatFits(infiniteSize).ceiled()
        var titleOrigin: CGPoint = .zero
        if percentLabel.text != nil {
            titleOrigin = CGPoint(x: percentWidth + 6, y: 0)
        }
        titleLabel.frame = CGRect(origin: titleOrigin, size: CGSize(width: titleSize.width, height: bounds.height))
        let valueSize = valueLabel.sizeThatFits(infiniteSize).ceiled()
        let valueWidth = valueSize.width
        valueLabel.frame = CGRect(x: bounds.width - valueWidth, y: 0, width: valueWidth, height: bounds.height)
    }
    
    func updateWithValue(_ value: Int64, percent: Int? = nil, animated: Bool = false) {
        valueLabel.text = type(of: self).numberFormatter.string(from: NSNumber(value: value))
        if let percent = percent {
            percentLabel.text = "\(percent)%"
        } else {
            percentLabel.text = nil
        }
        setNeedsLayout()
    }
    
    func preferredSize() -> (size: CGSize, percentWidth: CGFloat) {
        let infiniteSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let percentSize = percentLabel.sizeThatFits(infiniteSize).ceiled()
        var widthForPercent: CGFloat = 0
        if percentLabel.text != nil {
            widthForPercent = percentSize.width + 6
        }
        
        let titleSize = titleLabel.sizeThatFits(infiniteSize).ceiled()
        let valueSize = valueLabel.sizeThatFits(infiniteSize).ceiled()
        let size = CGSize(
            width: widthForPercent + titleSize.width + 4 + valueSize.width,
            height: max(titleSize.height, valueSize.height)
        )
        return (size: size, percentWidth: percentSize.width)
    }
    
    func apply(theme: Theme) {
        titleLabel.textColor = theme.chartBoxText
        percentLabel.textColor = theme.chartBoxText
        switch source {
        case .all:
            valueLabel.textColor = theme.chartBoxText
        case let .column(column):
            valueLabel.textColor = UIColor(hexString: column.colorHex)
        }
    }
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter
    }()
    
}
