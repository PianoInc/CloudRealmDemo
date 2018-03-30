//
//  AppDelegate.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 2..
//  Copyright © 2018 piano. All rights reserved.
//

import UIKit
import RealmSwift
import CloudKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        application.registerForRemoteNotifications()
        _ = CloudManager.shared
        performMigration()
        
        
        
        
        //Remove this chunk if datas need to be persistent
//        let realm = try! Realm()
//        try! realm.write {
//            realm.deleteAll()
//        }
        

        return true
    }

    
    
    func performMigration() {
        let url = Realm.Configuration.defaultConfiguration.fileURL
        let config = Realm.Configuration(
            fileURL: url,
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 26,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }

        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        let _ = try! Realm()
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("oh yeah!!")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }

    //This only happens whenever the change has occured from other environment!!
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("got noti!")
        guard let dict = userInfo as? [String: NSObject],
                application.applicationState != .inactive else {return}
        let notification = CKNotification(fromRemoteNotificationDictionary: dict)

        guard let subscriptionID = notification.subscriptionID else {return}


        if subscriptionID.hasPrefix(CloudManager.shared.privateDatabase.subscriptionID) {
            CloudManager.shared.privateDatabase.handleNotification()
            completionHandler(.newData)
        } else if subscriptionID == CloudManager.shared.sharedDatabase.subscriptionID {
            CloudManager.shared.sharedDatabase.handleNotification()
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }

    }
    
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShareMetadata) {
        let acceptShareOperation: CKAcceptSharesOperation =
            CKAcceptSharesOperation(shareMetadatas:
                [cloudKitShareMetadata])
        
        acceptShareOperation.qualityOfService = .userInteractive
        acceptShareOperation.perShareCompletionBlock = {meta, share,
            error in
            print("share was accepted")
        }
        acceptShareOperation.acceptSharesCompletionBlock = {
            error in
            /// Send your user to where they need to go in your app
        }
        CKContainer(identifier:
            cloudKitShareMetadata.containerIdentifier).add(acceptShareOperation)
    }
    
}


extension Realm {
    static func setDefaultRealmForUser(username: String) {

        let defaultConfig = Realm.Configuration.defaultConfiguration
        var config = Realm.Configuration()
        
        // Use the default directory, but replace the filename with the username
        config.fileURL = config.fileURL!.deletingLastPathComponent()
            .appendingPathComponent("\(username).realm")
        config.schemaVersion = defaultConfig.schemaVersion

        // Set this as the configuration used for the default Realm
        Realm.Configuration.defaultConfiguration = config
    }
}
