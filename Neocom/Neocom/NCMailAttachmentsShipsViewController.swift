//
//  NCMailAttachmentsShipsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCAttachmentLoadoutRow: NCLoadoutRow {
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		cell.accessoryType = .detailButton
		accessoryButtonRoute = route
		route = nil
	}
}

class NCMailAttachmentsShipsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if treeController?.content == nil {
			self.treeController?.content = RootNode([NCLoadoutsSection<NCAttachmentLoadoutRow>(categoryID: .ship)])
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let item = node as? NCLoadoutRow else {return}
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		guard let loadout = (try? context.existingObject(with: item.loadoutID)) else {return}
		guard let parent = parent as? NCMailAttachmentsViewController else {return}
		parent.completionHandler?(parent, loadout)
	}
	
}
