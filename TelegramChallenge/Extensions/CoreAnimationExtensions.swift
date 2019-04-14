//
//  Created by Timur Bernikovich on 14/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class DebugHelper {
    
    private(set) var timings: [TimeInterval] = []
    var durations: [TimeInterval] {
        guard !timings.isEmpty else {
            return []
        }
        
        var durations: [TimeInterval] = []
        var previous = timings[0]
        for index in 1..<timings.count {
            let timing = timings[index]
            durations.append(timing - previous)
            previous = timing
        }
        return durations
    }
    var longest: TimeInterval {
        guard timings.count > 1 else {
            return 0
        }
        
        let first = timings[0]
        let last = timings[timings.count - 1]
        return last - first
    }
    
    init() {
        append()
    }
    
    func append() {
        timings.append(CACurrentMediaTime())
    }
    
}
