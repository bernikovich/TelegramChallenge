//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

protocol Theme {
    var statusBarStyle: UIStatusBarStyle { get }
    var main: UIColor { get }
    var accent: UIColor { get }
    var text: UIColor { get }
    var background: UIColor { get }
    var separator: UIColor { get }
    
    // Chart
    var chartLine: UIColor { get }
    var chartOriginLine: UIColor { get }
    var chartLineText: UIColor { get }
    var chartBoxText: UIColor { get }

    var chartTrimmer: UIColor { get }
    var chartTrimmerFade: UIColor { get }
}

struct DayTheme: Theme {
    let statusBarStyle: UIStatusBarStyle = .default
    let main = UIColor(hex: 0xFEFEFE)
    let accent = UIColor(hex: 0x027EE5)
    let text = UIColor(hex: 0x000000)
    let background = UIColor(hex: 0xEFEFF4)
    let separator = UIColor(hex: 0xCCCCD1)
    
    let chartLine = UIColor(hex: 0xF3F3F3)
    let chartOriginLine = UIColor(hex: 0xE1E2E3)
    let chartLineText = UIColor(hex: 0x989EA3)
    let chartBoxText = UIColor(hex: 0x69696E)

    let chartTrimmer = UIColor(hex: 0xC9D3DC).withAlphaComponent(0.92)
    let chartTrimmerFade = UIColor(hex: 0xEAF0F6).withAlphaComponent(0.8)
}

struct NightTheme: Theme {
    let statusBarStyle: UIStatusBarStyle = .lightContent
    let main = UIColor(hex: 0x213040)
    let accent = UIColor(hex: 0x1891FF)
    let text = UIColor(hex: 0xFEFEFE)
    let background = UIColor(hex: 0x18222D)
    let separator = UIColor(hex: 0x121A23)
    
    let chartLine = UIColor(hex: 0x1B2734)
    let chartOriginLine = UIColor(hex: 0x131B23)
    let chartLineText = UIColor(hex: 0x5D6D7E)
    let chartBoxText = UIColor(hex: 0xFEFEFE)

    let chartTrimmer = UIColor(hex: 0x3B4A5A).withAlphaComponent(0.92)
    let chartTrimmerFade = UIColor(hex: 0x172332).withAlphaComponent(0.8)
}
