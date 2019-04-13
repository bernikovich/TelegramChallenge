//
//  Created by Timur Bernikovich on 12/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class BarChartValueBoxView: BaseView {
    
    enum Style {
        case normal, stacked
    }
    
    let style: Style
    var lastDate: Date?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .natural
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        return label
    }()
    
    private let valuesContainer = UIView()
    private var titleValueViews: [TitleValueView] = []
    
    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        subscribeToAppearanceUpdates()
        
        addSubview(backgroundView)
        addSubview(titleLabel)
        addSubview(valuesContainer)
        
        backgroundView.layer.cornerRadius = 6
        backgroundView.clipsToBounds = true
    }
    
    func update(date: Date, columns: [Column], index: Int) {
        lastDate = date
        
        let infiniteSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let horizontalInset: CGFloat = 10
        
        let dateString = type(of: self).dateFormatter.string(from: date)
        titleLabel.text = dateString
        let titleSize = titleLabel.sizeThatFits(infiniteSize).ceiled()
        titleLabel.frame = CGRect(x: horizontalInset, y: 5, width: titleSize.width, height: titleSize.height)
        titleLabel.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        
        var oldTitleValueViews = titleValueViews
        var newTitleValueViews: [TitleValueView] = []
        
        let sources: [TitleValueView.Source]
        switch style {
        case .normal:
            sources = columns.map { TitleValueView.Source.column($0) }
        case .stacked:
            sources = columns.map { TitleValueView.Source.column($0) } + (columns.count > 1 ? [.all] : [])
        }
        
        sources.forEach { source in
            let view: TitleValueView
            if let viewIndex = oldTitleValueViews.firstIndex(where: { $0.source == source }) {
                view = oldTitleValueViews[viewIndex]
                oldTitleValueViews.remove(at: viewIndex)
            } else {
                view = TitleValueView(source: source)
            }
            newTitleValueViews.append(view)
            
            let value: Int64
            switch source {
            case .all:
                value = columns.reduce(Int64(0), { $0 + $1.values[index] })
            case let .column(column):
                value = column.values[index]
            }
            
            view.updateWithValue(value) // Animated?
        }
        
        titleValueViews = newTitleValueViews
        oldTitleValueViews.forEach {
            $0.removeFromSuperview()
        }
        
        // Kinda stack view.
        let spacing: CGFloat = 2
        valuesContainer.frame = CGRect(x: horizontalInset, y: titleLabel.frame.maxY + spacing, width: 0, height: 0)
        
        var previousView: UIView?
        newTitleValueViews.forEach { view in
            if view.superview != valuesContainer {
                valuesContainer.addSubview(view)
            }
            
            let size = view.preferredSize()
            if let previousView = previousView {
                view.frame = CGRect(x: 0, y: previousView.frame.maxY + spacing, width: valuesContainer.frame.width, height: size.height)
            } else {
                view.frame = CGRect(x: 0, y: 0, width: valuesContainer.frame.width, height: size.height)
            }
            view.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            previousView = view
            valuesContainer.frame.size = CGSize(width: max(valuesContainer.frame.width, size.width), height: view.frame.maxY)
        }
        
        bounds = CGRect(
            x: 0,
            y: 0,
            width: max(valuesContainer.frame.maxX + horizontalInset, 140),
            height: valuesContainer.frame.maxY + 8
        )
        backgroundView.frame = bounds
        valuesContainer.frame.size = CGSize(width: backgroundView.frame.width - 2 * horizontalInset, height: valuesContainer.frame.height)
    }
    
    
    private let valueLabel = UILabel()
    private let backgroundView = UIView()
}

extension BarChartValueBoxView: AppearanceSupport {
    func apply(theme: Theme) {
        titleLabel.textColor = Appearance.theme.chartBoxText
        backgroundView.backgroundColor = theme.background
    }
}

private extension BarChartValueBoxView {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E',' d MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
