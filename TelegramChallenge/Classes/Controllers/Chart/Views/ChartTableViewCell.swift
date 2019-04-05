//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

enum ChartConstants {

    static let startChartVisibilityRange = (1 - TrimmerConstants.defaultVisibility)...1

}

final class ChartTableViewCell: BaseTableViewCell, Identifiable {

    override func setup() {
        super.setup()

        contentView.addSubview(chartView)
        contentView.addSubview(legendView)
        contentView.addSubview(trimmerView)

        contentView.addSubview(emptyLabel)
        emptyLabel.text = "No data"
        emptyLabel.font = UIFont.systemFont(ofSize: 24)
        emptyLabel.alpha = 0
        emptyLabel.textAlignment = .center
        
        trimmerView.delegate = self
    }

    override func updateSelection(_ highlighted: Bool, animated: Bool) {}

    override func layoutSubviews() {
        super.layoutSubviews()
        
        clipsToBounds = true
        
        let parentFrame = contentView.frame
        trimmerView.frame = CGRect(
            x: UIConstants.horizontalInset,
            y: parentFrame.height - UIConstants.trimmerViewHeight - UIConstants.verticalInset,
            width: parentFrame.width - 2 * UIConstants.horizontalInset,
            height: UIConstants.trimmerViewHeight
        )
        
        chartView.frame = CGRect(
            x: UIConstants.horizontalInset,
            y: UIConstants.verticalInset,
            width: parentFrame.width - 2 * UIConstants.horizontalInset,
            height: parentFrame.height - trimmerView.frame.height - 2 * UIConstants.verticalInset - UIConstants.legendViewHeight
        )

        let legendFrame = CGRect(
            x: 0,
            y: chartView.frame.maxY,
            width: parentFrame.width,
            height: UIConstants.legendViewHeight
        )

        if legendFrame != legendView.frame {
            legendView.frame = legendFrame
            legendView.update(range: trimmerView.selectedRange)
        }

        emptyLabel.frame = bounds
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
        }

        trimmerView.drawChart(chart, animated: false)
        trimmerView.redraw()

        viewModel.onLinesEnabledUpdate = { [weak self] in
            let lines = viewModel.chart.lines.filter { viewModel.isLineEnabled($0) }
            self?.chartView.setupVisibleLines(lines)
            self?.trimmerView.setupVisibleLines(lines)
            if let oldLines = self?.visibleLines, oldLines.isEmpty != lines.isEmpty {
                self?.updateEmptyState(visibleLines: lines, animated: true)
            }
            self?.visibleLines = lines
        }

        if let visibleLines = visibleLines {
            updateEmptyState(visibleLines: visibleLines, animated: false)
            chartView.setupVisibleLines(visibleLines, animated: false)
            trimmerView.setupVisibleLines(visibleLines, animated: false)
        }
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        trimmerView.apply(theme: theme)
        chartView.apply(theme: theme)
        legendView.apply(theme: theme)
        emptyLabel.textColor = theme.text
    }

    private func updateEmptyState(visibleLines: [Line], animated: Bool) {
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
        visibleLines = nil
        chart = nil
    }

    private var viewModel: ChartViewModel?
    private let chartView = ChartView()
    private let legendView = LegendView()
    private let trimmerView = TrimmerView()
    private let emptyLabel = UILabel()
    
    private var chart: Chart?
    private var visibleLines: [Line]?
}

extension ChartTableViewCell: TrimmerViewDelegate {
    func trimmerView(trimmerView: TrimmerView, didUpdate selectedRange: ClosedRange<CGFloat>) {
        guard viewModel?.selectedRange != selectedRange else {
            return
        }
        viewModel?.selectedRange = selectedRange
        chartView.updateWithRange(selectedRange, forceReload: false, animated: true)
    }
}

private extension ChartTableViewCell {
    func makeLegend(from values: [Date]) -> [String] {
        return values.map(ChartTableViewCell.dateFormatter.string)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }()
}

private enum UIConstants {
    
    static let trimmerViewHeight: CGFloat = 44
    static let legendViewHeight: CGFloat = 24
    static let horizontalInset: CGFloat = 16
    static let verticalInset: CGFloat = 16

}
