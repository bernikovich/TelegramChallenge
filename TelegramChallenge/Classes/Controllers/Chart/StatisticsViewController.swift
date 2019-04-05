//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class StatisticsViewController: BaseTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Statistics"
        
        tableView.rowHeight = UIConstants.defaultRowHeight
        tableView.register(cells: [
            ChartTableViewCell.self,
            GraphicSelectionTableViewCell.self,
            SwitchThemeTableViewCell.self
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

    private var chartViewModels: [ChartViewModel] = []

}

extension StatisticsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? HeaderView else {
            return
        }
        header.apply(theme: Appearance.theme)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard
            section < chartViewModels.count,
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderView.id) as? HeaderView
        else {
            return nil
        }
        view.setup(title: "CHART #\(section + 1)")
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return chartViewModels.isEmpty ? 0 : chartViewModels.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= chartViewModels.count {
            return 1
        }
        
        return chartViewModels[section].chart.lines.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        if indexPath.section >= chartViewModels.count {
            return tableView.dequeueReusableCell(for: indexPath) as SwitchThemeTableViewCell
        }
        
        let item = indexPath.item
        let viewModel = chartViewModels[section]
        let chart = viewModel.chart
        if item == 0 {
            let cell = tableView.dequeueReusableCell(for: indexPath) as ChartTableViewCell
            cell.setupWith(viewModel: viewModel)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(for: indexPath) as GraphicSelectionTableViewCell
            let line = chart.lines[item - 1]
            cell.setupWith(line: line, viewModel: viewModel)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section >= chartViewModels.count {
            return UIConstants.defaultRowHeight
        }
        
        if indexPath.row == 0 {
            let tableSide = min(tableView.bounds.width, tableView.bounds.height)
            let height = tableSide > 500 ? tableSide / 2 : tableSide
            return height
        } else {
            return UIConstants.defaultRowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = indexPath.section
        if section >= chartViewModels.count {
            Appearance.switchTheme()
            return
        }
        let item = indexPath.item

        guard item > 0 else {
            return
        }

        let viewModel = chartViewModels[section]
        let line = viewModel.chart.lines[item - 1]
        viewModel.switchLineEnabled(line)
        if let cell = tableView.cellForRow(at: indexPath) as? GraphicSelectionTableViewCell {
            cell.setupWith(line: line, viewModel: viewModel)
        }
    }

}

private enum UIConstants {
    
    static let defaultRowHeight: CGFloat = 44

}

private extension GraphicSelectionTableViewCell {

    func setupWith(line: Line, viewModel: ChartViewModel) {
        self.setupWith(
            title: line.name,
            color: UIColor(hexString: line.colorHex),
            selected: viewModel.isLineEnabled(line)
        )
    }

}
