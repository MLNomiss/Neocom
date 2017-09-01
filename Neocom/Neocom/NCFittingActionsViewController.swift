//
//  NCFittingActionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData
import EVEAPI

/*class NCFittingTypeRow: TreeRow {
	let type: NCDBInvType
	
	init(type: NCDBInvType, segue: String? = nil, accessoryButtonSegue: String? = nil) {
		self.type = type
		super.init(cellIdentifier: "NCDefaultTableViewCell", segue: segue, accessoryButtonSegue: accessoryButtonSegue)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.object = type
		cell.titleLabel?.text = type.typeName
		cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.accessoryType = .detailButton
	}
	
	override var hashValue: Int {
		return type.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingTypeRow)?.hashValue == hashValue
	}
	
	override func changed(from: TreeNode) -> Bool {
		return false
	}
}*/

class NCFittingDamagePatternRow: TreeRow {
	let damagePattern: NCFittingDamage
	
	init(prototype: Prototype = Prototype.NCDamageTypeTableViewCell.compact, damagePattern: NCFittingDamage, route: Route? = nil) {
		self.damagePattern = damagePattern
		super.init(prototype: prototype, route: route)
		
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDamageTypeTableViewCell else {return}
		
		func fill(label: NCDamageTypeLabel, value: Double) {
			label.progress = Float(value)
			label.text = "\(Int(round(value * 100)))%"
		}
		
		fill(label: cell.emLabel, value: damagePattern.em)
		fill(label: cell.kineticLabel, value: damagePattern.kinetic)
		fill(label: cell.thermalLabel, value: damagePattern.thermal)
		fill(label: cell.explosiveLabel, value: damagePattern.explosive)
	}
	
	override var hashValue: Int {
		return damagePattern.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingDamagePatternRow)?.hashValue == hashValue
	}
	
}

class NCFittingAreaEffectRow: NCTypeInfoRow {
	
}

class NCLoadoutNameRow: NCTextFieldRow {
	
	override var hashValue: Int {
		return 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCLoadoutNameRow)?.hashValue == hashValue
	}
}

class NCFittingActionsViewController: UITableViewController, TreeControllerDelegate, UITextFieldDelegate {
	@IBOutlet var treeController: TreeController!
	var fleet: NCFittingFleet?
	
