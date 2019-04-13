//
//  Created by Timur Bernikovich on 3/20/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class ChartValueBoxHandler {

    let box = BarChartValueBoxView(style: .normal)
    let line = ChartValueBoxLineView()

    func show() {
        box.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        box.alpha = 0
        line.alpha = 0
        UIView.animate(withDuration: SharedConstants.animationDuration) {
            self.box.transform = .identity
            self.box.alpha = 1
            self.line.alpha = 1
        }
    }

    func hide(animated: Bool) {
        UIView.animate(withDuration: animated ? SharedConstants.animationDuration : 0, animations: {
            self.box.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.box.alpha = 0
            self.line.alpha = 0
        }, completion: { _ in
            self.box.removeFromSuperview()
            self.line.removeFromSuperview()
        })
    }

}
