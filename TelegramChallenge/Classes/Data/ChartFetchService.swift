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
        guard let chartsURL = chartsResourceURL() else {
            return []
        }
        
        let data = try Data(contentsOf: chartsURL)
        let decoder = JSONDecoder()
        return try decoder.decode([CodableChart].self, from: data)
    }
    
    private static func chartsResourceURL() -> URL? {
        return Bundle.main.url(forResource: "chart_data", withExtension: "json")
    }
    
}

private extension Chart {
    
    init?(chart: CodableChart) {
        guard let legendId = chart.types.first(where: { $0.value == "x" })?.key,
            let legendColumn = chart.columns.first(where: { $0.id == legendId }) else {
            return nil
        }
        
        legend = Legend(values: legendColumn.values.compactMap { Date(timeIntervalSince1970: Double($0) / 1000) })
        
        let lineIds = chart.types.filter({ $0.value == "line" }).map({ $0.key })
        lines = lineIds.compactMap({ identifier -> Line? in
            guard let name = chart.names[identifier],
                let colorHex = chart.colors[identifier],
                let values = chart.columns.first(where: { $0.id == identifier })?.values else {
                    return nil
            }
            return Line(name: name, colorHex: colorHex, values: values)
        }).sorted(by: { $0.name < $1.name })
    }

}

private struct CodableChart: Decodable {
    
    let columns: [CodableColumn]
    let types: [String: String]
    let names: [String: String]
    let colors: [String: String]

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
