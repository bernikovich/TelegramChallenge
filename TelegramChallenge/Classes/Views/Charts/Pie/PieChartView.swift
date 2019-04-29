//
//  Created by Timur Bernikovich on 15/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class PieChartView: BaseChartView, ChartView {
    
    private let view = InnerPieChartView()
    
    override func setup() {
        super.setup()
        
        contentView.addSubview(view)
        view.frame = contentView.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func setupWithChart(_ chart: Chart, in range: ClosedRange<CGFloat>, animated: Bool) {
        let time = CACurrentMediaTime()
        self.chart = chart
        self.range = range
        self.visibleColumns = chart.columns
        redraw(animated: false)
        let tim2 = CACurrentMediaTime()
        if tim2 - time > 0.01 {
            print(":(")
        }
    }
    
    func updateWithRange(_ range: ClosedRange<CGFloat>, forceReload: Bool, animated: Bool) {
        self.range = range
        redraw(animated: true)
    }
    
    func setupVisibleColumns(_ visibleColumns: [Column], animated: Bool) {
        self.visibleColumns = visibleColumns
        redraw(animated: true)
    }
    
    func clear() {
        
    }
    
    func redraw(animated: Bool) {
        let segments = chart.columns.map { column -> PieSegment in
            let valuesRange = column.indexRange(for: range)
            let value: CGFloat
            if visibleColumns.contains(column) {
                value = column.values[valuesRange].reduce(CGFloat(0), {
                    $0 + CGFloat($1)
                })
            } else {
                value = 0
            }
            let color = UIColor(hexString: column.colorHex)
            return PieSegment(identifier: column.name, color: color, value: value)
        }
        view.updateWithSegements(segments, animated: animated)
    }
    
    func apply(theme: Theme) {
        
    }
    
}
