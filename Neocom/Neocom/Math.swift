//
//  Math.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

extension Int {
	func clamped(to: ClosedRange<Int>) -> Int {
		return Swift.max(to.lowerBound, Swift.min(to.upperBound, self))
	}
}

extension Double {
	func clamped(to: ClosedRange<Double>) -> Double {
		return max(to.lowerBound, min(to.upperBound, self))
	}
}

extension Float {
	func clamped(to: ClosedRange<Float>) -> Float {
		return max(to.lowerBound, min(to.upperBound, self))
	}
}
