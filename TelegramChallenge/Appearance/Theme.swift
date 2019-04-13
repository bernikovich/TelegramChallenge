//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

protocol Theme {
    var statusBarStyle: UIStatusBarStyle { get }
    var main: UIColor { get }
    var accent: UIColor { get }
    var tintColor: UIColor { get }
    var text: UIColor { get }
    var background: UIColor { get }
    var separator: UIColor { get }
    var header: UIColor { get }
    
    // Chart
    var chartPlotLine: UIColor { get }
    var lineChartPlotText: UIColor { get }
    var chartBoxText: UIColor { get }
    
    var barChartPlotXAxisText: UIColor { get }
    var barChartPlotYAxisText: UIColor { get }
    var barChartFade: UIColor { get }

    var chartTrimmer: UIColor { get }
    var chartTrimmerFade: UIColor { get }
}

struct DayTheme: Theme {
    let statusBarStyle: UIStatusBarStyle = .default
    let main = UIColor(hex: 0xFEFEFE)
    let accent = UIColor(hex: 0x027EE5)
    let tintColor = UIColor(hex: 0x108BE3)
    let text = UIColor(hex: 0x000000)
    let background = UIColor(hex: 0xEFEFF4)
    let separator = UIColor(hex: 0xCCCCD1)
    let header = UIColor(hex: 0x8E8E93)
    
    let chartPlotLine = UIColor(hex: 0x182D3B).withAlphaComponent(0.1)
    let lineChartPlotText = UIColor(hex: 0x8E8E93)
    let chartBoxText = UIColor(hex: 0x69696E)
    
    let barChartPlotXAxisText = UIColor(hex: 0x252529).withAlphaComponent(0.5)
    let barChartPlotYAxisText = UIColor(hex: 0x252529).withAlphaComponent(0.5)
    let barChartFade = UIColor(hex: 0xFFFFFF).withAlphaComponent(0.5)

    let chartTrimmer = UIColor(hex: 0xC0D1E1)
    let chartTrimmerFade = UIColor(hex: 0xE2EEF9).withAlphaComponent(0.6)
}

struct NightTheme: Theme {
    let statusBarStyle: UIStatusBarStyle = .lightContent
    let main = UIColor(hex: 0x213040)
    let accent = UIColor(hex: 0x1891FF)
    let tintColor = UIColor(hex: 0x2EA6FE)
    let text = UIColor(hex: 0xFEFEFE)
    let background = UIColor(hex: 0x18222D)
    let separator = UIColor(hex: 0x121A23)
    let header = UIColor(hex: 0x8596AB)
    
    let chartPlotLine = UIColor(hex: 0x8596AB).withAlphaComponent(0.2)
    let lineChartPlotText = UIColor(hex: 0x8596AB)
    let chartBoxText = UIColor(hex: 0xFFFFFF)
    
    let barChartPlotXAxisText = UIColor(hex: 0x8596AB)
    let barChartPlotYAxisText = UIColor(hex: 0xBACCE1).withAlphaComponent(0.6)
    let barChartFade = UIColor(hex: 0x212F3F).withAlphaComponent(0.5)

    let chartTrimmer = UIColor(hex: 0x56626D)
    let chartTrimmerFade = UIColor(hex: 0x18222D).withAlphaComponent(0.6)
}
