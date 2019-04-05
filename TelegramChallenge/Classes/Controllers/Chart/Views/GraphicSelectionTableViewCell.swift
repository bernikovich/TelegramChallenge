//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class GraphicSelectionTableViewCell: BaseTableViewCell, Identifiable {

    override func setup() {
        super.setup()
        contentView.addSubview(assetView)
        contentView.addSubview(titleLabel)
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        titleLabel.textColor = theme.text
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let parentFrame = contentView.frame
        let spacing: CGFloat = 16
        let assetSize: CGFloat = 12
        assetView.frame = CGRect(
            x: spacing,
            y: parentFrame.midY - assetSize / 2,
            width: assetSize,
            height: assetSize
        )

        titleLabel.frame = CGRect(
            x: assetView.frame.maxX + spacing,
            y: 0,
            width: parentFrame.width - assetView.frame.maxX - 2 - spacing * 2,
            height: parentFrame.height
        )
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        let color = assetView.backgroundColor
        super.setSelected(selected, animated: animated)
        
        if selected {
            assetView.backgroundColor = color
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let color = assetView.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            assetView.backgroundColor = color
        }
    }

    func setupWith(title: String, color: UIColor, selected: Bool) {
        accessoryType = selected ? .checkmark : .none
        titleLabel.text = title
        assetView.backgroundColor = color
    }

    private let assetView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        return view
    }()

    private let titleLabel = UILabel()
    
}
