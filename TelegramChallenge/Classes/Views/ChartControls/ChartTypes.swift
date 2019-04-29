//
//  Created by Timur Bernikovich on 15/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

enum ChartType {
    case lines, twoLines, bars, singleBar, percent, pie
    
    var detailsType: ChartType {
        switch self {
        case .singleBar:
            return .lines
        case .percent:
            return .pie
        default:
            return self
        }
    }
}

extension ChartType {
    var supportsColumnVisibilityChanges: Bool {
        switch self {
        case .singleBar, .twoLines:
            return false
        default:
            return true
        }
    }
}

class ChartTransition {

    static func zoomIn(mainView: ChartControlsView, detailsView: ChartControlsView) {
        let duration = SharedConstants.animationDuration / 1.5
        switch (mainView.chartType, detailsView.chartType) {
        case (.percent, .pie):
            let cornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
            cornerRadiusAnimation.duration = duration
            cornerRadiusAnimation.toValue = min(mainView.chartView.frame.width, mainView.chartView.frame.height) / 2
            mainView.chartView.layer.add(cornerRadiusAnimation, forKey: "cornerRadiusAnimation")
            mainView.chartView.layer.masksToBounds = true
            
            let transformAnimation = CABasicAnimation(keyPath: "transform")
            transformAnimation.duration = duration
            var transform = CGAffineTransform(rotationAngle: CGFloat.pi / 6)
            transform = transform.concatenating(CGAffineTransform(scaleX: 1.5, y: 1.5))
            transformAnimation.fromValue = transform.transform3D
            detailsView.chartView.layer.add(transformAnimation, forKey: "transformAnimation")
            
            detailsView.alpha = 0
            UIView.animate(withDuration: duration, animations: {
                detailsView.alpha = 1
            }, completion: { [weak mainView] _ in
                mainView?.chartView.layer.masksToBounds = false
            })
        case (.lines, _),
             (.twoLines, _),
             (.bars, _),
             (.singleBar, _):
            let transformAnimation1 = CABasicAnimation(keyPath: "transform")
            transformAnimation1.duration = duration
            transformAnimation1.toValue = CGAffineTransform(scaleX: 4, y: 1).transform3D
            mainView.chartView.contentView.layer.add(transformAnimation1, forKey: "transformAnimation")
            
            let transformAnimation = CABasicAnimation(keyPath: "transform")
            transformAnimation.duration = duration
            transformAnimation.fromValue = CGAffineTransform(scaleX: 0.25, y: 1).transform3D
            detailsView.chartView.contentView.layer.add(transformAnimation, forKey: "transformAnimation")
            
            detailsView.alpha = 0
            UIView.animate(withDuration: duration, animations: {
                detailsView.alpha = 1
            })
        default:
            detailsView.alpha = 0
            UIView.animate(withDuration: duration) {
                detailsView.alpha = 1
            }
        }
    }
    
    static func zoomOut(mainView: ChartControlsView, detailsView: ChartControlsView) {
        let duration = SharedConstants.animationDuration / 1.5
        switch (mainView.chartType, detailsView.chartType) {
        case (.percent, .pie):
            let cornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
            cornerRadiusAnimation.duration = duration
            cornerRadiusAnimation.fromValue = min(mainView.chartView.frame.width, mainView.chartView.frame.height) / 2
            mainView.chartView.layer.add(cornerRadiusAnimation, forKey: "cornerRadiusAnimation")
            mainView.chartView.layer.masksToBounds = true
            
            let transformAnimation = CABasicAnimation(keyPath: "transform")
            transformAnimation.duration = duration
            var transform = CGAffineTransform(rotationAngle: CGFloat.pi / 6)
            transform = transform.concatenating(CGAffineTransform(scaleX: 1.5, y: 1.5))
            transformAnimation.toValue = transform.transform3D
            detailsView.chartView.contentView.layer.add(transformAnimation, forKey: "transformAnimation")
            
            UIView.animate(withDuration: duration, animations: {
                detailsView.alpha = 0
            }, completion: { [weak mainView] _ in
                detailsView.removeFromSuperview()
                mainView?.chartView.layer.masksToBounds = false
            })
        case (.lines, _),
             (.twoLines, _),
             (.bars, _),
             (.singleBar, _):
            let transformAnimation1 = CABasicAnimation(keyPath: "transform")
            transformAnimation1.duration = duration
            transformAnimation1.fromValue = CGAffineTransform(scaleX: 4, y: 1).transform3D
            mainView.chartView.contentView.layer.add(transformAnimation1, forKey: "transformAnimation")
            
            let transformAnimation = CABasicAnimation(keyPath: "transform")
            transformAnimation.duration = duration
            transformAnimation.toValue = CGAffineTransform(scaleX: 0.25, y: 1).transform3D
            detailsView.chartView.contentView.layer.add(transformAnimation, forKey: "transformAnimation")
            
            UIView.animate(withDuration: duration, animations: {
                detailsView.alpha = 0
            }, completion: { _ in
                detailsView.removeFromSuperview()
            })
        default:
            UIView.animate(withDuration: duration, animations: {
                detailsView.alpha = 0
            }, completion: { _ in
                detailsView.removeFromSuperview()
            })
        }
    }


}
