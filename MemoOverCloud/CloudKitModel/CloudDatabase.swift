//
// Created by 김범수 on 2018. 2. 8..
// Copyright (c) 2018 piano. All rights reserved.
//

import CloudKit

class CloudCommonDatabase {
    fileprivate let database: CKDatabase
    public let subscriptionID: String
    var userID: CKRecordID?

    init(database: CKDatabase, userID: CKRecordID?) {
        self.database = database

        self.subscriptionID = "cloudkit-note-changes\(database.scopeString)"
        self.userID = userID
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

    //초기 DB zone x -> operation -> error zonex -> zone
    /*
     * It will be implemented by subclassing
     */
    fileprivate func createZoneIfNeeded(completion: @escaping ((Error?) -> Void)) {}


    public func deleteRecords(recordNames: [String], in zoneID: CKRecordZoneID, completion: @escaping ((Error?) -> Void)) {
        let recordIDs = recordNames.map { CKRecordID(recordName: $0, zoneID: zoneID)}

        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)

        operation.modifyRecordsCompletionBlock = { (_, _, error) in
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

                let (ancestorRec, clientRec, serverRec) = ckError.getMergeRecords()
                guard let clientRecord = clientRec,
                        let serverRecord = serverRec,
                        let ancestorRecord = ancestorRec else { return completion(nil, error) }

                //Resolve conflict. If it's false, it means server record has win & no merge happened
                let merged = ConflictResolver.merge(ancestor: ancestorRecord, myRecord: clientRecord, serverRecord: serverRecord)

                if merged {
                    self.saveRecord(record: serverRecord) { newRecord, error in
                        completion(newRecord, error)
                    }
                } else {
                    completion(serverRecord, nil)
                }

                return
            }

            completion(nil, nil)
        }
    }

    private func internalSaveRecord(record: CKRecord, completion: @escaping ((Error?) -> Void)) {

        let isShared = self.database.databaseScope == .shared
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: [])
        operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
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

            
            
            savedRecords?.forEach {
                CloudCommonDatabase.syncChanged(record: $0, isShared: isShared)
            }
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
    public var zoneID: CKRecordZoneID

    public override init(database: CKDatabase, userID: CKRecordID?) {
        let zone = CKRecordZone(zoneName: self.customZoneName)
        self.zoneID = zone.zoneID

        super.init(database: database, userID: userID)
        
        saveSubscription()
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

        let userID = self.userID?.recordName ?? ""
        let recordTypes = [RealmCategoryModel.recordTypeString,
                           RealmNoteModel.recordTypeString,
                           RealmImageModel.recordTypeString,
                           RealmCategoryForSharedModel.recordTypeString]

        recordTypes.forEach {
            let subscriptionKey = "ckSubscriptionSaved\($0)\(database.scopeString)\(userID)"
            let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionKey)
            guard !alreadySaved else {return}


            let predicate = NSPredicate(value: true)

            let subscription = CKQuerySubscription(recordType: $0,
                    predicate: predicate,
                    subscriptionID: "\(subscriptionID)\($0)\(userID)",
                    options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])


            //Set Silent Push

            let notificationInfo = CKNotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo


            let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
            operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
                guard error == nil else { return}

                UserDefaults.standard.set(true, forKey: subscriptionKey)
            }
            operation.qualityOfService = .utility


            database.add(operation)
        }

    }

    public func loadRecords(recordNames: [String], completion: @escaping (([CKRecordID: CKRecord]?, Error?) -> Void)) {
        super.loadRecords(recordNames: recordNames, in: self.zoneID, completion: completion)
    }

    public override func handleNotification() {
        let userID = self.userID?.recordName ?? ""
        let serverChangedTokenKey = "ckServerChangeToken\(database.scopeString)\(userID)"
        var changeToken: CKServerChangeToken?

        if let changeTokenData = UserDefaults.standard.data(forKey: serverChangedTokenKey) {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData) as? CKServerChangeToken
        }


        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = changeToken

        let optionDic = [zoneID: options]

        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: optionDic)
        operation.fetchAllChanges = false

        operation.recordChangedBlock = { record in
            CloudCommonDatabase.syncChanged(record: record, isShared: false)

            if record.recordType == RealmNoteModel.recordTypeString &&
                    record.changedKeys().contains(Schema.Note.content) ||
                    record.changedKeys().contains(Schema.Note.attributes) {

                CloudNotificationCenter.shared.postServerChangeNotification(about: record)

            }
        }

        operation.recordWithIDWasDeletedBlock = { deletedRecordID, recordType in
            CloudCommonDatabase.syncDeleted(recordID: deletedRecordID, recordType: recordType)
        }

        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changedToken, _ in
            guard let changedToken = changedToken else { return }

            let changedTokenData = NSKeyedArchiver.archivedData(withRootObject: changedToken)
            UserDefaults.standard.set(changedTokenData, forKey: serverChangedTokenKey)
        }

        operation.recordZoneFetchCompletionBlock = { [weak self] zoneID, changeToken, data, more, error in
            guard error == nil, let changedToken = changeToken else { return }

            let changedTokenData = NSKeyedArchiver.archivedData(withRootObject: changedToken)
            UserDefaults.standard.set(changedTokenData, forKey: serverChangedTokenKey)

            if more { self?.handleNotification() }
        }


        operation.qualityOfService = .utility

        database.add(operation)
    }

    public func deleteRecords(recordNames: [String], completion: @escaping ((Error?) -> Void)) {
        super.deleteRecords(recordNames: recordNames, in: zoneID, completion: completion)
    }
}

