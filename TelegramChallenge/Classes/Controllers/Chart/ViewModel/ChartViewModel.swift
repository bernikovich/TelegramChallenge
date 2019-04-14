//
//  Created by Timur Bernikovich on 3/12/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

enum ChartConstants {
    
    // Do we need this?
    static let startChartVisibilityRange = (1 - TrimmerConstants.defaultVisibility)...1
    
}

final class ChartViewModel {

    let chart: Chart
    private var visibleColumns: Set<Column>

    var selectedRange = ChartConstants.startChartVisibilityRange {
        didSet {
            guard oldValue != selectedRange else {
                return
            }
            selectedRangeUpdate?(selectedRange)
        }
    }

    var selectedRangeUpdate: ((ClosedRange<CGFloat>) -> ())? {
        didSet {
            selectedRangeUpdate?(selectedRange)
        }
    }
    var onLinesEnabledUpdate: (() -> ())? {
        didSet {
            onLinesEnabledUpdate?()
        }
    }
    
    init(chart: Chart) {
        self.chart = chart
        visibleColumns = Set(chart.columns)
    }

    func switchColumnVisibilityState(_ column: Column) {
        // We don't want to make hiding all columns pos
        if visibleColumns.count == 1, let visibleColumn = visibleColumns.first, visibleColumn == column {
            return
        }
        
        if visibleColumns.remove(column) == nil {
            visibleColumns.insert(column)
        }
        onLinesEnabledUpdate?()
    }
    func hideAllColumnsBut(_ column: Column) {
        visibleColumns = [column]
        onLinesEnabledUpdate?()
    }

    func isColumnEnabled(_ line: Column) -> Bool {
        return visibleColumns.contains(line)
    }
    
}
