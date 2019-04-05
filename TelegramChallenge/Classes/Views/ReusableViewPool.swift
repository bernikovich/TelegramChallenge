//
//  Created by Timur Bernikovich on 3/17/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class ReusableViewPool<T: UIView> {

    init(initialPool: [T] = []) {
        availablePool = initialPool
    }

    func dequeue() -> T {
        guard !availablePool.isEmpty else {
            return T()
        }

        return availablePool.removeLast()
    }

    func enqueue(_ element: T) {
        availablePool.append(element)
    }

    private var availablePool: [T] = []

}
