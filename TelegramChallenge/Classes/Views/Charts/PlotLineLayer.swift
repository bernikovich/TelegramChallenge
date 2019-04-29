//
//  Created by Timur Bernikovich on 12/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class PlotLineLayer: CALayer {
    
    var value: Int64 {
        didSet {
            updateText()
        }
    }
    let chartType: ChartType
    
    var textColor: UIColor? {
        didSet {
            updateColors()
        }
    }
    
    let lineLayer = CALayer()
    let textLayer = CATextLayer()
    private let font = UIFont.systemFont(ofSize: 12)
    
    init(value: Int64, chartType: ChartType) {
        self.value = value
        self.chartType = chartType
        
        super.init()
        
        textLayer.font = CGFont(font.fontName as CFString)
        textLayer.fontSize = font.pointSize
        textLayer.alignmentMode = .natural
        textLayer.contentsScale = UIScreen.main.scale
        addSublayer(textLayer)
        
        addSublayer(lineLayer)
        
        updateText()
        updateColors()
    }
    
    private func updateText() {
        textLayer.string = value.abbreviated
    }
    
    override init(layer: Any) {
        self.value = (layer as? PlotLineLayer)?.value ?? 0
        self.chartType = (layer as? PlotLineLayer)?.chartType ?? .lines
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
        size.width = ceil(size.width)
        
        textLayer.frame = CGRect(
            x: 0,
            y: bounds.height - UIConstants.lineHeight - UIConstants.textInset - size.height,
            width: bounds.width,
            height: size.height
        )
        
        lineLayer.frame = CGRect(
            x: 0,
            y: bounds.height - UIConstants.lineHeight,
            width: bounds.width,
            height: UIConstants.lineHeight
        )
    }
    
    private func updateColors() {
        apply(theme: Appearance.theme)
    }
    
    func apply(theme: Theme) {
        CATransaction.performWithoutAnimation {
            if let textColor = textColor {
                textLayer.foregroundColor = textColor.cgColor
            } else {
                switch chartType {
                case .lines, .twoLines:
                    textLayer.foregroundColor = theme.lineChartPlotText.cgColor
                case .bars, .singleBar, .percent, .pie:
                    textLayer.foregroundColor = theme.barChartPlotYAxisText.cgColor
                }
            }
            
            lineLayer.backgroundColor = theme.chartPlotLine.cgColor
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
