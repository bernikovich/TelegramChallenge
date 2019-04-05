//
//  HeaderView.swift
//  TeleGraph
//
//  Created by Timur Bernikovich on 3/21/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class HeaderView: UITableViewHeaderFooterView, Identifiable {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        subscribeToAppearanceUpdates()
        textLabel?.font = UIFont.systemFont(ofSize: 14)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(title: String) {
        textLabel?.text = title
    }

}

extension HeaderView: AppearanceSupport {
    func apply(theme: Theme) {
        textLabel?.textColor = theme.chartLineText
    }
}
