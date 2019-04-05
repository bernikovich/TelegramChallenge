//
//  Created by Timur Bernikovich on 12/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class PlotItemLayer {
    let text: PlotTextLayer
    let line: PlotLineLayer

    var value: Int64 {
        return text.value
    }

    init(text: PlotTextLayer, line: PlotLineLayer) {
        self.text = text
        self.line = line
    }

    func removeFromSuperlayer() {
        text.removeFromSuperlayer()
        line.removeFromSuperlayer()
    }

    func apply(transform: CATransform3D) {
        text.transform = transform
        line.transform = transform
    }

    func apply(opacity: Float) {
        text.opacity = opacity
        line.opacity = opacity
    }
}

class PlotTextLayer: CALayer, AppearanceSupport {

    let value: Int64
    
    private let textLayer = CATextLayer()
    private let font = UIFont.systemFont(ofSize: 12)

    init(value: Int64) {
        self.value = value

        super.init()

        textLayer.font = CGFont(font.fontName as CFString)
        textLayer.fontSize = font.pointSize
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.string = value.abbreviated
        addSublayer(textLayer)

        updateColors()
    }

    override init(layer: Any) {
        self.value = (layer as? PlotLineLayer)?.value ?? 0
        super.init(layer: layer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSublayers() {
        super.layoutSublayers()

        let fontHeight = ceil(font.ascender - font.descender)
        var size = textLayer.preferredFrameSize()
        size.height = fontHeight
        size.width = ceil(size.width) + fontHeight
        
        textLayer.cornerRadius = size.height / 2
        textLayer.frame = CGRect(x: -textLayer.cornerRadius, y: bounds.height - UIConstants.lineHeight - UIConstants.textInset - size.height,
                                 width: size.width, height: size.height)
    }

    private func updateColors() {
        apply(theme: Appearance.theme)
    }

    func apply(theme: Theme) {
        CATransaction.performWithoutAnimation {
            textLayer.foregroundColor = theme.chartLineText.cgColor
            textLayer.backgroundColor = theme.main.withAlphaComponent(0.75).cgColor
        }
    }
}

class PlotLineLayer: CALayer, AppearanceSupport {
    
    private let lineLayer = CALayer()

    var isOrigin: Bool = false {
        didSet {
            updateColors()
        }
    }

    var value: Int64

    init(value: Int64) {
        self.value = value
        
        super.init()
        
        addSublayer(lineLayer)
        
        updateColors()
    }
    
    override init(layer: Any) {
        self.value = (layer as? PlotLineLayer)?.value ?? 0
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        lineLayer.frame = CGRect(x: 0, y: bounds.height - UIConstants.lineHeight, width: bounds.width, height: UIConstants.lineHeight)
    }
    
    private func updateColors() {
        apply(theme: Appearance.theme)
    }
    
    func apply(theme: Theme) {
        CATransaction.performWithoutAnimation {
            let lineColor = isOrigin ? theme.chartOriginLine : theme.chartLine
            lineLayer.backgroundColor = lineColor.cgColor
            backgroundColor = theme.main.cgColor
        }
    }

}

extension Int64 {
    var abbreviated: String {
        let abbrev = "KMBTPE"
        return abbrev.enumerated().reversed().reduce(nil as String?) { accum, tuple in
            let factor = Double(self) / pow(10, Double(tuple.0 + 1) * 3)
            let format = (factor.truncatingRemainder(dividingBy: 1)  == 0 ? "%.0f%@" : "%.1f%@")
            return accum ?? (factor > 1 ? String(format: format, factor, String(tuple.1)) : nil)
            } ?? String(self)
    }
}

private enum UIConstants {
    
    static let lineHeight: CGFloat = 1
    static let textInset: CGFloat = 2
    
}
