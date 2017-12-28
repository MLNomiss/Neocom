//
//  NCFittingTargetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import Dgmpp

class NCFittingTargetsViewController: NCTreeViewController {

	var modules: [DGMModule]?
	var completionHandler: ((NCFittingTargetsViewController, DGMShip?) -> Void)!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCFleetMemberTableViewCell.default])
	}
	
	@IBAction func clearTarget(_ sender: Any) {
		completionHandler(self, nil)
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		defer {completionHandler()}
		guard let module = modules?.first else {return}
		guard let ship = module.parent as? DGMShip else {return}
		guard let character = ship.parent as? DGMCharacter else {return}
		guard let gang = character.parent as? DGMGang else {return}
		
		let targets = gang.pilots.flatMap {return $0 == character ? nil : $0}
		let currentTarget = module.target?.parent as? DGMCharacter
		var rows: [TreeNode] = targets.map {NCFleetMemberRow(pilot: $0)}
		
		let i = currentTarget != nil ? targets.index(of: currentTarget!) : nil
		
		let root = TreeNode()
		root.children = rows
		self.treeController?.content = root
		if let i = i {
			let row = rows[i]
			self.treeController?.selectCell(for: row, animated: false, scrollPosition: .bottom)
		}
	}
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if let node = node as? NCFleetMemberRow {
			completionHandler(self, node.pilot.ship)
		}
	}
}
