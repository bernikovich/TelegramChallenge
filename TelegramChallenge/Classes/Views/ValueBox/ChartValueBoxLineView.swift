//
//  Created by Timur Bernikovich on 3/20/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class ChartValueBoxLineView: BaseView {

    override func setup() {
        super.setup()
        subscribeToAppearanceUpdates()
        addSubview(line)
        frame.size.width = Constants.bubbleSize
    }

    func setupWithLines(_ lines: [Line], index: Int, range: ClosedRange<Int64>) {
        subviews
            .filter { $0 is BubbleView }
            .forEach { $0.removeFromSuperview() }
        let delta = CGFloat(range.upperBound - range.lowerBound)
        for line in lines {
            let value = CGFloat(line.values[index] - range.lowerBound) / delta
            let y = frame.height * (1 - value)
            let bubble = BubbleView()
            bubble.layer.borderColor = UIColor(hexString: line.colorHex).cgColor
            bubble.center = CGPoint(x: frame.width / 2, y: y)
            addSubview(bubble)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        line.frame = CGRect(x: frame.width / 2 - 0.5, y: 0, width: 1, height: frame.height)
    }

    private let line = UIView()

}

extension ChartValueBoxLineView: AppearanceSupport {
    func apply(theme: Theme) {
        line.backgroundColor = Appearance.theme.chartLine
    }
}

private final class BubbleView: BaseView {

    override func setup() {
        super.setup()
        subscribeToAppearanceUpdates()

        frame.size = CGSize(width: Constants.bubbleSize, height: Constants.bubbleSize)
        layer.borderWidth = 2
        layer.cornerRadius = Constants.bubbleSize / 2
    }

}

extension BubbleView: AppearanceSupport {
    func apply(theme: Theme) {
        backgroundColor = Appearance.theme.main
    }
}

private enum Constants {

    static let bubbleSize: CGFloat = 9

}
