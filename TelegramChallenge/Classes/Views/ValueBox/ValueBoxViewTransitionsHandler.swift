//
//  Created by Timur Bernikovich on 12/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class ValueBoxViewTransitionsHandler {
    
    let view: ValueBoxView
    let lineView = ValueBoxLineView()
    
    init(style: ValueBoxView.Style) {
        view = ValueBoxView(style: style)
    }
    
    func show() {
        view.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        view.alpha = 0
        lineView.alpha = 0
        UIView.animate(withDuration: SharedConstants.animationDuration) {
            self.view.transform = .identity
            self.view.alpha = 1
            self.lineView.alpha = 1
        }
    }
    
    func hide(animated: Bool) {
        UIView.animate(withDuration: animated ? SharedConstants.animationDuration : 0, animations: {
            self.view.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.view.alpha = 0
            self.lineView.alpha = 0
        }, completion: { _ in
            self.view.removeFromSuperview()
            self.lineView.removeFromSuperview()
        })
    }
    
}
