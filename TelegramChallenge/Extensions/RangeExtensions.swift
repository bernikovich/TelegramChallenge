//
//  RangeExtensions.swift
//  TeleGraph
//
//  Created by Timur Bernikovich on 3/13/19.
//  Copyright © 2019 Timur Bernikovich. All rights reserved.
//

import Foundation

extension ClosedRange {
    func clamp(_ value: Bound) -> Bound {
        return Swift.min(upperBound, Swift.max(lowerBound, value))
    }
}

extension ClosedRange where Bound: SignedNumeric {
    func round(_ value: Bound, threshold: Bound) -> Bound {
        if abs(value - lowerBound) < threshold {
            return lowerBound
        } else if abs(value - upperBound) < threshold {
            return upperBound
        } else {
            return value
        }
    }
}
