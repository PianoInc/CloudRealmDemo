//
// Created by 김범수 on 2018. 3. 5..
// Copyright (c) 2018 piano. All rights reserved.
//

import CloudKit

class CloudNotificationCenter: NSObject {

    static let shared = CloudNotificationCenter()


    //Post whenever iCloud User account has changed.
    func postICloudUserChanged() {
        NotificationCenter.default.post(name: NSNotification.Name.RealmConfigHasChanged, object: nil)
    }

}

extension Notification.Name {
    public static let RealmConfigHasChanged: NSNotification.Name = NSNotification.Name(rawValue: "RealmConfigHasChanged")
}
