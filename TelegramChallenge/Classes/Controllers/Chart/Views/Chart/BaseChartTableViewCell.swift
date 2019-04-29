//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class BaseChartTableViewCell: BaseTableViewCell {

    struct Item: Equatable {
        let mainViewModel: ChartControlsViewModel
        let detailsViewModelForDataAtIndex: ((Int) -> ChartControlsViewModel?)?
        
        static func ==(lhs: Item, rhs: Item) -> Bool {
            return lhs.mainViewModel === rhs.mainViewModel
        }
    }
    
    class var chartType: ChartType { return .lines }
    private let containerView = UIView()
    private lazy var chartControlsView = ChartControlsView(chartType: type(of: self).chartType)
    private var item: Item?
    
    override func setup() {
        super.setup()
        
        clipsToBounds = true
        contentView.addSubview(containerView)
        containerView.addSubview(chartControlsView)
        chartControlsView.frame = containerView.bounds
        chartControlsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    override func updateSelection(_ highlighted: Bool, animated: Bool) {}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds
    }
    
    func setup(with item: Item) {
        if self.item == item {
            return
        }
        
        chartControlsView.prepareForReuse()
        self.item = item
        
        chartControlsView.setupWith(viewModel: item.mainViewModel)
        if let detailsViewModelForDataAtIndex = item.detailsViewModelForDataAtIndex {
            chartControlsView.onSelectDetails = { [weak self] index in
                if let viewModel = detailsViewModelForDataAtIndex(index) {
                    self?.showDetails(viewModel)
                }
            }
        } else {
            chartControlsView.onSelectDetails = nil
        }
    }
    
    private func showDetails(_ viewModel: ChartControlsViewModel) {
        let detailsChartControlsView = ChartControlsView(chartType: type(of: self).chartType.detailsType)
        detailsChartControlsView.frame = chartControlsView.frame
        detailsChartControlsView.autoresizingMask = chartControlsView.autoresizingMask
        
        viewModel.onZoomOut = { [weak self, weak detailsChartControlsView] in
            guard let view = detailsChartControlsView, let mainView = self?.chartControlsView else {
                return
            }
            
            ChartTransition.zoomOut(mainView: mainView, detailsView: view)
        }
        
        detailsChartControlsView.setupWith(viewModel: viewModel)
        
        containerView.addSubview(detailsChartControlsView)
        ChartTransition.zoomIn(mainView: chartControlsView, detailsView: detailsChartControlsView)
    }
    
    static func preferredHeight(for item: Item, containerWidth: CGFloat) -> CGFloat {
        return ChartControlsView.preferredHeight(
            for: item.mainViewModel,
            chartType: chartType,
            containerWidth: containerWidth
        )
    }

}
