//
//  NCTimeIntervalFormatter.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

class NCTimeIntervalFormatter: Formatter {
	enum Precision: Int {
		case Seconds
		case Minutes
		case Hours
		case Days
	};
	
	var precision: Precision = .Seconds

	class func localizedString(from timeInterval: TimeInterval, precision: Precision) -> String {
		let t = UInt(timeInterval)
		let d = t / (60 * 60 * 24);
		let h = (t / (60 * 60)) % 24;
		let m = (t / 60) % 60;
		let s = t % 60;
		
		var string = ""
		var empty = true

		if (precision.rawValue <= Precision.Days.rawValue && d > 0) {
			string += "\(d)d"
			empty = false
		}
		if (precision.rawValue <= Precision.Hours.rawValue && h > 0) {
			string += "\(empty ? "" : " ")\(h)h"
			empty = false
		}
		if (precision.rawValue <= Precision.Minutes.rawValue && m > 0) {
			string += "\(empty ? "" : " ")\(m)m"
			empty = false
		}
		if (precision.rawValue <= Precision.Seconds.rawValue && s > 0) {
			string += "\(empty ? "" : " ")\(s)s"
			empty = false
		}

		return string;
	}
	
	override func string(for obj: Any?) -> String? {
		guard let obj = obj as? TimeInterval else {return nil}
		return NCTimeIntervalFormatter.localizedString(from: obj, precision: precision)
	}
	
}
