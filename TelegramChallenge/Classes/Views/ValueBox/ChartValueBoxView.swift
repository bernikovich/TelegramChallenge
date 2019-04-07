//
//  Created by Timur Bernikovich on 3/20/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class ChartValueBoxView: BaseView {

    var lastDate: Date?
    
    override func setup() {
        super.setup()

        subscribeToAppearanceUpdates()

        titleLabel.numberOfLines = 0
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right

        addSubview(backgroundView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        backgroundView.layer.cornerRadius = 5
        backgroundView.clipsToBounds = true
    }

    func update(date: Date, lines: [Line], index: Int) {
        lastDate = date
        
        let dayMonth = ChartValueBoxView.dayMonthFormatter.string(from: date)
        let year = ChartValueBoxView.yearFormatter.string(from: date)
        let dateString = NSMutableAttributedString()
        let dayMonthString = NSAttributedString(string: dayMonth, attributes: [.font: UIFont.boldSystemFont(ofSize: 12)])
        let yearString = NSAttributedString(string: year, attributes: [.font: UIFont.systemFont(ofSize: 12)])
        dateString.append(dayMonthString)
        dateString.append(NSAttributedString(string: "\n"))
        dateString.append(yearString)

        let valuesString = NSMutableAttributedString()
        for line in lines {
            if !valuesString.string.isEmpty {
                valuesString.append(NSAttributedString(string: "\n"))
            }
            let value = line.values[index].abbreviated
            let string = NSAttributedString(string: value, attributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor(hexString: line.colorHex)])
            valuesString.append(string)
        }

        titleLabel.attributedText = dateString
        titleLabel.frame.size = dateString.size().ceiled()
        valueLabel.attributedText = valuesString
        valueLabel.frame.size = valuesString.size().ceiled()

        let horizontalInset: CGFloat = 6
        let verticalInset: CGFloat = 4

        bounds = CGRect(
            x: 0,
            y: 0,
            width: titleLabel.frame.width + 4 * horizontalInset + valueLabel.frame.width,
            height: max(titleLabel.frame.height, valueLabel.frame.height) + 2 * verticalInset
        )
        backgroundView.frame = bounds

        titleLabel.frame.origin = CGPoint(x: horizontalInset, y: verticalInset)
        valueLabel.frame.origin = CGPoint(x: bounds.width - valueLabel.frame.width - horizontalInset, y: verticalInset)
    }

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let backgroundView = UIView()
}

private extension CGSize {
    func ceiled() -> CGSize {
        return CGSize(width: ceil(width), height: ceil(height))
    }
}

extension ChartValueBoxView: AppearanceSupport {
    func apply(theme: Theme) {
        titleLabel.textColor = Appearance.theme.chartBoxText
        backgroundView.backgroundColor = theme.background
    }
}

private extension ChartValueBoxView {
    static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
