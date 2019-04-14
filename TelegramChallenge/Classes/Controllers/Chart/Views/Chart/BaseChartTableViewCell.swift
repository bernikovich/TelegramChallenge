//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

enum ChartType {
    case lines, twoLines, bars, singleBar, percent
}
extension ChartType {
    var supportsColumnVisibilityChanges: Bool {
        switch self {
        case .singleBar, .twoLines:
            return false
        default:
            return true
        }
    }
}

class BaseChartTableViewCell: BaseTableViewCell {
    
    class var chartType: ChartType { return .lines }
    
    private var chart: Chart?
    private var viewModel: ChartViewModel?
    private var oldVisibleColumns: [Column]? // Is it needed?
    private var visibleColumns: [Column]? {
        guard let viewModel = viewModel else {
            return nil
        }
        return viewModel.chart.columns.filter { viewModel.isColumnEnabled($0) }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    private let titleBackgroundView: GradientView = {
        let view = GradientView()
        view.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        view.gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        return view
    }()
    
    private lazy var chartView: ChartView = {
        return type(of: self).chartViewForType(type(of: self).chartType, simplified: false)
    }()
    
    // We don't clip chart view to bounds.
    // But we don't want them to appear under bottom controls.
    private let controlsGradientBackgroundView: GradientView = {
        let view = GradientView()
        view.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        view.gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        return view
    }()
    private let controlsBackgroundView: GradientView = {
        let view = GradientView()
        view.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        view.gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        return view
    }()
    
    private lazy var legendView: LegendView = {
        return LegendView(chartType: type(of: self).chartType)
    }()
    private lazy var trimmerView: TrimmerView = {
        return TrimmerView(chartView: type(of: self).chartViewForType(type(of: self).chartType, simplified: true))
    }()
    private static func chartViewForType(_ type: ChartType, simplified: Bool) -> ChartView {
        let chartView: ChartView
        switch chartType {
        case .bars:
            chartView = BarChartView(simplified: simplified)
        case .singleBar:
            chartView = BarChartView(simplified: simplified)
        case .lines:
            chartView = LineChartView(simplified: simplified)
        case .twoLines:
            chartView = TwoLinesChartView(simplified: simplified)
        case .percent:
            chartView = PercentChartView(simplified: simplified)
        }
        return chartView
    }
    
    private let filterCollectionView = FilterSwitchCollection()
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No data"
        label.font = UIFont.systemFont(ofSize: 24)
        label.alpha = 0
        label.textAlignment = .center
        return label
    }()
    
    override func setup() {
        super.setup()
        
        clipsToBounds = true
        
        contentView.addSubview(titleBackgroundView)
        contentView.addSubview(titleLabel)
        contentView.insertSubview(chartView, belowSubview: titleBackgroundView)
        contentView.addSubview(controlsGradientBackgroundView)
        contentView.addSubview(controlsBackgroundView)
        contentView.addSubview(legendView)
        contentView.addSubview(trimmerView)
        
        if type(of: self).chartType.supportsColumnVisibilityChanges {
            contentView.addSubview(filterCollectionView)
        }
        
        contentView.addSubview(emptyLabel)
        
        trimmerView.delegate = self
    }
    
    override func updateSelection(_ highlighted: Bool, animated: Bool) {}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        clipsToBounds = true
        
        let parentFrame = contentView.frame
        let contentWidth = parentFrame.width - 2 * UIConstants.horizontalInset
        
        titleLabel.frame = CGRect(
            x: 0,
            y: 0,
            width: parentFrame.width,
            height: UIConstants.titleHeight
        )
        
        titleBackgroundView.frame = titleLabel.frame
        
        chartView.frame = CGRect(
            x: 0,
            y: titleLabel.frame.maxY,
            width: parentFrame.width,
            height: UIConstants.chartHeight
        )
        
        controlsGradientBackgroundView.frame = CGRect(
            x: 0,
            y: chartView.frame.maxY,
            width: parentFrame.width,
            height: titleBackgroundView.frame.height
        )
        controlsBackgroundView.frame = CGRect(
            x: 0,
            y: controlsGradientBackgroundView.frame.maxY,
            width: parentFrame.width,
            height: parentFrame.height - controlsGradientBackgroundView.frame.maxY
        )
        
