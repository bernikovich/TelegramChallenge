//
//  Created by Timur Bernikovich on 3/12/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

enum ChartConstants {
    
    // Do we need this?
    static let startChartVisibilityRange = (1 - TrimmerConstants.defaultVisibility)...1
    
}

final class ChartControlsViewModel {

    let chart: Chart
    let legendDateFormatter: DateFormatter
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
    var onZoomOut: (() -> ())?
    
    init(chart: Chart, legendDateFormatter: DateFormatter?) {
        self.chart = chart
        if let legendDateFormatter = legendDateFormatter {
            self.legendDateFormatter = legendDateFormatter
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "d MMM"
            self.legendDateFormatter = formatter
        }
        
        visibleColumns = Set(chart.columns)
    }

    func switchColumnVisibilityState(_ column: Column) -> Bool {
        // We don't want to make hiding all columns pos
        if visibleColumns.count == 1, let visibleColumn = visibleColumns.first, visibleColumn == column {
            return false
        }
        
        if visibleColumns.remove(column) == nil {
            visibleColumns.insert(column)
        }
        onLinesEnabledUpdate?()
        return true
    }
    func hideAllColumnsBut(_ column: Column) {
        visibleColumns = [column]
        onLinesEnabledUpdate?()
    }

    func isColumnEnabled(_ line: Column) -> Bool {
        return visibleColumns.contains(line)
    }
    
}
