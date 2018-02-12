//
// Created by 김범수 on 2018. 2. 8..
// Copyright (c) 2018 piano. All rights reserved.
//

import CloudKit

class CloudCommonDatabase {
    fileprivate let database: CKDatabase
    public let subscriptionID: String

    init(database: CKDatabase) {
        self.database = database

        self.subscriptionID = "cloudkit-note-changes\(database.scopeString)"
    }

    /*
     * This method creates custom Zone with specific identifier
     * in this class.
     */
    fileprivate func createZoneWithID(zoneID: CKRecordZoneID, completion: @escaping ((Error?) -> Void)) {
        let recordZone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: [])

        operation.modifyRecordZonesCompletionBlock = { (_, _, error) in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }

        operation.qualityOfService = .utility

        database.add(operation)
    }

    /*
     * It will be implemented by subclassing
     */
    fileprivate func createZoneIfNeeded(completion: @escaping ((Error?) -> Void)) {}


    /*
     * Load records by given record names and zoneID
     */
    public func loadRecords(recordNames: [String], in zoneID: CKRecordZoneID, completion: @escaping (([CKRecordID: CKRecord]?, Error?) -> Void)) {

        let recordIDs = recordNames.map { CKRecordID(recordName: $0, zoneID: zoneID) }


        let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
        operation.fetchRecordsCompletionBlock = { records, error in
            guard error == nil else { return completion(nil, error)}

            completion(records, nil)
        }
        operation.qualityOfService = .utility


        database.add(operation)

    }

    /*
     * if parameter ckrecord is not nil, conflict has occured & merged result is the ckrecord
     */
    public func saveRecord(record: CKRecord, completion: @escaping ((CKRecord?, Error?) -> Void)) {
        self.internalSaveRecord(record: record) { error in
            guard error == nil else {
                guard let ckError = error as? CKError else { return completion(nil, error) }

                let (clientRec, serverRec) = ckError.getMergeRecords()
                guard let clientRecord = clientRec,
                        let serverRecord = serverRec,
                        let clientModified = clientRecord.modificationDate,
                        let serverModified = serverRecord.modificationDate else { return completion(nil, error) }

                if clientModified.compare(serverModified) == .orderedDescending {
                    //client win!

                    //TODO: set serverRecord same with client record
                    self.saveRecord(record: serverRecord) { newRecord, error in
                        completion(newRecord, error)
                    }
                } else {
                    //server win!

                    completion(serverRecord, nil)
                }
                return
            }

            completion(nil, nil)
        }
    }

    private func internalSaveRecord(record: CKRecord, completion: @escaping ((Error?) -> Void)) {

        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: [])
        operation.modifyRecordsCompletionBlock = { _, _, error in
            guard error == nil else {
                guard let cloudError = error as? CKError,
                        cloudError.isZoneNotFound() else { return completion(error) }


                //Zone has not created yet, Let's make one
                //And try to save record again

                self.createZoneIfNeeded() { error in
                    guard error == nil else { return completion(error) }

                    self.internalSaveRecord(record: record, completion: completion)
                }
                return
            }

            //Lazy save the subscription

            self.saveSubscription()
            completion(nil)
        }
        operation.qualityOfService = .utility

        database.add(operation)

    }

    /*
     * It will be implemented by subclassing
     */
    fileprivate func saveSubscription() {}

    /*
     * It will be implemented by subclassing
     */
    public func handleNotification() {}
}


class CloudPrivateDatabase: CloudCommonDatabase {
    private let customZoneName = "Cloud_Memo_Zone"
    public var zoneID: CKRecordZoneID!

    public override init(database: CKDatabase) {
        let zone = CKRecordZone(zoneName: self.customZoneName)
        self.zoneID = zone.zoneID

        super.init(database: database)

    }

    /*
     * This method creates custom Zone with specific identifier
     * in this class.
     */
    override fileprivate func createZoneIfNeeded(completion: @escaping ((Error?) -> Void)) {
        createZoneWithID(zoneID: self.zoneID, completion: completion)
    }

