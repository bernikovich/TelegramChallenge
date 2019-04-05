//
//  Created by Tsimur Bernikovich on 4/5/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

public final class GradientView: UIView {
    public var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    public override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
}

extension CAGradientLayer {
    var uiColors: [UIColor] {
        set {
            colors = newValue.map { $0.cgColor }
        }
        get {
            return (colors ?? []).compactMap { UIColor(cgColor:($0 as! CGColor)) }
        }
    }
}
