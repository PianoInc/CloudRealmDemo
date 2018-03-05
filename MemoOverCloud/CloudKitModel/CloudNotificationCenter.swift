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

    /**
    This notification is needed because realm notification *Cannot* distinguish between
    server change and client change of realm object.

    Normally, this isn't a issue because UI just needs to update latest state of object.
    However, note object changes have to be explicitly distinguished since user can type some text while server has changed.

        - parameters:
            - about: record that have changed it's content or attribute
        - important: the record type must be always Note!!

    */
    func postServerChangeNotification(about record: CKRecord) {
        NotificationCenter.default.post(name: .NoteChangedFromServer, object: record.recordID.recordName)
    }


    //TODO: add notification for diff3 conflict!
}

extension Notification.Name {
    public static let RealmConfigHasChanged: NSNotification.Name = NSNotification.Name(rawValue: "RealmConfigHasChanged")
    public static let NoteChangedFromServer: NSNotification.Name = NSNotification.Name(rawValue: "NoteChangedFromServer")
}
