//
//  CloudManager.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 7..
//  Copyright © 2018년 piano. All rights reserved.
//

import CloudKit



class CloudManager {

    static let shared = CloudManager()

    public let databases: [CloudCommonDatabase]
    public let privateDatabase: CloudPrivateDatabase
    public let sharedDatabase: CloudSharedDatabase

    private init() {
        self.privateDatabase = CloudPrivateDatabase(database: CKContainer.default().privateCloudDatabase)
        self.sharedDatabase = CloudSharedDatabase(database: CKContainer.default().sharedCloudDatabase)

        databases = [self.privateDatabase, self.sharedDatabase]

        self.resumeLongLivedOperationIfPossible()
    }



    /*
     * This function enables every offline local change operation to wait for reconnect
     * and resumes them all at once whenever the connection is made again
     */
    private func resumeLongLivedOperationIfPossible() {

        CKContainer.default().fetchAllLongLivedOperationIDs { ( operationIDs, error) in
            guard error == nil,
                    let ids = operationIDs else {return}

            ids.forEach {
                CKContainer.default().fetchLongLivedOperation(withID: $0) { operation, error in
                    guard error == nil else { return }
                    if let operation = operation {
                        CKContainer.default().add(operation)
                    }
                }
            }

        }
    }


    func loadRecordsFromPrivateDBWithID(recordNames: [String], completion handler: @escaping(([CKRecordID: CKRecord]?, Error?) -> Void)) {
        privateDatabase.loadRecords(recordNames: recordNames, completion: handler)
    }


    func uploadRecordToPrivateDB(record: CKRecord, completion: @escaping ((CKRecord?, Error?) -> Void)) {
        privateDatabase.saveRecord(record: record, completion: completion)
    }

    func uploadRecordToSharedDB(record: CKRecord, completion: @escaping ((CKRecord?, Error?) -> Void)) {
        sharedDatabase.saveRecord(record: record, completion: completion)
    }

    func deleteInPrivateDB(recordNames:[String], completion: @escaping ((Error?) -> Void)) {
        privateDatabase.deleteRecords(recordNames: recordNames, completion: completion)
    }

    func deleteInSharedDB(recordNames:[String], in zone: CKRecordZoneID, completion: @escaping ((Error?) -> Void)) {
        sharedDatabase.deleteRecords(recordNames: recordNames, in: zone, completion: completion)
    }
}
