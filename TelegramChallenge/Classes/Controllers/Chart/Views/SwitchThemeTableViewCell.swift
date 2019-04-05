//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class SwitchThemeTableViewCell: BaseTableViewCell, Identifiable {

    override func setup() {
        super.setup()
        contentView.addSubview(switchLabel)
        switchLabel.frame = contentView.bounds
        switchLabel.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        switchLabel.textColor = tintColor
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)

        if theme is NightTheme {
            switchLabel.text = "Switch to Day Mode"
        } else if theme is DayTheme {
            switchLabel.text = "Switch to Night Mode"
        }
    }

    private let switchLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

}
