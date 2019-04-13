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
        linesEnabled = Set(chart.columns)
    }

    func switchLineEnabled(_ line: Column) {
        if linesEnabled.remove(line) == nil {
            linesEnabled.insert(line)
        }
        onLinesEnabledUpdate?()
    }

    func isColumnEnabled(_ line: Column) -> Bool {
        return linesEnabled.contains(line)
    }

    private var linesEnabled: Set<Column>
    
}
