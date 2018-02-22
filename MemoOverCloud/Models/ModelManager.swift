//
// Created by 김범수 on 2018. 2. 14..
// Copyright (c) 2018 piano. All rights reserved.
//


import CloudKit
import RealmSwift

//TODO: Repetetive code. Refactor it by generic
class ModelManager {

    static func save(model: RealmCategoryModel, completion: ((Error?) -> Void)? = nil) {
        let record = model.getRecord()

        LocalDatabase.shared.saveObject(newObject: model)

        CloudManager.shared.uploadRecordToPrivateDB(record: record) { (conflicted, error) in
            if let error = error {
                return completion?(error) ?? ()
            } else if let conflictedModel = conflicted?.parseCategoryRecord() {
                LocalDatabase.shared.saveObject(newObject: conflictedModel)
            }
            completion?(nil)
        }

    }

    static func delete(model: RealmCategoryModel, completion: ((Error?) -> Void)? = nil) {
        let recordName = model.recordName
        let ref = ThreadSafeReference(to: model)


        LocalDatabase.shared.deleteObject(ref: ref)
        CloudManager.shared.deleteInPrivateDB(recordNames: [recordName]) { error in
            if let error = error { completion?(error) }
            else {completion?(nil)}
        }
    }
    
    static func update(model: RealmCategoryModel, kv: [String: Any], completion: ((Error?) -> Void)? = nil) {
        
        let ref = ThreadSafeReference(to: model)
        let id = model.id
        
        LocalDatabase.shared.updateObject(ref: ref, kv: kv) {
            LocalDatabase.shared.databaseQueue.sync {
                autoreleasepool {
                    guard let realm = try? Realm(), let updatedModel = realm.object(ofType: RealmCategoryModel.self, forPrimaryKey: id) else {return}
                    let record = updatedModel.getRecord()
                    
                    CloudManager.shared.uploadRecordToPrivateDB(record: record){ (conflicted, error) in
                        if let error = error {
                            return completion?(error) ?? ()
                        } else if let conflictedModel = conflicted?.parseCategoryRecord() {
                            LocalDatabase.shared.saveObject(newObject: conflictedModel)
                        }
                        completion?(nil)
                    }
                }
            }
        }
    }


    static func save(model: RealmNoteModel, completion: ((Error?) -> Void)? = nil) {

        let record = model.getRecord()
        LocalDatabase.shared.saveObject(newObject: model)

        let cloudCompletion: (CKRecord?, Error?) -> Void = { (conflicted, error) in

            if let error = error {
                return completion?(error) ?? ()
            } else if let conflictedModel = conflicted?.parseNoteRecord() {
                LocalDatabase.shared.saveObject(newObject: conflictedModel)
            }
            completion?(nil)
        }

        if model.isShared {
            
            let recordID = CKRecordID(recordName: record.recordID.recordName, zoneID: CloudManager.shared.privateDatabase.zoneID)
            let categoryForSharedMemoRecord = CKRecord(recordType: RealmRecordTypeString.categoryForSharedMemo.rawValue, recordID: recordID)

            categoryForSharedMemoRecord[Schema.SharedNote.categoryRecordName] = model.categoryRecordName as CKRecordValue

            record[Schema.Note.categoryRecordName] = nil
            CloudManager.shared.uploadRecordToSharedDB(record: record, completion: cloudCompletion)
            CloudManager.shared.uploadRecordToPrivateDB(record: record) {_,_ in }
        } else {
            CloudManager.shared.uploadRecordToPrivateDB(record: record, completion: cloudCompletion)
        }
    }

    static func delete(model: RealmNoteModel, completion: ((Error?) -> Void)? = nil) {

        let recordName = model.recordName
        let ref = ThreadSafeReference(to: model)

        
        if model.isShared {
            let record = model.getRecord()
            CloudManager.shared.deleteInPrivateDB(recordNames: [recordName], completion: {_ in})
            CloudManager.shared.deleteInSharedDB(recordNames: [recordName], in: record.recordID.zoneID) { error in
                if let error = error { completion?(error) }
                else {completion?(nil)}
            }
        } else {
            CloudManager.shared.deleteInPrivateDB(recordNames: [recordName]) { error in
                if let error = error { completion?(error) }
                else {completion?(nil)}
            }
        }
        
        LocalDatabase.shared.deleteObject(ref: ref)
    }

