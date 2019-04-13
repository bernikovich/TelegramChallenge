//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import Foundation

struct Chart {
    let legend: Legend
    let columns: [Column]
    
    //    chart.percentage – true for percentage based values.
    //    chart.stacked – true for values stacking on top of each other.
    //    chart.y_scaled – true for charts with 2 Y axes.
    let isPercentage: Bool
    let isStacked: Bool
    let isYScaled: Bool
}

struct Legend {
    let values: [Date]
}

struct Column {
    enum Style: String {
        case line, bar, area
    }
    
    let name: String
    let style: Style
    let colorHex: String
    let values: [Int64]
    
    // For optimization purpose.
    let minValue: Int64?
    let maxValue: Int64?
    
    init(name: String, style: Style, colorHex: String, values: [Int64]) {
        self.name = name
        self.style = style
        self.colorHex = colorHex
        self.values = values
        
        self.minValue = values.min()
        self.maxValue = values.max()
    }
}

extension Column: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(colorHex)
        hasher.combine(values.count)
    }
    
    static func ==(lhs: Column, rhs: Column) -> Bool {
        return lhs.name == rhs.name
            && lhs.colorHex == rhs.colorHex
            && lhs.values.count == rhs.values.count
    }

}

extension Chart {
    static var empty: Chart {
        return Chart(legend: Legend(values: []), columns: [], isPercentage: false, isStacked: false, isYScaled: false)
    }
}
