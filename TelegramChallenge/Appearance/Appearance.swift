//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class Appearance {

    static var theme: Theme = NightTheme() {
        didSet {
            observers.values.forEach { ($0 as? AppearanceSupport)?.apply(theme: theme) }
        }
    }

    static fileprivate var observers = WeakArray<AnyObject>()

    static func switchTheme() {
        if theme is NightTheme {
            theme = DayTheme()
        } else if theme is DayTheme {
            theme = NightTheme()
        }
    }

}

protocol AppearanceSupport: AnyObject {
    func apply(theme: Theme)
    func subscribeToAppearanceUpdates()
}

extension AppearanceSupport {

    func subscribeToAppearanceUpdates() {
        guard !Appearance.observers.contains(object: self) else {
            return
        }
        apply(theme: Appearance.theme)

        Appearance.observers.add(object: self)
        Appearance.observers.compact()
    }

}

// Move me
enum SharedConstants {
    static let animationDuration: TimeInterval = 0.30
    static let timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .linear)
    
    // According to provided screenshots.
    static let numberOfPlotLines: Double = 5.5
    
    // Can be simplified in cell.
    static let horizontalInset: CGFloat = 16
}
