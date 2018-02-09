//
// Created by 김범수 on 2018. 2. 8..
// Copyright (c) 2018 piano. All rights reserved.
//

import CloudKit

class CloudDatabase {

    private static let customZoneName = "Cloud_Memo_Zone"
    private let database: CKDatabase

    public var zoneID: CKRecordZoneID!
    public let subscriptionID: String


    public init (database: CKDatabase) {
        self.database = database

        if database.databaseScope == .shared {
            //TODO: register database subscription
            fatalError()
        } else if database.databaseScope == .private {
            let zone = CKRecordZone(zoneName: CloudDatabase.customZoneName)
            self.zoneID = zone.zoneID

            self.subscriptionID = "cloudkit-note-changes\(database.scopeString)"
        } else {
            // We're not using any public database!!
            fatalError()
        }

    }


    /*
     * This method creates custom Zone with specific identifier
     * in this class.
     */
    private func createZone(completion: @escaping ((Error?) -> Void)) {
        let recordZone = CKRecordZone(zoneID: self.zoneID)
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
     * Save subscription so that we can be notified whenever
     * some change has happened
     */
    private func saveSubscriptionForCategory() {
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


    private func saveSubscriptionForSharedDB() {

        let subscriptionKey = "ckSubscriptionSaved\(database.scopeString)"
        let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionKey)
        guard !alreadySaved else {return}


        let predicate = NSPredicate(value: true)

        //TODO: finish it
    }


    /*
     * Load records by given record names
     */
    public func loadRecords(recordNames: [String], completion: @escaping (([CKRecordID: CKRecord]?, Error?) -> Void)) {

        let recordIDs = recordNames.map { CKRecordID(recordName: $0, zoneID: self.zoneID) }


        let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
        operation.fetchRecordsCompletionBlock = { records, error in
            guard error == nil else { return completion(nil, error)}

            completion(records, nil)
        }
        operation.qualityOfService = .utility


        database.add(operation)

    }


    public func saveRecord(record: CKRecord, completion: @escaping ((Error?) -> Void)) {

        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: [])
        operation.modifyRecordsCompletionBlock = { _, _, error in
            guard error == nil else {
                guard let cloudError = error as? CKError,
                        cloudError.isZoneNotFound() else { return completion(error) }


                //Zone has not created yet, Let's make one
                //And try to save record again

                self.createZone() { error in
                    guard error == nil else { return completion(error) }

                    self.saveRecord(record: record, completion: completion)
                }
                return
            }

            //Lazy save the subscription

            self.saveSubscriptionForCategory()
            completion(nil)
        }
        operation.qualityOfService = .utility

        database.add(operation)

    }

    public func handleNotification() {

        let serverChangedTokenKey = "ckServerChangeToken\(database.scopeString)"
        var changeToken: CKServerChangeToken?

        if let changeTokenData = UserDefaults.standard.data(forKey: serverChangedTokenKey) {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData) as? CKServerChangeToken
        }


        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = changeToken

        let optionDic = [zoneID: options]
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: optionDic)
        operation.fetchAllChanges = true // change it to false

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

extension CKDatabase {
    var scopeString: String {
        switch databaseScope {
            case .public: return "public"
            case .private: return "private"
            case .shared: return "shared"
        }
    }
}