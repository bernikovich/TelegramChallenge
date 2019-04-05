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
}

extension Chart {
    static var empty: Chart {
        return Chart(legend: Legend(values: []), lines: [])
    }
}
