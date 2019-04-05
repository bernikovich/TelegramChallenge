//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

extension UIView {
    func mask(withRect rect: CGRect, inverse: Bool = false) {
        let path = UIBezierPath(rect: rect)
        let maskLayer = CAShapeLayer()

        if inverse {
            path.append(UIBezierPath(rect: bounds))
            maskLayer.fillRule = .evenOdd
        }

        maskLayer.path = path.cgPath
        layer.mask = maskLayer
    }
}

extension CGFloat {
    static var pixel: CGFloat {
        return CGFloat(1) / UIScreen.main.scale
    }
}
