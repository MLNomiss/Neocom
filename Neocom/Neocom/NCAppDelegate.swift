//
//  NCAppDelegate.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData
import CloudData
import SafariServices

@UIApplicationMain
class NCAppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:
		[UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		ESI.initialize()
//		EVE.initialize()
		
		application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert], categories: nil))
		application.registerForRemoteNotifications()

		NSPersistentStoreCoordinator.registerStoreClass(CloudStore.self, forStoreType: CloudStoreType)
//		let directory = URL.init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]).appendingPathComponent("com.shimanski.eveuniverse.NCCache")
//		let url = directory.appendingPathComponent("store.sqlite")
//		try? FileManager.default.removeItem(at: url)

		
		setupAppearance()
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		if let context = NCCache.sharedCache?.viewContext, context.hasChanges {
			try? context.save()
		}
		
		let task = application.beginBackgroundTask(expirationHandler: nil)
		
		NCNotificationManager.sharedManager.schedule { _ in
			application.endBackgroundTask(task)
		}
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		NCDataManager().updateMarketPrices()

		DispatchQueue.global(qos: .background).async {
			autoreleasepool {
				let fileManager = FileManager.default
				guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.shimanski.neocom") else {return}
				let flagURL = groupURL.appendingPathComponent(".already_transferred")
				if !fileManager.fileExists(atPath: flagURL.path) {
					let loadoutsURL = groupURL.appendingPathComponent("loadouts.xml")
					guard let data = try? Data(contentsOf: loadoutsURL),
						let loadouts = NCLoadoutRepresentation(value: data) else {return}
					DispatchQueue.main.async {
						guard let topMostController = self.window?.rootViewController?.topMostPresentedViewController else {return}
						if !((topMostController as? UINavigationController)?.viewControllers.first is NCTransferViewController) {
							Router.Utility.Transfer(loadouts: loadouts).perform(source: topMostController, sender: nil)
						}
					}
				}
			}
		}

	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		
		
		
		if OAuth2.handleOpenURL(url, clientID: ESClientID, secretKey: ESSecretKey, completionHandler: { (result) in
			switch result {
			case let .success(token):
				guard let context = NCStorage.sharedStorage?.viewContext else {break}
				
				let account: NCAccount = context.fetch("Account", limit: 1, where: "characterID == %qi", token.characterID) ?? {
					let account = NCAccount(entity: NSEntityDescription.entity(forEntityName: "Account", in: context)!, insertInto: context)
					account.uuid = UUID().uuidString
					return account
				}()
				account.token = token
				
				if context.hasChanges {
					try? context.save()
				}
				let request = NSFetchRequest<NCAccount>(entityName: "Account")
				if let result = try? context.fetch(request), result.count == 1 {
					NCAccount.current = result.first
				}
			case let .failure(error):
				let controller = self.window?.rootViewController?.topMostPresentedViewController
				controller?.present(UIAlertController(error: error), animated: true, completion: nil)
				break
			}
		}) {
			if let controller = self.window?.rootViewController?.topMostPresentedViewController as? SFSafariViewController {
				controller.dismiss(animated: true, completion: nil)
			}

			return true
		}
		else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
			switch components.scheme?.lowercased() {
			case "showinfo"?:
				guard let typeID = Int(components.path), let type = NCDatabase.sharedDatabase?.invTypes[typeID] else {return false}
				var controller = (window?.rootViewController as? UISplitViewController)?.viewControllers.last
				while controller?.presentedViewController != nil {
					controller = controller?.presentedViewController
				}
				guard !(controller is UIAlertController) else {return false}
				guard let databaseTypeInfoViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NCDatabaseTypeInfoViewController") as? NCDatabaseTypeInfoViewController else {return false}
				databaseTypeInfoViewController.type = type
				while let child = (controller as? UINavigationController)?.topViewController as? UINavigationController {
					controller = child
				}
				if let navigationController = controller as? UINavigationController {
					navigationController.pushViewController(databaseTypeInfoViewController, animated: true)
				}
				return true
			default:
				return false
			}
		}
		else {
			return false
		}
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		CloudStore.handleRemoteNotification(userInfo: userInfo)
		completionHandler(.newData)
	}
	
	func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
		let size = UIScreen.main.bounds.size
		return window?.traitCollection.userInterfaceIdiom == .pad || min(size.width, size.height) > 400 ? [.all] : [.portrait]
	}
	
	//MARK: Private

	private func setupAppearance() {
		CSScheme.currentScheme = CSScheme.Dark
		let navigationBar = UINavigationBar.appearance(whenContainedInInstancesOf: [NCNavigationController.self])
		navigationBar.setBackgroundImage(UIImage.image(color: UIColor.background), for: UIBarMetrics.default)
		navigationBar.shadowImage = UIImage.image(color: UIColor.background)
		navigationBar.barTintColor = UIColor.background
		navigationBar.tintColor = UIColor.white
		navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
		navigationBar.barStyle = .black
		navigationBar.isTranslucent = false
		let tableView = NCTableView.appearance()
		tableView.tableBackgroundColor = UIColor.background
		tableView.separatorColor = UIColor.separator
		NCTableViewCell.appearance().backgroundColor = UIColor.cellBackground
		NCHeaderTableViewCell.appearance().backgroundColor = UIColor.background
		NCBackgroundView.appearance().backgroundColor = UIColor.background
		
		let searchBar = UISearchBar.appearance(whenContainedInInstancesOf: [NCTableView.self])
		searchBar.barTintColor = UIColor.background
		searchBar.tintColor = UIColor.white
		searchBar.setSearchFieldBackgroundImage(UIImage.searchFieldBackgroundImage(color: UIColor.separator), for: UIControlState.normal)
//		searchBar.backgroundImage = UIImage.image(color: UIColor.background)
		
		let toolbar = UIToolbar.appearance(whenContainedInInstancesOf: [NCNavigationController.self])
		toolbar.tintColor = UIColor.white
		toolbar.barStyle = .black
		toolbar.barTintColor = UIColor.background
		toolbar.isTranslucent = false
	}

}


extension NCAppDelegate: UISplitViewControllerDelegate {
	
}