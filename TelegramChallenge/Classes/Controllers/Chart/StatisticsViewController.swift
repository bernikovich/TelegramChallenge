//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class StatisticsViewController: BaseTableViewController {
    
    private var chartViewModels: [ChartViewModel] = []
    
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
        ChartFetchService.loadCharts { [weak self] charts in
            self?.chartViewModels = charts.map(ChartViewModel.init)
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
        return chartViewModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let viewModel = chartViewModels[section]
        
        // TODO: Implement with some kind of switch.
        if viewModel.chart.isPercentage {
            let cell: PercentChartTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.setupWith(viewModel: viewModel)
            return cell
        } else if viewModel.chart.isStacked {
            let cell: BarChartTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.setupWith(viewModel: viewModel)
            return cell
        } else if viewModel.chart.columns.count == 1, viewModel.chart.columns[0].style == .bar {
            let cell: SingleBarChartTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.setupWith(viewModel: viewModel)
            return cell
        } else if viewModel.chart.isYScaled && viewModel.chart.columns.count == 2 {
            let cell: TwoLinesChartTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.setupWith(viewModel: viewModel)
            return cell
        } else {
            let cell: LineChartTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.setupWith(viewModel: viewModel)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let viewModel = chartViewModels[indexPath.section]
        if viewModel.chart.isPercentage {
            return PercentChartTableViewCell.preferredHeight(for: viewModel, containerWidth: tableView.bounds.width)
        } else if viewModel.chart.isStacked {
            return BarChartTableViewCell.preferredHeight(for: viewModel, containerWidth: tableView.bounds.width)
        } else if viewModel.chart.columns.count == 1, viewModel.chart.columns[0].style == .bar {
            return  SingleBarChartTableViewCell.preferredHeight(for: viewModel, containerWidth: tableView.bounds.width)
        } else if viewModel.chart.isYScaled && viewModel.chart.columns.count == 2 {
            return TwoLinesChartTableViewCell.preferredHeight(for: viewModel, containerWidth: tableView.bounds.width)
        } else {
            return LineChartTableViewCell.preferredHeight(for: viewModel, containerWidth: tableView.bounds.width)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
