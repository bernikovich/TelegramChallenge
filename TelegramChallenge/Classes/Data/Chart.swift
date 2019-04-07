//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import Foundation

struct Chart {
    let legend: Legend
    let lines: [Line]
}

struct Legend {
    let values: [Date]
}

struct Line: Hashable {
    let name: String
    let colorHex: String
    let values: [Int64]
    
    // For optimization purpose.
    let minValue: Int64?
    let maxValue: Int64?
    
    init(name: String, colorHex: String, values: [Int64]) {
        self.name = name
        self.colorHex = colorHex
        self.values = values
        
        self.minValue = values.min()
        self.maxValue = values.max()
    }
}

extension Chart {
    static var empty: Chart {
        return Chart(legend: Legend(values: []), lines: [])
    }
}
