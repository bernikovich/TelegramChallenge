//
//  Created by Timur Bernikovich on 3/17/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import UIKit

final class ReusablePool<T> {

    private let creationClosure: () -> T
    private var availablePool: [T] = []
    
    init(creationClosure: @escaping () -> T, initialSize: Int = 5) {
        self.creationClosure = creationClosure
        for _ in 0..<initialSize {
            enqueue(creationClosure())
        }
    }

    func dequeue() -> T {
        guard !availablePool.isEmpty else {
            return creationClosure()
        }

        return availablePool.removeLast()
    }

    func enqueue(_ element: T) {
        availablePool.append(element)
    }

}
