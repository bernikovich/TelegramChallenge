//
//  Created by Timur Bernikovich on 3/11/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class BaseTableViewCell: UITableViewCell, AppearanceSupport {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateSelection(selected, animated: animated)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateSelection(highlighted, animated: animated)
    }

    func updateSelection(_ highlighted: Bool, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            if highlighted {
                self.backgroundColor = self.tintColor.withAlphaComponent(0.3)
            } else {
                self.backgroundColor = Appearance.theme.main
            }
        }
    }

    func setup() {
        subscribeToAppearanceUpdates()
    }

    func apply(theme: Theme) {
        contentView.backgroundColor = .clear
        backgroundColor = theme.main
        textLabel?.textColor = theme.text
    }

}
