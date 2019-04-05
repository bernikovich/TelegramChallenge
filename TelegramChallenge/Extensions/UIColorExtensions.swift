//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 0xFF
        let green = CGFloat((hex & 0x00FF00) >> 8) / 0xFF
        let blue = CGFloat((hex & 0x0000FF) >> 0) / 0xFF
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    convenience init(argbHex: UInt32) {
        let alpha = CGFloat((argbHex & 0xFF000000) >> 24) / 0xFF
        let red = CGFloat((argbHex & 0x00FF0000) >> 16) / 0xFF
        let green = CGFloat((argbHex & 0x0000FF00) >> 8) / 0xFF
        let blue = CGFloat((argbHex & 0x000000FF) >> 0) / 0xFF
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    convenience init(hexString: String) {
        let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        scanner.scanLocation = hexString.hasPrefix("#") ? 1 : 0
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        self.init(hex: color)
    }
    
}
