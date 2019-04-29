//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class StatisticsViewController: BaseTableViewController {
    
    private var items: [BaseChartTableViewCell.Item] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Statistics"
        
        tableView.register(cells: [
            BarChartTableViewCell.self,
            LineChartTableViewCell.self,
            SingleBarChartTableViewCell.self,
            PercentChartTableViewCell.self,
            TwoLinesChartTableViewCell.self
        ])

        tableView.register(HeaderView.self, forHeaderFooterViewReuseIdentifier: HeaderView.id)
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)

        tableView.delegate = self
        tableView.dataSource = self

        loadCharts()
    }

    private func loadCharts() {
        ChartFetchService.loadCharts { [weak self] chartInfoCollection in
            self?.items = chartInfoCollection.map { chartInfo in
                let chart = chartInfo.mainChart
                let detailsClosure: ((Int) -> ChartControlsViewModel?) = { index -> ChartControlsViewModel? in
                    let date = chart.legend.values[index]
                    let hourFormatter = DateFormatter()
                    hourFormatter.locale = Locale(identifier: "en_US_POSIX")
                    hourFormatter.dateFormat = "hh:mm"
                    return chartInfo.detailsChartForDate(date).map { ChartControlsViewModel(chart: $0, legendDateFormatter: hourFormatter) }
                }
                
                return BaseChartTableViewCell.Item(
                    mainViewModel: ChartControlsViewModel(chart: chart, legendDateFormatter: nil),
                    detailsViewModelForDataAtIndex: detailsClosure
                )
            }
            self?.tableView.reloadData()
        }
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        let title: String
        if theme is NightTheme {
            title = "Day Mode"
        } else {
            title = "Night Mode"
        }
        let barButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(switchTheme))
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    @objc func switchTheme(_ sender: Any?) {
        Appearance.switchTheme()
    }

}

extension StatisticsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? HeaderView else {
            return
        }
        header.apply(theme: Appearance.theme)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderView.id) as? HeaderView else {
            return nil
        }
        
        view.setup(title: "CHART #\(section + 1)")
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let start = CACurrentMediaTime()
        
        let section = indexPath.section
        let item = items[section]
        let viewModel = item.mainViewModel
        
        // TODO: Implement with some kind of switch.
        let resultCell: BaseChartTableViewCell
        if viewModel.chart.isPercentage {
            let cell: PercentChartTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            resultCell = cell
        } else if viewModel.chart.isStacked {
            let cell: BarChartTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            resultCell = cell
        } else if viewModel.chart.columns.count == 1, viewModel.chart.columns[0].style == .bar {
            let cell: SingleBarChartTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            resultCell = cell
        } else if viewModel.chart.isYScaled && viewModel.chart.columns.count == 2 {
            let cell: TwoLinesChartTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            resultCell = cell
        } else {
            let cell: LineChartTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            resultCell = cell
        }
        resultCell.setup(with: item)
        
        let end = CACurrentMediaTime()
        print("cellForRowAt: \(end - start)")
        
        return resultCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.section]
        let viewModel = item.mainViewModel
        if viewModel.chart.isPercentage {
            return PercentChartTableViewCell.preferredHeight(for: item, containerWidth: tableView.bounds.width)
        } else if viewModel.chart.isStacked {
            return BarChartTableViewCell.preferredHeight(for: item, containerWidth: tableView.bounds.width)
        } else if viewModel.chart.columns.count == 1, viewModel.chart.columns[0].style == .bar {
            return  SingleBarChartTableViewCell.preferredHeight(for: item, containerWidth: tableView.bounds.width)
        } else if viewModel.chart.isYScaled && viewModel.chart.columns.count == 2 {
            return TwoLinesChartTableViewCell.preferredHeight(for: item, containerWidth: tableView.bounds.width)
        } else {
            return LineChartTableViewCell.preferredHeight(for: item, containerWidth: tableView.bounds.width)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