    static func update(model: RealmNoteModel, kv: [String: Any], completion: ((Error?) -> Void)? = nil) {
        
        let ref = ThreadSafeReference(to: model)
        let id = model.id
        
        LocalDatabase.shared.updateObject(ref: ref, kv: kv) {
            LocalDatabase.shared.databaseQueue.sync {
                autoreleasepool {
                    guard let realm = try? Realm(), let updatedModel = realm.object(ofType: RealmNoteModel.self, forPrimaryKey: id) else {return}
                    
                    let record = updatedModel.getRecord()
                    let cloudCompletion: (CKRecord?, Error?) -> Void = { (conflicted, error) in
                        
                        if let error = error {
                            return completion?(error) ?? ()
                        } else if let conflictedModel = conflicted?.parseNoteRecord() {
                            LocalDatabase.shared.saveObject(newObject: conflictedModel)
                        }
                        completion?(nil)
                    }
                    
                    if updatedModel.isShared {
                        //TODO: logic needs to be fixed
                        let recordID = CKRecordID(recordName: record.recordID.recordName, zoneID: CloudManager.shared.privateDatabase.zoneID)
                        let categoryForSharedMemoRecord = CKRecord(recordType: RealmRecordTypeString.categoryForSharedMemo.rawValue, recordID: recordID)
                        
                        categoryForSharedMemoRecord[Schema.SharedNote.categoryRecordName] = model.categoryRecordName as CKRecordValue
                        
                        record[Schema.Note.categoryRecordName] = nil
                        CloudManager.shared.uploadRecordToSharedDB(record: record, completion: cloudCompletion)
                        CloudManager.shared.uploadRecordToPrivateDB(record: record) {_,_ in }
                    } else {
                        CloudManager.shared.uploadRecordToPrivateDB(record: record, completion: cloudCompletion)
                    } 
                }
            }
        }
        
    }

    static func save(model: RealmImageModel, completion: ((Error?) -> Void)? = nil) {

        let (url, record) = model.getRecord()
        LocalDatabase.shared.saveObject(newObject: model)

        if model.isShared {
            CloudManager.shared.uploadRecordToSharedDB(record: record) { conflicted, error in
                if let error = error {
                    return completion?(error) ?? ()
                } else if let conflictedModel = conflicted?.parseImageRecord() {
                    LocalDatabase.shared.saveObject(newObject: conflictedModel)
                }
                completion?(nil)
                try? FileManager.default.removeItem(at: url)
            }
        } else {
            CloudManager.shared.uploadRecordToPrivateDB(record: record) { (conflicted, error) in
                if let error = error {
                    return completion?(error) ?? ()
                } else if let conflictedModel = conflicted?.parseImageRecord() {
                    LocalDatabase.shared.saveObject(newObject: conflictedModel)
                }
                completion?(nil)
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    static func delete(model: RealmImageModel, completion: ((Error?) -> Void)? = nil) {

        let recordName = model.recordName
        let ref = ThreadSafeReference(to: model)

        if model.isShared {
            //Not make any additional url
            let coder = NSKeyedUnarchiver(forReadingWith: model.ckMetaData)
            coder.requiresSecureCoding = true
            guard let record = CKRecord(coder: coder) else {fatalError("Data polluted!!")}
            coder.finishDecoding()
            
            CloudManager.shared.deleteInSharedDB(recordNames: [recordName], in: record.recordID.zoneID) { error in
                if let error = error { completion?(error) }
                else { completion?(nil) }
            }
        } else {
            CloudManager.shared.deleteInPrivateDB(recordNames: [recordName]) { error in
                if let error = error { completion?(error) }
                else {completion?(nil)}

            }
        }
        
        LocalDatabase.shared.deleteObject(ref: ref)
    }


}
