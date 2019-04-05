//
//  BaseView.swift
//  TeleGraph
//
//  Created by Timur Bernikovich on 3/12/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class BaseView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {}

}
