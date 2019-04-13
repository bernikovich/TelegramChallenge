//
//  Created by Timur Bernikovich on 12/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class BarChartValueBoxAppearance {
    
    let view = BarChartValueBoxView(style: .stacked)
    
    func show() {
        view.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        view.alpha = 0
        UIView.animate(withDuration: SharedConstants.animationDuration) {
            self.view.transform = .identity
            self.view.alpha = 1
        }
    }
    
    func hide(animated: Bool) {
        UIView.animate(withDuration: animated ? SharedConstants.animationDuration : 0, animations: {
            self.view.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.view.alpha = 0
        }, completion: { _ in
            self.view.removeFromSuperview()
        })
    }
    
}
