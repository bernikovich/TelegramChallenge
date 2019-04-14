//
//  Created by Timur Bernikovich on 07/04/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class FilterSwitch: BaseView {
    
    struct Item {
        let color: UIColor
        let text: String
    }
    
    private enum UIConstants {
        static let leadingInset: CGFloat = 9
        static let checkmarkSize: CGFloat = 15
        static let checkmarkTextSpacing: CGFloat = 6
        static let trailingInset: CGFloat = 12
    }
    
    private let innerButton = UIButton(type: .custom)
    
    private let checkmarkLayer = CAShapeLayer.makeCheckmark()
    private let label = UILabel()
    
    private(set) var isSelected: Bool = true
    private var item: Item?
    var onSelect: (() -> ())?
    var onLongTap: (() -> ())?
    
    private static var attributes: [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ]
    }
    
    override func setup() {
        super.setup()
        
        layer.cornerRadius = 6
        layer.borderWidth = 1
        
        innerButton.layer.cornerRadius = 6
        innerButton.layer.masksToBounds = true
        innerButton.addTarget(self, action: #selector(FilterSwitch.didSelectButton(_:)), for: .touchUpInside)
        addSubview(innerButton)
        innerButton.frame = bounds
        innerButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(FilterSwitch.didLongPress(_:)))
        innerButton.addGestureRecognizer(longPressGesture)
        
        label.textAlignment = .center
        addSubview(label)
        
        layer.addSublayer(checkmarkLayer)
        checkmarkLayer.frame = CGRect(
            x: UIConstants.leadingInset,
            y: 8,
            width: UIConstants.checkmarkSize,
            height: UIConstants.checkmarkSize
        )
        
        updateState(animated: false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateState(animated: false)
    }
    
    func setup(with item: Item) {
        self.item = item
        
        layer.borderColor = item.color.cgColor
        label.attributedText = NSAttributedString(string: item.text, attributes: FilterSwitch.attributes)
        label.sizeToFit()
        
        updateState(animated: false)
    }
    
    func updateState(_ isSelected: Bool, animated: Bool) {
        self.isSelected = isSelected
        updateState(animated: animated)
    }
    
    static func preferredSize(for item: Item) -> CGSize {
        let attributedString = NSAttributedString(string: item.text, attributes: FilterSwitch.attributes)
        let rect = attributedString.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil)
        let width = UIConstants.leadingInset + UIConstants.checkmarkSize + UIConstants.checkmarkTextSpacing
            + ceil(rect.width)  + UIConstants.trailingInset
        return CGSize(width: width, height: 30)
    }
    
    @objc func didSelectButton(_ sender: Any?) {
        onSelect?()
    }
    
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            onLongTap?()
        }
    }
    
    private func updateState(animated: Bool) {
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            UIView.animate(withDuration: 0.25) {
                self.updateState()
            }
            CATransaction.commit()
        } else {
            updateState()
        }
    }
    
    private func updateState() {
        var labelFrame = label.frame.integral
        labelFrame.origin.y = (bounds.height - labelFrame.height) / 2
        if isSelected {
            checkmarkLayer.strokeEnd = 1
            innerButton.setBackgroundColor(item?.color, for: .normal)
            innerButton.setBackgroundColor(item?.color.withAlphaComponent(0.8), for: .highlighted)
            label.textColor = .white
            labelFrame.origin.x = checkmarkLayer.frame.maxX + UIConstants.checkmarkTextSpacing
        } else {
            checkmarkLayer.strokeEnd = 0
            innerButton.setBackgroundColor(.clear, for: .normal)
            innerButton.setBackgroundColor(item?.color.withAlphaComponent(0.1), for: .highlighted)
            innerButton.backgroundColor = .clear
            label.textColor = item?.color
            labelFrame.origin.x = (bounds.width - labelFrame.width) / 2
        }
        label.frame = labelFrame
    }

}

private extension CAShapeLayer {
    static func makeCheckmark() -> CAShapeLayer {
        // Relative to 15x15.
        let size = CGSize(width: 15, height: 15)
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 3, y: 8))
        bezierPath.addLine(to: CGPoint(x: 6, y: 11))
        bezierPath.addLine(to: CGPoint(x: 13, y: 3))
        
        let layer = CAShapeLayer()
        layer.frame = CGRect(origin: .zero, size: size)
        
        layer.path = bezierPath.cgPath
        layer.strokeColor = UIColor.white.cgColor
        layer.fillColor = nil
        layer.lineWidth = 2
        layer.lineCap = .round
        layer.lineJoin = .round
        
        return layer
    }
}

private extension UIButton {
    func setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        guard let color = color else {
            setBackgroundImage(nil, for: state)
            return
        }
        
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()?.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setBackgroundImage(colorImage, for: state)
    }
}