    /*
     * Save subscription so that we can be notified whenever
     * some change has happened
     */
    override fileprivate func saveSubscription() {
        //Check If I had saved subscription before

        let subscriptionKey = "ckSubscriptionSaved\(database.scopeString)"
        let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionKey)
        guard !alreadySaved else {return}


        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: RealmCategoryModel.recordTypeString,
                predicate: predicate,
                subscriptionID: subscriptionID,
                options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])


        //Set Silent Push

        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo


        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            guard error == nil else { return }

            UserDefaults.standard.set(true, forKey: subscriptionKey)
        }
        operation.qualityOfService = .utility


        database.add(operation)
    }

    public func loadRecords(recordNames: [String], completion: @escaping (([CKRecordID: CKRecord]?, Error?) -> Void)) {
        super.loadRecords(recordNames: recordNames, in: self.zoneID, completion: completion)
    }

    public override func handleNotification() {
        let serverChangedTokenKey = "ckServerChangeToken\(database.scopeString)"
        var changeToken: CKServerChangeToken?

        if let changeTokenData = UserDefaults.standard.data(forKey: serverChangedTokenKey) {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData) as? CKServerChangeToken
        }


        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = changeToken

        let optionDic = [zoneID: options]

        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: optionDic)
        operation.fetchAllChanges = true //TODO: change it to false

        operation.recordChangedBlock = { record in
            CloudRealmMapper.saveRecordIntoRealm(record: record)
        }

        operation.recordWithIDWasDeletedBlock = { deletedRecordID, recordType in
            CloudRealmMapper.deleteRecordInRealm(recordID: deletedRecordID, recordType: recordType)
        }

        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changedToken, _ in
            guard let changedToken = changedToken else { return }

            let changedTokenData = NSKeyedArchiver.archivedData(withRootObject: changedToken)
            UserDefaults.standard.set(changedTokenData, forKey: serverChangedTokenKey)
        }

        operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
            guard error == nil, let changedToken = changeToken else { return }

            let changedTokenData = NSKeyedArchiver.archivedData(withRootObject: changedToken)
            UserDefaults.standard.set(changedTokenData, forKey: serverChangedTokenKey)
        }


        operation.qualityOfService = .utility

        database.add(operation)
    }
}

class CloudSharedDatabase: CloudCommonDatabase {
    public var zoneIDs: [CKRecordZoneID] = []

    public override init(database: CKDatabase) {
        super.init(database: database)
    }

    /*
     * Save subscription so that we can be notified whenever
     * some change has happened
     */
    override fileprivate func saveSubscription() {
        //Check If I had saved subscription before

        let subscriptionKey = "ckSubscriptionSaved\(database.scopeString)"
        let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionKey)
        guard !alreadySaved else {return}

        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)


        //Set Silent Push

        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo


        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            guard error == nil else { return }

            UserDefaults.standard.set(true, forKey: subscriptionKey)
        }
        operation.qualityOfService = .utility


        database.add(operation)
    }


    public override func handleNotification() {
        let serverChangedTokenKey = "ckServerChangeToken\(database.scopeString)"
        var changeToken: CKServerChangeToken?

        if let changeTokenData = UserDefaults.standard.data(forKey: serverChangedTokenKey) {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData) as? CKServerChangeToken
        }


        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)//CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: optionDic)
        operation.fetchAllChanges = true //TODO: change it to false


        operation.changeTokenUpdatedBlock = { changedToken in

            let changedTokenData = NSKeyedArchiver.archivedData(withRootObject: changedToken)
            UserDefaults.standard.set(changedTokenData, forKey: serverChangedTokenKey)

        }

        operation.fetchDatabaseChangesCompletionBlock = { changeToken, _, error in
            guard error == nil, let changedToken = changeToken else {return}

            let changedTokenData = NSKeyedArchiver.archivedData(withRootObject: changedToken)
            UserDefaults.standard.set(changedTokenData, forKey: serverChangedTokenKey)
        }

        operation.recordZoneWithIDChangedBlock = { zoneID in
            //fetch changes in zone!!
        }

        operation.recordZoneWithIDWasDeletedBlock = { zoneID in
            //delete all models related to zoneID
        }

        operation.recordZoneWithIDWasPurgedBlock = { zoneID in
            //delete all model related to zoneID
        }


        operation.qualityOfService = .utility

        database.add(operation)
    }
}


extension CKDatabase {
    var scopeString: String {
        switch databaseScope {
            case .public: return "public"
            case .private: return "private"
            case .shared: return "shared"
        }
    }
}