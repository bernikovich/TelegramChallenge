//
//  Created by Timur Bernikovich on 15/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class ChartControlsView: BaseView, AppearanceSupport {
    
    let chartType: ChartType
    
    private var chart: Chart?
    private var viewModel: ChartControlsViewModel?
    var onSelectDetails: ((Int) -> ())? {
        didSet {
            chartView.onSelectDetails = onSelectDetails
        }
    }
    private var oldVisibleColumns: [Column]? // Is it needed?
    private var visibleColumns: [Column]? {
        guard let viewModel = viewModel else {
            return nil
        }
        return viewModel.chart.columns.filter { viewModel.isColumnEnabled($0) }
    }
    
    private let headerView: GradientView = {
        let view = GradientView()
        view.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        view.gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        return view
    }()
    private let zoomOutView = ZoomOutView()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    lazy var chartView: ChartView = {
        return type(of: self).chartViewForType(chartType, simplified: false)
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
        return LegendView(chartType: chartType)
    }()
    private lazy var trimmerView: TrimmerView = {
        return TrimmerView(chartView: type(of: self).chartViewForType(chartType, simplified: true))
    }()
    
    init(chartType: ChartType) {
        self.chartType = chartType
        super.init(frame: .zero)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func chartViewForType(_ type: ChartType, simplified: Bool) -> ChartView {
        let chartView: ChartView
        switch type {
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
        case .pie:
            if simplified {
                chartView = PercentChartView(simplified: simplified)
            } else {
                chartView = PieChartView(simplified: simplified)
            }
        }
        return chartView
    }
    
    private let filterCollectionView = FilterSwitchCollection()
    
    override func setup() {
        super.setup()
        
        subscribeToAppearanceUpdates()
        
        clipsToBounds = true
        
        addSubview(headerView)
        headerView.addSubview(zoomOutView)
        headerView.addSubview(titleLabel)
        insertSubview(chartView, belowSubview: headerView)
        addSubview(controlsGradientBackgroundView)
        addSubview(controlsBackgroundView)
        addSubview(legendView)
        legendView.isHidden = chartType == .pie
        addSubview(trimmerView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ChartControlsView.onZoomOutTap(_:)))
        tapGesture.numberOfTouchesRequired = 1
        zoomOutView.addGestureRecognizer(tapGesture)
        
        if chartType.supportsColumnVisibilityChanges {
            addSubview(filterCollectionView)
        }
        
        trimmerView.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        clipsToBounds = true
        
        let parentFrame = frame
        let contentWidth = parentFrame.width - 2 * UIConstants.horizontalInset
        
        headerView.frame = CGRect(
            x: 0,
            y: 0,
            width: parentFrame.width,
            height: UIConstants.titleHeight
        )
        updateHeader()
        
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
            height: headerView.frame.height
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
        
        if chartType != .singleBar {
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
    }
    
    @objc func onZoomOutTap(_ sender: UITapGestureRecognizer) {
        viewModel?.onZoomOut?()
    }
    
    func setupWith(viewModel: ChartControlsViewModel) {
        let chart = viewModel.chart
        self.chart = viewModel.chart
        self.viewModel = viewModel
        
        zoomOutView.isHidden = viewModel.onZoomOut == nil
        chartView.setupWithChart(chart, in: viewModel.selectedRange, animated: false)
        legendView.setup(with: makeLegend(from: chart.legend.values))
        
        viewModel.selectedRangeUpdate = { [weak self] range in
            self?.trimmerView.selectedRange = range
            self?.legendView.update(range: range)
            self?.updateHeader()
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
        
        chartView.setupVisibleColumns(visibleColumns, animated: animated)
        trimmerView.setupVisibleColumns(visibleColumns, animated: animated)
        
        if let viewModel = viewModel {
            let filterStates = viewModel.chart.columns.map { viewModel.isColumnEnabled($0) }
            filterCollectionView.updateStates(filterStates, animated: animated)
        }
        
        oldVisibleColumns = visibleColumns
    }
    
    private func updateHeader() {
        guard let viewModel = viewModel else {
            return
        }
        
        zoomOutView.frame = CGRect(
            x: SharedConstants.horizontalInset,
            y: 0,
            width: zoomOutView.preferredWidth(),
            height: headerView.frame.height
        )
        
        let legend = viewModel.chart.legend
        let range = legend.indexRange(for: viewModel.selectedRange)
        let startDate = legend.values[range.lowerBound]
        let endDate = legend.values[range.upperBound]
        let dateFormatter = type(of: self).titleDateFormatter
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        if startDateString == endDateString {
            titleLabel.text = "\(startDateString)"
        } else {
            titleLabel.text = "\(startDateString) - \(endDateString)"
        }
        
        let titleSize = titleLabel.sizeThatFits(CGSize(width: CGFloat.Magnitude.greatestFiniteMagnitude, height: CGFloat.Magnitude.greatestFiniteMagnitude)).ceiled()
        var titleFrame = CGRect(
            x: (headerView.frame.width - titleSize.width) / 2,
            y: 0,
            width: titleSize.width,
            height: headerView.frame.height
        )
        let minimumOriginX = zoomOutView.frame.maxX + 6
        if !zoomOutView.isHidden {
            titleFrame.origin.x = max(titleFrame.origin.x, minimumOriginX)
        }
        titleLabel.frame = titleFrame
    }
    
    func apply(theme: Theme) {
        trimmerView.apply(theme: theme)
        chartView.apply(theme: theme)
        legendView.apply(theme: theme)
        titleLabel.textColor = theme.text
        
        let background = theme.main
        let backgroundGradient = [background, background, background.withAlphaComponent(0)]
        backgroundColor = background
        headerView.gradientLayer.uiColors = backgroundGradient
        controlsGradientBackgroundView.gradientLayer.uiColors = backgroundGradient.reversed()
        controlsBackgroundView.backgroundColor = background
    }
    
    func prepareForReuse() {
        chartView.clear()
        legendView.clean()
        viewModel = nil
        oldVisibleColumns = nil
        chart = nil
    }
    
    static func preferredHeight(for viewModel: ChartControlsViewModel, chartType: ChartType, containerWidth: CGFloat) -> CGFloat {
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
    
    private static func filterItemForViewModel(_ viewModel: ChartControlsViewModel) -> FilterSwitchCollection.Item {
        let items = viewModel.chart.columns.map {
            FilterSwitch.Item(color: UIColor(hexString: $0.colorHex), text: $0.name)
        }
        let initialStates = viewModel.chart.columns.map { viewModel.isColumnEnabled($0) }
        
        
        let onSelect: (Int) -> (Bool) = {
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

extension ChartControlsView: TrimmerViewDelegate {
    func trimmerView(trimmerView: TrimmerView, didUpdate selectedRange: ClosedRange<CGFloat>) {
        guard viewModel?.selectedRange != selectedRange else {
            return
        }
        
        viewModel?.selectedRange = selectedRange
        chartView.updateWithRange(selectedRange, forceReload: false, animated: true)
    }
}

private extension ChartControlsView {
    func makeLegend(from values: [Date]) -> [String] {
        return values.map {
            viewModel?.legendDateFormatter.string(from: $0) ?? ""
        }
    }
    
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

class ZoomOutView: BaseView, AppearanceSupport {
    private let arrowLayer = CAShapeLayer.makeArrow()
    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.text = "Zoom Out"
        return label
    }()
    
    override func setup() {
        super.setup()
        
        subscribeToAppearanceUpdates()
        
        layer.addSublayer(arrowLayer)
        arrowLayer.frame = CGRect(origin: .zero, size: CGSize(width: 6, height: 10))
        
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var arrowFrame = arrowLayer.frame
        arrowFrame.origin.x = 0
        arrowFrame.origin.y = (bounds.height - arrowFrame.height) / 2
        arrowLayer.frame = arrowFrame
        
        label.frame = CGRect(
            x: arrowLayer.frame.maxX + 6,
            y: 0,
            width: bounds.width - (arrowLayer.frame.minX + 6),
            height: bounds.height)
    }
    
    func preferredWidth() -> CGFloat {
        let labelSize = label.sizeThatFits(CGSize(width: CGFloat.Magnitude.greatestFiniteMagnitude, height: CGFloat.Magnitude.greatestFiniteMagnitude)).ceiled()
        let spacing: CGFloat = 6
        return 6 + spacing + labelSize.width
    }
    
    func apply(theme: Theme) {
        arrowLayer.strokeColor = theme.accent.cgColor
        label.textColor = theme.accent
    }
    
}

private extension CAShapeLayer {
    static func makeArrow() -> CAShapeLayer {
        // Relative to 5x10.
        let size = CGSize(width: 6, height: 10)
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 5, y: 1))
        bezierPath.addLine(to: CGPoint(x: 1, y: 5))
        bezierPath.addLine(to: CGPoint(x: 5, y: 9))
        
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
