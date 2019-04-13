//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class ChartFetchService {

    static func loadCharts(completion: @escaping ([Chart]) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let charts = ChartFetchService.loadCharts()
            DispatchQueue.main.async {
                completion(charts)
            }
        }
    }
    
    private static func loadCharts() -> [Chart] {
        do {
            let charts = try decodedCharts()
            return charts.compactMap(Chart.init)
        } catch {
            return []
        }
    }
    
    private static func decodedCharts() throws -> [CodableChart] {
        let chartsURLs = chartsResourceURLs()
        var charts: [CodableChart] = []
        try chartsURLs.forEach {
            guard let chartURL = $0 else {
                return
            }
            
            let data = try Data(contentsOf: chartURL)
            let decoder = JSONDecoder()
            let chart = try decoder.decode(CodableChart.self, from: data)
            charts.append(chart)
        }
        
        return charts
    }
    
    private static func chartsResourceURLs() -> [URL?] {
        let folders = ["1", "2", "3", "4", "5"]
        let mainJson = "overview"
        return folders.map { Bundle.main.url(forResource: "Data/\($0)/\(mainJson)", withExtension: "json") }
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
