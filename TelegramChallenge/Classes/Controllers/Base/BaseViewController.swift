//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController, AppearanceSupport {

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToAppearanceUpdates()
    }

    func apply(theme: Theme) {
        view.backgroundColor = theme.background
    }

}