        let legendFrame = CGRect(
            x: 0,
            y: chartView.frame.maxY,
            width: parentFrame.width,
            height: UIConstants.legendViewHeight
        )
        if legendFrame != legendView.frame {
            let inset = UIEdgeInsets(top: 0, left: UIConstants.horizontalInset, bottom: 0, right: UIConstants.horizontalInset)
            legendView.frame = legendFrame
            legendView.scrollView.contentInset = inset
            legendView.update(range: trimmerView.selectedRange)
        }
        
        trimmerView.frame = CGRect(
            x: 0,
            y: legendView.frame.maxY + UIConstants.trimmerOffset,
            width: parentFrame.width,
            height: UIConstants.trimmerViewHeight
        )
        
        if type(of: self).chartType != .singleBar {
            var filterHeight: CGFloat = 0
            if let viewModel = viewModel {
                let filterItem = type(of: self).filterItemForViewModel(viewModel)
                filterHeight = FilterSwitchCollection.preferredSize(for: filterItem, containerWidth: contentWidth)
            }
            
            filterCollectionView.frame = CGRect(
                x: UIConstants.horizontalInset,
                y: trimmerView.frame.maxY + UIConstants.filterOffset,
                width: contentWidth,
                height: filterHeight
            )
        }
        
        var emptyFrame = bounds
        emptyFrame.size.height = trimmerView.frame.maxY
        emptyLabel.frame = emptyFrame
    }
    
    func setupWith(viewModel: ChartViewModel) {
        let chart = viewModel.chart
        self.chart = viewModel.chart
        self.viewModel = viewModel
        
        chartView.setupWithChart(chart, in: viewModel.selectedRange, animated: false)
        legendView.setup(with: makeLegend(from: chart.legend.values))
        
        viewModel.selectedRangeUpdate = { [weak self] range in
            self?.trimmerView.selectedRange = range
            self?.legendView.update(range: range)
            self?.updateTitle()
        }
        
        trimmerView.drawChart(chart, animated: false)
        trimmerView.redraw()
        
        updateVisibleColumns(visibleColumns, animated: false)
        viewModel.onLinesEnabledUpdate = { [weak self] in
            self?.updateVisibleColumns(self?.visibleColumns, animated: true)
        }
        
        let filterItem = type(of: self).filterItemForViewModel(viewModel)
        filterCollectionView.setup(with: filterItem)
        
        setNeedsLayout()
    }
    
    private func updateVisibleColumns(_ visibleColumns: [Column]?, animated: Bool) {
        guard let visibleColumns = visibleColumns else {
            return
        }
        
        if visibleColumns == oldVisibleColumns {
            return
        }
        
        updateEmptyState(visibleLines: visibleColumns, animated: animated)
        chartView.setupVisibleColumns(visibleColumns, animated: animated)
        trimmerView.setupVisibleColumns(visibleColumns, animated: animated)
        
        if let viewModel = viewModel {
            let filterStates = viewModel.chart.columns.map { viewModel.isColumnEnabled($0) }
            filterCollectionView.updateStates(filterStates, animated: animated)
        }
        
        if let oldVisibleColumns = oldVisibleColumns, oldVisibleColumns.isEmpty != visibleColumns.isEmpty {
            updateEmptyState(visibleLines: visibleColumns, animated: animated)
        }
        
        oldVisibleColumns = visibleColumns
    }
    
    private func updateTitle() {
        guard let viewModel = viewModel else {
            return
        }
        
        let legend = viewModel.chart.legend
        let range = legend.indexRange(for: viewModel.selectedRange)
        let startDate = legend.values[range.lowerBound]
        let endDate = legend.values[range.upperBound]
        titleLabel.text = "\(type(of: self).titleDateFormatter.string(from: startDate)) - \(type(of: self).titleDateFormatter.string(from: endDate))"
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        trimmerView.apply(theme: theme)
        chartView.apply(theme: theme)
        legendView.apply(theme: theme)
        emptyLabel.textColor = theme.text
        titleLabel.textColor = theme.text
        
        let background = theme.main
        let backgroundGradient = [background, background, background.withAlphaComponent(0)]
        titleBackgroundView.gradientLayer.uiColors = backgroundGradient
        controlsGradientBackgroundView.gradientLayer.uiColors = backgroundGradient.reversed()
        controlsBackgroundView.backgroundColor = background
    }
    
    private func updateEmptyState(visibleLines: [Column], animated: Bool) {
        UIView.animate(withDuration: animated ? SharedConstants.animationDuration : 0) {
            let hasData = !visibleLines.isEmpty
            [self.legendView, self.trimmerView, self.chartView].forEach { $0.alpha = hasData ? 1 : 0 }
            self.emptyLabel.alpha = hasData ? 0 : 1
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        chartView.clear()
        legendView.clean()
        viewModel = nil
        oldVisibleColumns = nil
        chart = nil
    }
    
    static func preferredHeight(for viewModel: ChartViewModel, containerWidth: CGFloat) -> CGFloat {
        var height: CGFloat = 0
        height += UIConstants.titleHeight
        height += UIConstants.chartHeight
        height += UIConstants.legendViewHeight
        height += UIConstants.trimmerOffset
        height += UIConstants.trimmerViewHeight
        
        if chartType.supportsColumnVisibilityChanges {
            height += UIConstants.filterOffset
            let filterSwitchWidth = containerWidth - 2 * UIConstants.horizontalInset
            let filterItem = filterItemForViewModel(viewModel)
            height += FilterSwitchCollection.preferredSize(for: filterItem, containerWidth: filterSwitchWidth)
        }
        
        height += UIConstants.bottomInset
        return height
    }
    
    private static func filterItemForViewModel(_ viewModel: ChartViewModel) -> FilterSwitchCollection.Item {
        let items = viewModel.chart.columns.map {
            FilterSwitch.Item(color: UIColor(hexString: $0.colorHex), text: $0.name)
        }
        let initialStates = viewModel.chart.columns.map { viewModel.isColumnEnabled($0) }
        
        
        let onSelect: (Int) -> () = {
            viewModel.switchColumnVisibilityState(viewModel.chart.columns[$0])
        }
        let onLongPress: (Int) -> () = {
            viewModel.hideAllColumnsBut(viewModel.chart.columns[$0])
        }
        
        return FilterSwitchCollection.Item(
            switchItems: items,
            states: initialStates,
            onSelectItem: onSelect,
            onLongPressItem: onLongPress
        )
    }
    
}

