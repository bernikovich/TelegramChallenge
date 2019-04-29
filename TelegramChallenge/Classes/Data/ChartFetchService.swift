//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

struct ChartInfo {
    let mainChart: Chart
    let detailsChartForDate: ((Date) -> Chart?)
}

final class ChartFetchService {

    static func loadCharts(completion: @escaping ([ChartInfo]) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let chartInfoCollection = ChartFetchService.loadMainCharts()
            DispatchQueue.main.async {
                completion(chartInfoCollection)
            }
        }
    }
    
    private static func loadMainCharts() -> [ChartInfo] {
        let folders = ["1", "2", "3", "4", "5"]
        
        let monthDateFormatter = DateFormatter()
        monthDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        monthDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        monthDateFormatter.dateFormat = "yyyy-MM"
        
        let dayDateFormatter = DateFormatter()
        dayDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dayDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayDateFormatter.dateFormat = "dd"
        
        let detailsChartForDate: (Date, String) -> Chart? = { date, folder -> Chart? in
            if folder == "5" {
                guard let mainChartURL = Bundle.main.url(forResource: "Data/\(folder)/overview", withExtension: "json"),
                    let codableChart = try? decodedChart(at: mainChartURL),
                    let chart = Chart(chart: codableChart) else {
                        return nil
                }
                    
                guard let index = chart.legend.values.firstIndex(where: { $0 == date }) else {
                    return nil
                }
                
                let lowerBound = max(0, index - 3)
                let upperBound = min(chart.legend.values.count - 1, index + 3)
                guard lowerBound <= upperBound else {
                    return nil
                }
                
                let range = lowerBound...upperBound
                let legendValues = chart.legend.values[range]
                let legend = Legend(values: Array(legendValues))
                let columns: [Column] = chart.columns.map {
                    let values = Array($0.values[range])
                    return Column(name: $0.name, style: $0.style, colorHex: $0.colorHex, values: values)
                }
                return Chart(
                    legend: legend,
                    columns: columns,
                    isPercentage: chart.isPercentage,
                    isStacked: chart.isStacked,
                    isYScaled: chart.isYScaled
                )
            }
            
            let monthFolder = monthDateFormatter.string(from: date)
            let file = dayDateFormatter.string(from: date)
            
            guard let chartURL = Bundle.main.url(forResource: "Data/\(folder)/\(monthFolder)/\(file)", withExtension: "json"),
                let codableChart = try? decodedChart(at: chartURL),
                let chart = Chart(chart: codableChart) else {
                return nil
            }
            
            return chart
        }
        
        var chartInfoCollection: [ChartInfo] = []
        folders.forEach { folder in
            guard let mainChartURL = Bundle.main.url(forResource: "Data/\(folder)/overview", withExtension: "json"),
                let codableChart = try? decodedChart(at: mainChartURL),
                let chart = Chart(chart: codableChart) else {
                return
            }
            
            chartInfoCollection.append(ChartInfo(mainChart: chart, detailsChartForDate: { date -> Chart? in
                return detailsChartForDate(date, folder)
            }))
        }

        return chartInfoCollection
    }
    
    private static func decodedChart(at url: URL) throws -> CodableChart {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(CodableChart.self, from: data)
    }
    
}

private extension Chart {
    
    init?(chart: CodableChart) {
        guard let legendId = chart.types.first(where: { $0.value == "x" })?.key,
            let legendColumn = chart.columns.first(where: { $0.id == legendId }) else {
            return nil
        }
        
        legend = Legend(values: legendColumn.values.compactMap { Date(timeIntervalSince1970: Double($0) / 1000) })
        
        
        let lineIds = chart.types.filter({ $0.value != "x" }).map({ $0.key }).sorted()
        columns = lineIds.compactMap({ identifier -> Column? in
            guard let name = chart.names[identifier],
                let styleName = chart.types[identifier],
                let colorHex = chart.colors[identifier],
                let values = chart.columns.first(where: { $0.id == identifier })?.values else {
                    return nil
            }
            guard let style = Column.Style(rawValue: styleName) else {
                return nil
            }
            
            return Column(name: name, style: style, colorHex: colorHex, values: values)
        })
        
        isPercentage = chart.percentage ?? false
        isStacked = chart.stacked ?? false
        isYScaled = chart.y_scaled ?? false
    }

}

private struct CodableChart: Decodable {
    
    let columns: [CodableColumn]
    let types: [String: String]
    let names: [String: String]
    let colors: [String: String]
    let y_scaled: Bool?
    let stacked: Bool?
    let percentage: Bool?

}

private struct CodableColumn: Decodable {

    let id: String
    let values: [Int64]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.id = try container.decode(String.self)
        var values: [Int64] = []
        while !container.isAtEnd {
            values.append(try container.decode(Int64.self))
        }
        self.values = values
    }

}