class CloudSharedDatabase: CloudCommonDatabase {
    public var zoneIDs: Set<CKRecordZoneID> = []

    public override init(database: CKDatabase, userID: CKRecordID?) {
        super.init(database: database, userID: userID)
        
        saveSubscription()
    }

    /*
     * Save subscription so that we can be notified whenever
     * some change has happened
     */
    override fileprivate func saveSubscription() {
        //Check If I had saved subscription before

        let userID = self.userID?.recordName ?? ""
        let subscriptionKey = "ckSubscriptionSaved\(database.scopeString)\(userID)"
        let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionKey)
        guard !alreadySaved else {return}

        let subscription = CKDatabaseSubscription(subscriptionID: "\(subscriptionID)\(userID)")


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
        let userID = self.userID?.recordName ?? ""
        let serverChangedTokenKey = "ckServerChangeToken\(database.scopeString)\(userID)"
        var changeToken: CKServerChangeToken?

        if let changeTokenData = UserDefaults.standard.data(forKey: serverChangedTokenKey) {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData) as? CKServerChangeToken
        }


        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        operation.fetchAllChanges = false


        operation.changeTokenUpdatedBlock = { changedToken in

            let changedTokenData = NSKeyedArchiver.archivedData(withRootObject: changedToken)
            UserDefaults.standard.set(changedTokenData, forKey: serverChangedTokenKey)

        }

        operation.fetchDatabaseChangesCompletionBlock = { [weak self] changeToken, more, error in
            guard error == nil, let changedToken = changeToken else {return}

            let changedTokenData = NSKeyedArchiver.archivedData(withRootObject: changedToken)
            UserDefaults.standard.set(changedTokenData, forKey: serverChangedTokenKey)

            if more { self?.handleNotification() }
        }

        operation.recordZoneWithIDChangedBlock = { [weak self] zoneID in
            self?.zoneIDs.insert(zoneID)
            self?.fetchChangesInZone(zoneID)
        }

        operation.recordZoneWithIDWasDeletedBlock = { [weak self] zoneID in
            self?.zoneIDs.remove(zoneID)
            self?.fetchChangesInZone(zoneID)

            let serverChangedTokenKey = "ckServerChangeToken\(self?.database.scopeString ?? "") \(zoneID)\(userID)"
            UserDefaults.standard.removeObject(forKey: serverChangedTokenKey)
            //TODO:check if it works
        }

        operation.recordZoneWithIDWasPurgedBlock = { [weak self] zoneID in
            self?.zoneIDs.remove(zoneID)
            self?.fetchChangesInZone(zoneID)

            let serverChangedTokenKey = "ckServerChangeToken\(self?.database.scopeString ?? "") \(zoneID)\(userID)"
            UserDefaults.standard.removeObject(forKey: serverChangedTokenKey)
            //TODO:check if it works
        }


        operation.qualityOfService = .utility

        database.add(operation)
    }
    
    
    private func fetchChangesInZone(_ zoneID: CKRecordZoneID) {
        let userID = self.userID?.recordName ?? ""
        let serverChangedTokenKey = "ckServerChangeToken\(database.scopeString) \(zoneID)\(userID)"
        var changeToken: CKServerChangeToken?

        if let changeTokenData = UserDefaults.standard.data(forKey: serverChangedTokenKey) {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData) as? CKServerChangeToken
        }

        let options = CKFetchRecordZoneChangesOptions()

        options.previousServerChangeToken = changeToken

        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID],
                                                          optionsByRecordZoneID: [zoneID: options])


        operation.fetchAllChanges = false

        operation.recordChangedBlock = { record in
            CloudCommonDatabase.syncChanged(record: record, isShared: true)
        }

        operation.recordWithIDWasDeletedBlock = { deletedRecordID, recordType in
            CloudCommonDatabase.syncDeleted(recordID: deletedRecordID, recordType: recordType)
        }

        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changedToken, _ in
            guard let changedToken = changedToken else { return }

            let changedTokenData = NSKeyedArchiver.archivedData(withRootObject: changedToken)
            UserDefaults.standard.set(changedTokenData, forKey: serverChangedTokenKey)
        }

        operation.recordZoneFetchCompletionBlock = { [weak self] zoneID, changeToken, data, more, error in
            guard error == nil, let changedToken = changeToken else { return }

            let changedTokenData = NSKeyedArchiver.archivedData(withRootObject: changedToken)
            UserDefaults.standard.set(changedTokenData, forKey: serverChangedTokenKey)

            if more { self?.fetchChangesInZone(zoneID) }
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
