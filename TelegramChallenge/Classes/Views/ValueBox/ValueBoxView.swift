//
//  Created by Timur Bernikovich on 12/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class ValueBoxView: BaseView {
    
    enum Style {
        case normal, stacked, percent
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
    private var titleValueViews: [ValueBoxTitleValueView] = []
    
    private let backgroundView = UIView()
    let arrowLayer = CAShapeLayer.makeArrow()
    
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
        
        backgroundView.layer.addSublayer(arrowLayer)
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
        var newTitleValueViews: [ValueBoxTitleValueView] = []
        
        let sources: [ValueBoxTitleValueView.Source]
        switch style {
        case .normal:
            sources = columns.map { ValueBoxTitleValueView.Source.column($0) }
        case .stacked:
            sources = columns.map { ValueBoxTitleValueView.Source.column($0) } + (columns.count > 1 ? [.all] : [])
        case .percent:
            sources = columns.map { ValueBoxTitleValueView.Source.column($0) }
        }
        
        let sum = columns.reduce(Int64(0), { $0 + $1.values[index] })
        var columnPercentsFloat: [Int: Double] = [:]
        columns.enumerated().forEach { columnIndex, column in
            columnPercentsFloat[columnIndex] = sum > 0 ? Double(column.values[index]) * 100 / Double(sum) : 0
        }
        let normalizedColumnPercents = PercentCalculator.normalizePercents(columnPercentsFloat)
        
        sources.forEach { source in
            let view: ValueBoxTitleValueView
            if let viewIndex = oldTitleValueViews.firstIndex(where: { $0.source == source }) {
                view = oldTitleValueViews[viewIndex]
                oldTitleValueViews.remove(at: viewIndex)
            } else {
                view = ValueBoxTitleValueView(source: source)
            }
            newTitleValueViews.append(view)
            
            let value: Int64
            let percent: Int?
            switch source {
            case .all:
                value = sum
                percent = nil
            case let .column(column):
                value = column.values[index]
                if let columnIndex = columns.firstIndex(where: { $0 == column }) {
                    percent = style == .percent ? normalizedColumnPercents[columnIndex] : nil
                } else {
                    percent = nil
                }
            }
            
            view.updateWithValue(value, percent: percent) // Animated?
        }
        
        titleValueViews = newTitleValueViews
        oldTitleValueViews.forEach {
            $0.removeFromSuperview()
        }
        
        // Kinda stack view.
        let spacing: CGFloat = 2
        valuesContainer.frame = CGRect(x: horizontalInset, y: titleLabel.frame.maxY + spacing, width: 0, height: 0)
        
        var previousView: UIView?
        var maxPercentWidth: CGFloat = 0
        newTitleValueViews.forEach { view in
            if view.superview != valuesContainer {
                valuesContainer.addSubview(view)
            }
            
            let params = view.preferredSize()
            let size = params.size
            maxPercentWidth = max(maxPercentWidth, params.percentWidth)
            
            if let previousView = previousView {
                view.frame = CGRect(x: 0, y: previousView.frame.maxY + spacing, width: valuesContainer.frame.width, height: size.height)
            } else {
                view.frame = CGRect(x: 0, y: 0, width: valuesContainer.frame.width, height: size.height)
            }
            view.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            previousView = view
            valuesContainer.frame.size = CGSize(width: max(valuesContainer.frame.width, size.width), height: view.frame.maxY)
        }
        newTitleValueViews.forEach {
            $0.percentWidth = maxPercentWidth
        }
        
        bounds = CGRect(
            x: 0,
            y: 0,
            width: max(valuesContainer.frame.maxX + horizontalInset, 148),
            height: valuesContainer.frame.maxY + 8
        )
        backgroundView.frame = bounds
        valuesContainer.frame.size = CGSize(width: backgroundView.frame.width - 2 * horizontalInset, height: valuesContainer.frame.height)
        
        arrowLayer.frame = CGRect(
            x: valuesContainer.frame.maxX - arrowLayer.frame.width,
            y: titleLabel.frame.midY - arrowLayer.frame.height / 2,
            width: arrowLayer.frame.width,
            height: arrowLayer.frame.height
        )
    }
    
}

extension ValueBoxView: AppearanceSupport {
    func apply(theme: Theme) {
        titleLabel.textColor = Appearance.theme.chartBoxText
        backgroundView.backgroundColor = theme.background
        arrowLayer.strokeColor = theme.chartTooltipArrow.cgColor
    }
}

private extension ValueBoxView {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E',' d MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

private extension CAShapeLayer {
    static func makeArrow() -> CAShapeLayer {
        // Relative to 15x15.
        let size = CGSize(width: 6, height: 10)
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 1, y: 1))
        bezierPath.addLine(to: CGPoint(x: 5, y: 5))
        bezierPath.addLine(to: CGPoint(x: 1, y: 9))
        
        let layer = CAShapeLayer()
        layer.frame = CGRect(origin: .zero, size: size)
        
        layer.path = bezierPath.cgPath
        layer.strokeColor = UIColor.white.cgColor
        layer.fillColor = nil
        layer.lineWidth = 2
        layer.lineCap = .round
        layer.lineJoin = .round
        
        return layer
    }
}
