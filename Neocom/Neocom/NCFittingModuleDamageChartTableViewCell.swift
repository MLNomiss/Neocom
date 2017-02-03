//
//  NCFittingModuleDamageChartTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingModuleDamageChartTableViewCell: NCTableViewCell {
	@IBOutlet weak var damageChartView: NCFittingModuleDamageChartView!
	@IBOutlet weak var optimalLabel: UILabel!
	@IBOutlet weak var falloffLabel: UILabel!
	@IBOutlet weak var rawDpsLabel: UILabel!
	@IBOutlet weak var dpsLabel: UILabel!
	@IBOutlet weak var stepper: UIStepper!
}

class NCFittingModuleDamageChartRow: TreeRow {
	let module: NCFittingModule
	let ship: NCFittingShip?
	lazy var hullTypes: [NCDBDgmppHullType]? = {
		let request = NSFetchRequest<NCDBDgmppHullType>(entityName: "DgmppHullType")
		request.sortDescriptors = [NSSortDescriptor(key: "signature", ascending: true), NSSortDescriptor(key: "hullTypeName", ascending: true)]
		return (try? NCDatabase.sharedDatabase!.viewContext.fetch(request))

	}()
	lazy var hullType: NCDBDgmppHullType? = {
		guard let ship = self.ship else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.hullType
	}()
	
	init(module: NCFittingModule) {
		self.module = module
		self.ship = module.owner as? NCFittingShip
		super.init(cellIdentifier: "NCFittingModuleDamageChartTableViewCell")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingModuleDamageChartTableViewCell else {return}
		cell.damageChartView.module = self.module
		cell.stepper.maximumValue = Double(hullTypes?.count ?? 1) - 1
		cell.object = self
		if let hullType = hullType {
			cell.stepper.value = Double(hullTypes?.index(of: hullType) ?? 0)
		}
		cell.dpsLabel.text = NSLocalizedString("DPS AGAINST", comment: "") + " " + (hullType?.hullTypeName?.uppercased() ?? "")
		cell.damageChartView.targetSignature = Double(hullType?.signature ?? 0)
		module.engine?.perform {
			let optimal = self.module.maxRange
			let falloff = self.module.falloff
			let maxRange = optimal + max(falloff * 2, optimal * 0.5)
			let dps = self.module.dps.total
			
			DispatchQueue.main.async {
				cell.rawDpsLabel.text = NSLocalizedString("RAW DPS:", comment: "") + " " + NCUnitFormatter.localizedString(from: dps, unit: .none, style: .full)
				cell.optimalLabel.text = NSLocalizedString("Optimal", comment: "") + "\n" + NCUnitFormatter.localizedString(from: optimal, unit: .meter, style: .full)
				if falloff > 0 {
					cell.falloffLabel.text = NSLocalizedString("Falloff", comment: "") + "\n+" + NCUnitFormatter.localizedString(from: falloff, unit: .meter, style: .full)
				}
				else {
					cell.falloffLabel.isHidden = true
				}
				
				if let constraint = cell.optimalLabel.superview?.constraints.first(where: {$0.firstItem === cell.optimalLabel && $0.secondItem === cell.optimalLabel.superview && $0.firstAttribute == .centerX}) {
					let m = maxRange > 0 ? max(0.01, optimal / maxRange) : 0.01
					constraint.isActive = false
					let other = NSLayoutConstraint(item: cell.optimalLabel, attribute: .centerX, relatedBy: .equal, toItem: cell.optimalLabel.superview, attribute: .trailing, multiplier: CGFloat(m), constant: 0)
					other.priority = constraint.priority
					other.isActive = true
				}
				if let constraint = cell.falloffLabel.superview?.constraints.first(where: {$0.firstItem === cell.falloffLabel && $0.secondItem === cell.falloffLabel.superview && $0.firstAttribute == .centerX}) {
					let m = maxRange > 0 ? max(0.01, (optimal + falloff) / maxRange) : 0.01
					constraint.isActive = false
					let other = NSLayoutConstraint(item: cell.falloffLabel, attribute: .centerX, relatedBy: .equal, toItem: cell.falloffLabel.superview, attribute: .trailing, multiplier: CGFloat(m), constant: 0)
					other.priority = constraint.priority
					other.isActive = true
				}
			}
		}
	}
	
	override var hashValue: Int {
		return module.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleStateRow)?.hashValue == hashValue
	}

}
