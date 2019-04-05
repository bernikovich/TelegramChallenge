//
//  WeakArray.swift
//  TeleGraph
//
//  Created by Timur Bernikovich on 3/12/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import Foundation

struct WeakArray<T: AnyObject> {

    var values: [T] {
        return array.compactMap { $0.value }
    }

    mutating func add(object: T) {
        array.append(WeakRef(object))
    }

    mutating func compact() {
        array.removeAll(where: { $0.value == nil })
    }

    func contains(object: T) -> Bool {
        return array.contains(where: { $0.value === object })
    }

    private var array = [WeakRef<T>]()

}

private class WeakRef<T: AnyObject> {

    private(set) weak var value: T?

    init(_ value: T?) {
        self.value = value
    }

}
