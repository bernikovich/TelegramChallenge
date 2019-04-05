//
//  TrimRangeView.swift
//  TeleGraph
//
//  Created by Timur Bernikovich on 3/12/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

extension TrimRangeView {

    static let verticalInset: CGFloat = 2
    static let borderWidth: CGFloat = 1
    static let horizontalInset: CGFloat = 10

}

final class TrimRangeView: BaseView {
    
    override func setup() {
        super.setup()
        
        clipsToBounds = true
        layer.cornerRadius = 3
        
        addSubview(leftArrow)
        addSubview(rightArrow)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maskFrame = bounds.insetBy(
            dx: TrimRangeView.horizontalInset,
            dy: TrimRangeView.borderWidth
        )
        mask(withRect: maskFrame, inverse: true)

        leftArrow.center = CGPoint(x: TrimRangeView.horizontalInset / 2, y: center.y)
        rightArrow.center = CGPoint(x: frame.width - TrimRangeView.horizontalInset / 2, y: center.y)
    }

    private let leftArrow = UIImageView(image: UIImage(named: "trimmerArrowLeft"))
    private let rightArrow = UIImageView(image: UIImage(named: "trimmerArrowRight"))
}

extension TrimRangeView: AppearanceSupport {
    func apply(theme: Theme) {
        backgroundColor = theme.chartTrimmer
    }
}
