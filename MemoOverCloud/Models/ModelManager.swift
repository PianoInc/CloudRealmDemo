//
// Created by 김범수 on 2018. 2. 14..
// Copyright (c) 2018 piano. All rights reserved.
//


import CloudKit
import RealmSwift

//TODO: Repetetive code. Refactor it by generic

class ModelManager {
    
    private func getTypeFrom(recordType string: String) -> Object.Type? {
        switch string {
            case RealmCategoryModel.recordTypeString: return RealmCategoryModel.self
            case RealmNoteModel.recordTypeString: return RealmNoteModel.self
            case RealmImageModel.recordTypeString: return RealmImageModel.self
            default: return nil
        }
    }


    static func saveNew(model: RealmCategoryModel, completion: ((Error?) -> Void)? = nil) {
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


    static func saveNew(model: RealmNoteModel, completion: ((Error?) -> Void)? = nil) {
        
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

        CloudManager.shared.uploadRecordToPrivateDB(record: record, completion: cloudCompletion)
    }


    static func saveNew(model: RealmImageModel, completion: ((Error?) -> Void)? = nil) {

        let (url, record) = model.getRecord()
        LocalDatabase.shared.saveObject(newObject: model)

        let uploadFunc = model.isShared ? CloudManager.shared.uploadRecordToSharedDB:
                                            CloudManager.shared.uploadRecordToPrivateDB

        uploadFunc(record) { conflicted, error in
            if let error = error {
                return completion?(error) ?? ()
            } else if let conflictedModel = conflicted?.parseImageRecord() {
                LocalDatabase.shared.saveObject(newObject: conflictedModel)
            }
            completion?(nil)
            try? FileManager.default.removeItem(at: url)
        }
    }



    static func delete(id: String, type: Object.Type, completion: ((Error?) -> Void)? = nil) {
        guard let realm = try? Realm(),
                let model = realm.object(ofType: type.self, forPrimaryKey: id),
                let recordable = model as? Recordable else {return}

        let recordName = recordable.recordName
        let ref = ThreadSafeReference(to: model)


        LocalDatabase.shared.deleteObject(ref: ref)

        let cloudCompletion: (Error?) -> () = { error in
            if let error = error {completion?(error)}
            else {completion?(nil)}
        }

        if recordable.isShared {
            let coder = NSKeyedUnarchiver(forReadingWith: recordable.ckMetaData)
            coder.requiresSecureCoding = true
            guard let record = CKRecord(coder: coder) else {fatalError("Data polluted!!")}
            coder.finishDecoding()
            CloudManager.shared.deleteInSharedDB(recordNames: [recordName], in: record.recordID.zoneID, completion: cloudCompletion)
        } else {
            CloudManager.shared.deleteInPrivateDB(recordNames: [recordName], completion: cloudCompletion)
        }
    }

    static func update(id: String, type: Object.Type, kv: [String: Any], completion: ((Error?) -> Void)? = nil) {

        LocalDatabase.shared.updateObject(id: id, kv: kv, type: type.self) {
            LocalDatabase.shared.databaseQueue.sync {
                autoreleasepool {
                    guard let realm = try? Realm(),
                          let model = realm.object(ofType: type.self, forPrimaryKey: id) as? (Object & Recordable),
                            let record = model.getRecord?()else {return}


                    let uploadFunc = model.isShared ? CloudManager.shared.uploadRecordToSharedDB :
                                                CloudManager.shared.uploadRecordToPrivateDB
                    uploadFunc(record) { (conflicted, error) in
                        if let error = error {
                            return completion?(error) ?? ()
                        } else if let conflictedRecord = conflicted {
                            let newModel: Object?

                            switch conflictedRecord.recordType {
                                case RealmCategoryModel.recordTypeString:
                                    newModel = conflictedRecord.parseCategoryRecord()
                                case RealmNoteModel.recordTypeString:
                                    newModel = conflictedRecord.parseNoteRecord()
                                case RealmImageModel.recordTypeString:
                                    newModel = conflictedRecord.parseImageRecord()
                                default:
                                    newModel = nil
                            }

                            if let safeModel = newModel {
                                LocalDatabase.shared.saveObject(newObject: safeModel)
                            }
                        } else {
                            completion?(nil)
                        }
                    }
                }
            }
        }
    }
}
