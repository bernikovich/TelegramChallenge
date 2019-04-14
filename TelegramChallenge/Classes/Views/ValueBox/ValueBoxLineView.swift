//
//  Created by Timur Bernikovich on 3/20/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class ValueBoxLineView: BaseView {

    private let line = UIView()
    
    override func setup() {
        super.setup()
        subscribeToAppearanceUpdates()
        addSubview(line)
        frame.size.width = Constants.bubbleSize
    }

    func setupWithLines(_ columns: [Column], range: ClosedRange<Int64>, index: Int) {
        let ranges = [ClosedRange<Int64>](repeating: range, count: columns.count)
        setupWithLines(columns, ranges: ranges, index: index)
    }
    
    func setupWithLines(_ columns: [Column], ranges: [ClosedRange<Int64>], index: Int) {
        subviews.filter({ $0 is BubbleView }).forEach { $0.removeFromSuperview() }
        columns.enumerated().forEach { columnIndex, column in
            let range = ranges[columnIndex]
            let delta = CGFloat(range.upperBound - range.lowerBound)
            let value = CGFloat(column.values[index] - range.lowerBound) / delta
            let y = frame.height * (1 - value)
            let bubble = BubbleView()
            bubble.layer.borderColor = UIColor(hexString: column.colorHex).cgColor
            bubble.center = CGPoint(x: frame.width / 2, y: y)
            addSubview(bubble)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        line.frame = CGRect(x: frame.width / 2, y: 0, width: 2, height: frame.height)
    }

}

extension ValueBoxLineView: AppearanceSupport {
    func apply(theme: Theme) {
        line.backgroundColor = Appearance.theme.chartPlotLine
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

    static let bubbleSize: CGFloat = 8

}
