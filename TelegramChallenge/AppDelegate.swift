//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = MainWindow(frame: UIScreen.main.bounds)
        window.rootViewController = NavigationViewController(rootViewController: StatisticsViewController())
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }

}

private class MainWindow: UIWindow, AppearanceSupport {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        subscribeToAppearanceUpdates()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        subscribeToAppearanceUpdates()
    }
    
    func apply(theme: Theme) {
        tintColor = theme.tintColor
    }
    
}

class TestViewController: BaseViewController {
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        let item1 = FilterSwitch.Item(color: UIColor(hexString: "#3497ED"), text: "Apples")
//        let item2 = FilterSwitch.Item(color: UIColor(hexString: "#2373DB"), text: "Oranges")
//        let item3 = FilterSwitch.Item(color: UIColor(hexString: "#9ED448"), text: "Lemons")
//        let item4 = FilterSwitch.Item(color: UIColor(hexString: "#5FB641"), text: "Apricots")
//        let item5 = FilterSwitch.Item(color: UIColor(hexString: "#F5BD25"), text: "Kiwi")
//        let item6 = FilterSwitch.Item(color: UIColor(hexString: "#F79E39"), text: "Mango")
//        
////            {"y0":"Apples","y1":"Oranges","y2":"Lemons","y3":"Apricots","y4":"Kiwi","y5":"Mango"}
////        {"y0":"#3497ED","y1":"#2373DB","y2":"#9ED448","y3":"#5FB641","y4":"#F5BD25","y5":"#F79E39"
//        let item = FilterSwitchCollection.Item(switchItems: [item1, item2, item3, item4, item5, item6])
//        
//        let width = view.bounds.width - 2 * 20
//        let height = FilterSwitchCollection.preferredSize(for: item, containerWidth: width)
//        
//        let collectionView = FilterSwitchCollection()
//        collectionView.frame = CGRect(x: 20, y: 200, width: width, height: height)
//        collectionView.setup(with: item)
//        view.addSubview(collectionView)
//    }

}
