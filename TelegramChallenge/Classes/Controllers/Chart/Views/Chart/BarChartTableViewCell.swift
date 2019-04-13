//
//  Created by Timur Bernikovich on 09/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class BarChartTableViewCell: ChartTableViewCell, Identifiable {
    
    override class var chartType: ChartType { return .bars }
    
}
