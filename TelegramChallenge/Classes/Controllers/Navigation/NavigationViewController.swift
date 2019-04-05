//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class NavigationViewController: UINavigationController, AppearanceSupport {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToAppearanceUpdates()
        navigationBar.isTranslucent = false
    }

    func apply(theme: Theme) {
        setNeedsStatusBarAppearanceUpdate()
        navigationBar.barTintColor = theme.main
        navigationBar.tintColor = theme.text
        navigationBar.titleTextAttributes = [.foregroundColor: theme.text]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Appearance.theme.statusBarStyle
    }

}
