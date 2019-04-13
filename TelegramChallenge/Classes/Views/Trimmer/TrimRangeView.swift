//
//  Created by Timur Bernikovich on 3/12/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

extension TrimRangeView {

    static let verticalInset: CGFloat = 1
    static let horizontalInset: CGFloat = 11
    static let highlightLineWidth: CGFloat = 1
    
}

final class TrimRangeView: BaseView {
    
    private let externalBorderLayer = CALayer()
    private let contentView = UIView()
    
    private let leadingArrow = UIImageView(image: UIImage(named: "trimmerArrowLeft"))
    private let trailingArrow = UIImageView(image: UIImage(named: "trimmerArrowRight"))
    
    private let leadingHighlightLine = UIView()
    private let trailingHighlightLine = UIView()
    
    override func setup() {
        super.setup()
        
        layer.insertSublayer(externalBorderLayer, at: 0)
        layer.masksToBounds = false
        
        contentView.layer.cornerRadius = 6
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        contentView.addSubview(leadingArrow)
        contentView.addSubview(trailingArrow)
        
        addSubview(leadingHighlightLine)
        addSubview(trailingHighlightLine)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.performWithoutAnimation {
            let borderWidth: CGFloat = 1
            externalBorderLayer.borderWidth = borderWidth
            externalBorderLayer.cornerRadius = contentView.layer.cornerRadius + borderWidth
            externalBorderLayer.frame = CGRect(
                x: -borderWidth,
                y: -borderWidth,
                width: bounds.width + 2 * borderWidth,
                height: bounds.height + 2 * borderWidth
            )
        }
        
        let maskFrame = bounds.insetBy(
            dx: TrimRangeView.horizontalInset,
            dy: TrimRangeView.verticalInset
        )
        contentView.mask(withRect: maskFrame, inverse: true)

        leadingArrow.center = CGPoint(x: TrimRangeView.horizontalInset / 2, y: contentView.bounds.midY)
        trailingArrow.center = CGPoint(x: contentView.bounds.width - TrimRangeView.horizontalInset / 2, y: contentView.bounds.midY)
        
        leadingHighlightLine.frame = CGRect(
            x: maskFrame.minX,
            y: maskFrame.minY,
            width: TrimRangeView.highlightLineWidth,
            height: maskFrame.height
        )
        trailingHighlightLine.frame = CGRect(
            x: maskFrame.maxX - TrimRangeView.highlightLineWidth,
            y: maskFrame.minY,
            width: TrimRangeView.highlightLineWidth,
            height: maskFrame.height
        )
    }

}

extension TrimRangeView: AppearanceSupport {
    func apply(theme: Theme) {
        contentView.backgroundColor = theme.chartTrimmer
        
        // According to provided design.
        let highlight = (theme is DayTheme) ? UIColor.white : UIColor.clear
        CATransaction.performWithoutAnimation {
            externalBorderLayer.borderColor = highlight.cgColor
        }
        
        leadingHighlightLine.backgroundColor = highlight
        trailingHighlightLine.backgroundColor = highlight
    }
}
