//
//  Created by Timur Bernikovich on 13/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class ValueBoxViewPositionHandler {
    
    static func updatePosition(
        of view: ValueBoxView,
        in parent: UIView,
        isPresenting: Bool,
        touchX: CGFloat,
        linePercent: CGFloat) {
        
        let spacing: CGFloat = 12
        let allowedRange = (parent.bounds.minX + spacing + (view.frame.width / 2))...(parent.bounds.maxX - spacing - (view.frame.width / 2))
        let leadingPosition = touchX - (view.frame.width / 2 + spacing)
        let trailingPosition = touchX + (view.frame.width / 2 + spacing)
        let leadingPositionPossible = allowedRange.contains(leadingPosition)
        let trailingPositionPossible = allowedRange.contains(trailingPosition)
        
        let viewMaxY = view.frame.height
        
        let centerX: CGFloat
        let lineMinY = parent.frame.height * (1 - linePercent)
        if viewMaxY + 1 < lineMinY {
            centerX = allowedRange.clamp(touchX)
        } else {
            if !leadingPositionPossible && !trailingPositionPossible {
                centerX = trailingPosition
            } else if !leadingPositionPossible {
                centerX = trailingPosition
            } else if !trailingPositionPossible {
                centerX = leadingPosition
            } else {
                if isPresenting {
                    centerX = trailingPosition
                } else {
                    // Nearest.
                    let currentCenterX = view.frame.midX
                    if abs(currentCenterX - leadingPosition) < abs(currentCenterX - trailingPosition) {
                        centerX = leadingPosition
                    } else {
                        centerX = trailingPosition
                    }
                }
            }
        }
        
        // Do not animate when position changed by pan.
        let isMovedFarAway = abs(centerX - view.center.x) > 10
        let shouldAnimate = !isPresenting && isMovedFarAway
        
        UIView.animate(withDuration: shouldAnimate ? SharedConstants.animationDuration : 0) {
            view.center = CGPoint(x: centerX, y: view.frame.height / 2)
        }
    }

}