extension BaseChartTableViewCell: TrimmerViewDelegate {
    func trimmerView(trimmerView: TrimmerView, didUpdate selectedRange: ClosedRange<CGFloat>) {
        guard viewModel?.selectedRange != selectedRange else {
            return
        }
        
        let time1 = CACurrentMediaTime()
        viewModel?.selectedRange = selectedRange
        let time2 = CACurrentMediaTime()
        chartView.updateWithRange(selectedRange, forceReload: false, animated: true)
        print("---")
        print("Range change time1: \(time2 - time1)")
        print("Range change time2: \(CACurrentMediaTime() - time2)")
        if CACurrentMediaTime() - time1 > 0.02 {
            print("___")
        }
    }
}

private extension BaseChartTableViewCell {
    func makeLegend(from values: [Date]) -> [String] {
        return values.map(type(of: self).dateFormatter.string)
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Simplification.
        return formatter
    }()
    
    private static let titleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Simplification.
        return formatter
    }()
}

private enum UIConstants {
    
    static let titleHeight: CGFloat = 40
    
    // Optimize for different devices.
    static let chartHeight: CGFloat = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width) <= 320 ? 240 : 280
    static let legendViewHeight: CGFloat = 28
    static let trimmerOffset: CGFloat = 6
    static let trimmerViewHeight: CGFloat = 44
    static let filterOffset: CGFloat = 16
    static let bottomInset: CGFloat = 16
    
    static let horizontalInset: CGFloat = SharedConstants.horizontalInset
    
}
