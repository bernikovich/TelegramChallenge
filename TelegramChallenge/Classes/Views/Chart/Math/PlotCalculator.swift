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

    private var currentPlots: [Plot] = []

    init(numberOfSteps: Double = 1) {
        self.numberOfSteps = numberOfSteps
    }

    func verticalPlot(for range: ClosedRange<CGFloat>) -> Plot {
        let count = currentPlots.count
        let lowerIndex = Int(floor(CGFloat(count) * range.lowerBound))
        let upperIndex = Int(ceil(CGFloat(count) * range.upperBound))
        let safeRange = (lowerIndex..<upperIndex).clamped(to: 0..<count)
        let plots = Array(currentPlots[safeRange])
        let maxPlot = plots.max(by: { $0.range.upperBound < $1.range.upperBound }) ?? plots[0]
        return maxPlot
    }

    func updatePreloadedPlots(lines: [Line]) {
        let chunks = 20
        let delta = 1 / CGFloat(chunks)

        var plots: [Plot] = []
        for i in 0..<chunks {
            let start = CGFloat(i) * delta
            let range = (CGFloat(i) * delta)...(start + delta)
            let maxValue = lines
                .map { $0.valuesInRange(range).max() ?? 0}
                .max() ?? 0
            let minValue = lines
                .map { $0.valuesInRange(range).min() ?? 0}
                .min() ?? 0
            plots.append(verticalPlot(for: [minValue, maxValue], origin: origin(for: lines.flatMap({ $0.values }))))
        }
        self.currentPlots = plots
    }
    
    private func verticalPlot(for values: [Int64], origin: Int64) -> Plot {
        let defaultPlotRange = Plot(range: 0...5, step: 1)
        
        // First of all we find min and max values.
        guard var maxValue = values.max(), origin != maxValue else {
            return defaultPlotRange
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
    
    private func origin(for values: [Int64]) -> Int64 {
        guard let maxValue = values.max(), var minValue = values.min() else {
            return 0
        }
        
        guard minValue != maxValue else {
            return minValue
        }
        
        let maximumEmptyPartOfChart: Double = 0.4
        if minValue > 0 && (Double(minValue) / Double(maxValue)) < maximumEmptyPartOfChart {
            return 0
        }
        
        // Just round minimum value here.
        let delta = maxValue - minValue
        let log = log10(Double(delta))
        let power = Double(Int(log))
        let roundBase = Int64(pow(10, power)) // Doesn't really work for case [3999, 5000] min -> 3000
        minValue = Double(minValue).floor(base: roundBase)
        return minValue
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
