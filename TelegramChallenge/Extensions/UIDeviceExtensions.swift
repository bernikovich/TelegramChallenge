//
//  UIDeviceExtensions.swift
//  TelegramChallenge
//
//  Created by Timur Bernikovich on 07/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

extension UIDevice {
    
    static var isOld: Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        if identifier.contains("iPhone") {
            let majorName = identifier.components(separatedBy: ",").first ?? ""
            let indexString = majorName.replacingOccurrences(of: "iPhone", with: "")
            let oldPhoneIndex = 7 // iPhone 6/6+.
            if let index = Int(indexString), index <= oldPhoneIndex {
                return true
            }
        }
        
        return false
    }
    
}
