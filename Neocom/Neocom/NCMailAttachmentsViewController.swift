//
//  NCMailAttachmentsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCMailAttachmentsViewController: NCPageViewController {
	
	var shipsViewController: NCMailAttachmentsShipsViewController?
	
	var completionHandler: ((NCMailAttachmentsViewController, Any) -> Void)?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		shipsViewController = storyboard!.instantiateViewController(withIdentifier: "NCMailAttachmentsShipsViewController") as? NCMailAttachmentsShipsViewController
		
		viewControllers = [shipsViewController!]
	}
}
