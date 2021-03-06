//
//  Created by Timur Bernikovich on 14/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

struct Plot: Equatable {
    let range: ClosedRange<Int64>
    let step: Int64
}

extension Plot {
    var numberOfLines: Int64 {
        return (range.upperBound - range.lowerBound) / step + 1
    }
    var lineValues: [Int64] {
        return Array(0..<numberOfLines).map {
            range.lowerBound + $0 * step
        }
    }
}

class PlotCalculator {
    let numberOfSteps: Double
    let numberOfChunks: Int
    let zeroOrigin: Bool

    // Not optimized for UI!
    private var discretePlots: [Plot] = []

    init(numberOfSteps: Double = 1, numberOfChunks: Int, zeroOrigin: Bool) {
        self.numberOfSteps = numberOfSteps
        self.numberOfChunks = numberOfChunks
        self.zeroOrigin = zeroOrigin
    }

    func verticalPlot(for range: ClosedRange<CGFloat>) -> Plot {
        let count = discretePlots.count
        let lowerIndex = Int(floor(CGFloat(count) * range.lowerBound))
        let upperIndex = Int(ceil(CGFloat(count) * range.upperBound))
        let safeRange = (lowerIndex..<upperIndex).clamped(to: 0..<count)
        let plots = Array(discretePlots[safeRange])
        
        let minValue = plots.map({ $0.range.lowerBound }).min()
        let maxValue = plots.map({ $0.range.upperBound }).max()
        
        var optimizedPlot: Plot?
        if let minValue = minValue, let maxValue = maxValue {
            optimizedPlot = optimizedVerticalPlot(for: [minValue, maxValue], origin: zeroOrigin ? 0 : nil)
        }
        
        let anyOtherPlot = plots.first ?? Plot(range: 0...1, step: 1)
        return optimizedPlot ?? anyOtherPlot
    }

    func updatePreloadedPlots(columns: [Column]) {
        let delta = 1 / CGFloat(numberOfChunks)
        var plots: [Plot] = []
        for index in 0..<numberOfChunks {
            let start = CGFloat(index) * delta
            let end = start + delta
            
            let range = start...end
            
            var minValue: Int64?
            var maxValue: Int64?
            columns.forEach {
                let valuesRange = $0.valuesRangeInRange(range)
                minValue = min(minValue ?? Int64.max, valuesRange.lowerBound)
                maxValue = max(maxValue ?? Int64.min, valuesRange.upperBound)
            }
            
            let notOptimizedPlot = Plot(range: (minValue ?? 0)...(maxValue ?? 1), step: 1)
            plots.append(notOptimizedPlot)
        }
        discretePlots = plots
    }
    
    func updatePreloadedPlots(sum: StackBarSum) {
        let delta = 1 / CGFloat(numberOfChunks)
        var plots: [Plot] = []
        for index in 0..<numberOfChunks {
            let start = CGFloat(index) * delta
            let end = start + delta
            
            let range = start...end
            
            let valuesRange = sum.valuesRangeInRange(range)
            let minValue = valuesRange.lowerBound
            let maxValue = valuesRange.upperBound
            
            let notOptimizedPlot = Plot(range: minValue...maxValue, step: 1)
            plots.append(notOptimizedPlot)
        }
        discretePlots = plots
    }
    
    private func optimizedVerticalPlot(for values: [Int64], origin preferredOrigin: Int64? = nil) -> Plot {
        let defaultPlotRange = Plot(range: 0...5, step: 1)
        
        // First of all we find min and max values.
        guard var maxValue = values.max(), let minValue = values.min(), minValue != maxValue else {
            return defaultPlotRange
        }
        
        let origin: Int64
        if let preferredOrigin = preferredOrigin {
            origin = preferredOrigin
        } else {
            origin = prefferedOrigin(minValue: minValue, maxValue: maxValue)
        }
        
        // The idea here is to find such plot which
        // will contain N steps
        let delta = maxValue - origin
        let step = Double(delta) / (numberOfSteps)
        let roundedStep: Int64
        if step < 4 {
            roundedStep = step.ceil(base: 1)
        } else if step < 10 {
            roundedStep = step.ceil(base: 2)
        } else if step < 30 {
            roundedStep = step.ceil(base: 4)
        } else if step < 80 {
            roundedStep = step.ceil(base: 10)
        } else {
            let log = log10(Double(step))
            let power = Double(Int(log))
            let roundBase = Int64(pow(10, power))
            roundedStep = step.ceil(base: roundBase)
        }
        maxValue = Int64(Double(origin) + Double(roundedStep) * numberOfSteps)
        
        return Plot(range: origin...maxValue, step: roundedStep)
    }
    
    private func prefferedOrigin(minValue: Int64, maxValue: Int64) -> Int64 {
        guard minValue != maxValue else {
            return minValue
        }
        
        let maximumEmptyPartOfChart: Double = 0.2
        if minValue > 0 && (Double(minValue) / Double(maxValue)) < maximumEmptyPartOfChart {
            return 0
        }
        
        // Just round minimum value here.
        let delta = maxValue - minValue
        let log = log10(Double(delta))
        let power = Double(Int(log))
        let roundBase = Int64(pow(10, power)) // Doesn't really work for case [3999, 5000] min -> 3000
        let origin = Double(minValue).floor(base: roundBase)

        return origin
    }
}

extension Double {
    func ceil(base: Int64) -> Int64 {
        return Int64(Darwin.ceil(self / Double(base)) * Double(base))
    }
    
    func floor(base: Int64) -> Int64 {
        return Int64(Darwin.floor(self / Double(base)) * Double(base))
    }
}