	private var observer: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDamageTypeTableViewCell.compact,
		                    Prototype.NCActionTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCFittingCharacterTableViewCell.default,
							Prototype.NCFittingBoosterTableViewCell.default
		                    ])
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		reload()
		
		if traitCollection.userInterfaceIdiom == .phone {
			tableView.layoutIfNeeded()
			var size = tableView.contentSize
			size.height += tableView.contentInset.top
			size.height += tableView.contentInset.bottom
			navigationController?.preferredContentSize = size
		}
		
		if let pilot = fleet?.active, observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingEngineDidUpdate, object: pilot.engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
		
	}
	
	@IBAction func onDelete(_ sender: Any) {
		guard let fleet = fleet else {return}
		guard let pilot = fleet.active else {return}
		pilot.engine?.perform {
			fleet.remove(pilot: pilot)
		}
		dismiss(animated: true, completion: nil)
	}

	@IBAction func onShare(_ sender: UIBarButtonItem) {
		performShare(sender: sender)
	}
	
	@IBAction func onSkills(_ sender: Any) {
		guard let ship = fleet?.engine.sync(execute: {self.fleet?.active?.ship}) else {return}
		Router.Fitting.RequiredSkills(for: ship).perform(source: self, sender: sender)
	}

	@IBAction func onShoppingList(_ sender: Any) {
		guard let fleet = fleet else {return}
		guard let pilot = fleet.active else {return}
		UIApplication.shared.beginIgnoringInteractionEvents()
		pilot.engine?.perform {
			guard let shoppingItem = pilot.shoppingItem else {return}
			DispatchQueue.main.async {
				UIApplication.shared.endIgnoringInteractionEvents()
				Router.ShoppingList.Add(items: [shoppingItem]).perform(source: self, sender: sender)
			}
		}
	}

	@IBAction func onDuplicate(_ sender: Any) {
		guard let fleet = fleet else {return}
		guard let pilot = fleet.active else {return}
		guard let engine = pilot.engine else {return}
		
		engine.perform {
			guard let ship = pilot.ship else {return}
			
			guard let copy = fleet.append(typeID: ship.typeID, engine: engine) else {return}
			if let url = pilot.url {
				copy.setSkills(from: url)
			}
			let copyShip = NCFittingShip(typeID: ship.typeID)
			copy.ship = copyShip
			
			var name = ship.name
			if let r = name.range(of: "Copy", options: [String.CompareOptions.backwards]) {
				if name.endIndex == r.upperBound {
					name += " 1"
				}
				else if let n = Int(name.substring(from: name.index(after: r.upperBound))) {
					name.replaceSubrange(r.upperBound..<name.endIndex, with: " \(n + 1)")
				}
				else {
					name += " " + NSLocalizedString("Copy", comment: "")
				}
			}
			else if name.isEmpty {
				name = NSLocalizedString("Copy", comment: "")
			}
			else {
				name += " " + NSLocalizedString("Copy", comment: "")
			}
			
			copyShip.name = name
			
			ship.modules.forEach {
				guard let module = copyShip.addModule(typeID: $0.typeID, forced: true, socket: $0.socket) else {return}
				if let charge = $0.charge {
					module.charge = NCFittingCharge(typeID: charge.typeID)
				}
				module.state = $0.preferredState
			}
			ship.drones.forEach {
				guard let drone = copyShip.addDrone(typeID: $0.typeID, squadronTag: $0.squadronTag) else {return}
				drone.isActive = $0.isActive
			}
			pilot.implants.all.forEach {
				copy.addImplant(typeID: $0.typeID)
			}
			pilot.boosters.all.forEach {
				copy.addBooster(typeID: $0.typeID)
			}
			fleet.active = copy
		}
	}

	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let item = node as? TreeNodeRoutable else {return}
		guard let route = item.route else {return}
		route.perform(source: self, sender: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let node = node as? TreeRow else {return}
		guard let route = node.accessoryButtonRoute else {return}
		route.perform(source: self, sender: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard node is NCFittingAreaEffectRow else {return nil}
		return [UITableViewRowAction(style: .default, title: NSLocalizedString("Delete", comment: ""), handler: {[weak self] _ in
			guard let engine = self?.fleet?.active?.engine else {return}
			engine.perform {
				engine.area = nil
			}
		})]
	}
	
	//MARK: - UITextFieldDelegate
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		guard let cell = textField.ancestor(of: UITableViewCell.self) else {return}
		guard let indexPath = tableView.indexPath(for: cell) else {return}
		tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
		
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.endEditing(true)
		return true
	}

	@IBAction func onEndEditing(_ sender: UITextField) {
		guard let pilot = fleet?.active else {return}
		let text = sender.text
		pilot.engine?.perform {
			(pilot.ship ?? pilot.structure)?.name = text ?? ""
		}
	}
	
	//MARK: - Private
	
	private func reload() {
		guard let fleet = fleet else {return}
		guard let pilot = fleet.active else {return}
		guard let engine = pilot.engine else {return}
		
		var sections = [TreeNode]()

		let invTypes = NCDatabase.sharedDatabase?.invTypes

		engine.performBlockAndWait {
			let title = (pilot.ship ?? pilot.structure)?.name
			sections.append(NCLoadoutNameRow(text: title?.isEmpty == false ? title : nil, placeholder: NSLocalizedString("Ship Name", comment: "")))
			if let ship = pilot.ship ?? pilot.structure, let type = invTypes?[ship.typeID] {
				let row = NCTypeInfoRow(type: type, accessoryType: .detailButton, route: Router.Database.TypeInfo(ship), accessoryButtonRoute: Router.Database.TypeInfo(ship))
				sections.append(DefaultTreeSection(nodeIdentifier: "Ship", title: NSLocalizedString("Ship", comment: "").uppercased(), children: [row]))
			}
			
			let characterRow: TreeNode
			let characterRoute = Router.Fitting.Characters(pilot: pilot) { (controller, url) in
				controller.dismiss(animated: true) {
					pilot.setSkills(from: url, completionHandler: nil)
				}
			}
			
			if let account = pilot.account {
				characterRow = NCAccountCharacterRow(account: account, route: characterRoute)
			}
			else if let character = pilot.fitCharacter {
				characterRow = NCCustomCharacterRow(character: character, route: characterRoute)
			}
			else {
				characterRow = NCPredefinedCharacterRow(level: pilot.level ?? 0, route: characterRoute)
			}
			
			sections.append(DefaultTreeSection(nodeIdentifier: "Character", title: NSLocalizedString("Character", comment: "").uppercased(), children: [characterRow]))

			let areaEffectsRoute = Router.Fitting.AreaEffects { [weak self] (controller, type) in
				let typeID = type != nil ? Int(type!.typeID) : nil
				controller.dismiss(animated: true) {
					self?.fleet?.active?.engine?.perform {
						self?.fleet?.active?.engine?.area = typeID != nil ? NCFittingArea(typeID: typeID!) : nil
					}
				}
			}
			
			if fleet.pilots.count <= 1 {
				self.navigationItem.rightBarButtonItem = nil
			}
			
			if let area = engine.area, let type = invTypes?[area.typeID] {
				let row = NCFittingAreaEffectRow(type: type, accessoryType: .detailButton, route: areaEffectsRoute, accessoryButtonRoute: Router.Database.TypeInfo(type))
				sections.append(DefaultTreeSection(nodeIdentifier: "Area", title: NSLocalizedString("Area Effects", comment: "").uppercased(), children: [row]))
			}
			else {
				let row = NCActionRow(title: NSLocalizedString("Select Area Effects", comment: "").uppercased(),  route: areaEffectsRoute)
				sections.append(DefaultTreeSection(nodeIdentifier: "Area", title: NSLocalizedString("Area Effects", comment: "").uppercased(), children: [row]))
			}
			
			let damagePatternsRoute = Router.Fitting.DamagePatterns {[weak self] (controller, damagePattern) in
				controller.dismiss(animated: true) {
					self?.fleet?.active?.engine?.perform {
						for (pilot, _) in self?.fleet?.pilots ?? [] {
							pilot.ship?.damagePattern = damagePattern
						}
					}
				}
			}

			let damagePattern = pilot.ship?.damagePattern ?? .omni
			sections.append(DefaultTreeSection(nodeIdentifier: "DamagePattern", title: NSLocalizedString("Damage Pattern", comment: "").uppercased(), children: [NCFittingDamagePatternRow(damagePattern: damagePattern, route: damagePatternsRoute)]))

			
//			let shareAction = NCActionRow(prototype: Prototype.NCActionTableViewCell.default, title: NSLocalizedString("Share", comment: "").uppercased(), route: Router.Custom ({ [weak self] (controller, view) in
//				self?.performShare()
//			}))
//			
//			sections.append(DefaultTreeSection(nodeIdentifier: "Misc", title: NSLocalizedString("Misc", comment: "").uppercased(), children: [shareAction]))
		}
		
		if treeController.content == nil {
			let root = TreeNode()
			root.children = sections
			treeController.content = root
		}
		else {
			treeController.content?.children = sections
		}
	}
	
	private func performShare(sender: UIBarButtonItem) {
		guard let pilot = fleet?.active else {return}
		
		pilot.engine?.perform {
			guard let ship = pilot.ship ?? pilot.structure else {return}
			let typeID = ship.typeID
			let name = ship.name
			let loadout = pilot.loadout
			
			DispatchQueue.main.async { [weak self] in
				guard let strongSelf = self else {return}
				let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
				
				
				func share(representation: NCLoadoutRepresentation) {
					guard let strongSelf = self else {return}
					let controller = UIActivityViewController(activityItems: [NCLoadoutActivityItem(representation: representation)], applicationActivities: nil)
					controller.popoverPresentationController?.barButtonItem = sender
					strongSelf.present(controller, animated: true, completion: nil)

				}
				
				controller.addAction(UIAlertAction(title: NSLocalizedString("EFT", comment: ""), style: .default, handler: { _ in
					share(representation: .eft([(typeID: typeID, data: loadout, name: name)]))
				}))
				
//				controller.addAction(UIAlertAction(title: NSLocalizedString("DNA", comment: ""), style: .default, handler: { _ in
//					share(representation: .dnaURL([(typeID: typeID, data: loadout, name: name)]))
//				}))
				
				controller.addAction(UIAlertAction(title: NSLocalizedString("EVE XML", comment: ""), style: .default, handler: { _ in
					share(representation: .xml([(typeID: typeID, data: loadout, name: name)]))
				}))
				
				controller.addAction(UIAlertAction(title: NSLocalizedString("Link", comment: ""), style: .default, handler: { _ in
					share(representation: .httpURL([(typeID: typeID, data: loadout, name: name)]))
				}))

				controller.addAction(UIAlertAction(title: NSLocalizedString("Copy", comment: ""), style: .default, handler: { _ in
					guard let value = (NCLoadoutRepresentation.eft([(typeID: typeID, data: loadout, name: name)]).value as? [String])?.first else {return}
					UIPasteboard.general.string = value
				}))
				
				if let account = NCAccount.current {
					controller.addAction(UIAlertAction(title: NSLocalizedString("Save In-Game", comment: ""), style: .default, handler: { _ in
						guard let strongSelf = self else {return}
						guard let value = (NCLoadoutRepresentation.inGame([(typeID: typeID, data: loadout, name: name)]).value as? [ESI.Fittings.MutableFitting])?.first else {return}
						let dataManager = NCDataManager(account: account)
						let progress = NCProgressHandler(viewController: strongSelf, totalUnitCount: 1)
						progress.progress.perform {
							dataManager.createFitting(fitting: value) { result in
								switch result {
								case let .failure(error):
									strongSelf.present(UIAlertController(error: error), animated: true, completion: nil)
								default:
									break
								}
								progress.finish()
							}
						}
					}))
					
					controller.addAction(UIAlertAction(title: NSLocalizedString("EVE Mail", comment: ""), style: .default, handler: { _ in
						guard let strongSelf = self else {return}
						guard let url = (NCLoadoutRepresentation.dnaURL([(typeID: typeID, data: loadout, name: name)]).value as? [URL])?.first else {return}
						let name = !name.isEmpty ? name : NCDatabase.sharedDatabase?.invTypes[typeID]?.typeName ?? NSLocalizedString("Unknown", comment: "")

						let font = UIFont.preferredFont(forTextStyle: .body)
						let s = name * [NSLinkAttributeName: url, NSFontAttributeName: font] + " " * [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.white]
						Router.Mail.NewMessage(recipients: nil, subject: nil, body: s).perform(source: strongSelf, sender: sender)
					}))

				}


				controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
				
				strongSelf.present(controller, animated: true, completion: nil)
				controller.popoverPresentationController?.barButtonItem = sender
			}
		}
		

	}
}