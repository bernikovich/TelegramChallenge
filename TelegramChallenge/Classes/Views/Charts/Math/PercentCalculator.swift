//
//  Created by Timur Bernikovich on 15/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import Foundation

class PercentCalculator {
    
    static func normalizePercents(_ percents: [Int: Double]) -> [Int: Int] {
        guard !percents.isEmpty else {
            return [:]
        }
        
        let targetPercent = 100
        let currentSum = percents.values.reduce(Int(0), { $0 + Int($1) })
        let reminders = percents.mapValues { $0 - Double(Int($0)) }
        
        let defaultIndexForChanges = 0
        
        if currentSum == targetPercent {
            return percents.mapValues { Int($0) }
        } else if currentSum < targetPercent {
            // Increase value with biggest reminder.
            if let maxReminder = reminders.values.max(),
                let targetIndex = reminders.first(where: { $0.value == maxReminder })?.key {
                var newPercents = percents
                newPercents[targetIndex] = Double(Int64(percents[targetIndex] ?? 0) + 1)
                return normalizePercents(newPercents)
            } else {
                var newPercents = percents
                newPercents[defaultIndexForChanges] = Double(Int64(percents[defaultIndexForChanges] ?? 0) + 1)
                return normalizePercents(newPercents)
            }
        } else {
            // Reduce value with smallest reminder.
            if let minReminder = reminders.values.min(),
                let targetIndex = reminders.first(where: { $0.value == minReminder })?.key {
                var newPercents = percents
                newPercents[targetIndex] = Double(Int64(percents[targetIndex] ?? 0) - 1)
                return normalizePercents(newPercents)
            } else {
                var newPercents = percents
                newPercents[defaultIndexForChanges] = Double(Int64(percents[defaultIndexForChanges] ?? 0) - 1)
                return normalizePercents(newPercents)
            }
        }
    }

}
