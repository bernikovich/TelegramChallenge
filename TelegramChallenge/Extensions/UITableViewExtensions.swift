//
//  Created by Timur Bernikovich on 11/03/2019.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

protocol Identifiable {

    static var id: String { get }

}

extension Identifiable where Self: NSObject {
    
    static var id: String { return String(describing: self) }

}

extension UITableView {
    
    typealias IdentifiableCell = UITableViewCell & Identifiable
    
    func register(cells: [IdentifiableCell.Type]) {
        cells.forEach { register(cell: $0) }
    }
    
    func register(cell: IdentifiableCell.Type) {
        register(cell, forCellReuseIdentifier: cell.id)
    }
    
    func dequeueReusableCell<T: IdentifiableCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.id, for: indexPath) as? T else {
            fatalError("Could not dequeue reusable cell \(T.id)")
        }
        return cell
    }

}
