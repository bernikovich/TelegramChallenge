//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

class BaseTableViewController: BaseViewController {
    
    let tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        tableView.backgroundColor = theme.background
        tableView.separatorColor = theme.separator
    }

}
