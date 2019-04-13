//
//  Created by Timur Bernikovich on 13/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class PercentChartTableViewCell: ChartTableViewCell, Identifiable {
    
    override class var chartType: ChartType { return .percent }
    
}
