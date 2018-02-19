//
// Created by 김범수 on 2018. 2. 14..
// Copyright (c) 2018 piano. All rights reserved.
//


import CloudKit
import RealmSwift

//TODO: Repetetive code. Refactor it
//TODO: Shared model logic not implemented
class ModelManager {

    static func save(model: RealmCategoryModel, completion: @escaping ((Error?) -> Void)) {
        let record = model.getRecord()

        LocalDatabase.shared.saveObject(newObject: model)

        CloudManager.shared.uploadRecordToPrivateDB(record: record) { (conflicted, error) in
            if let error = error {
                return completion(error)
            } else if let conflictedModel = conflicted?.parseCategoryRecord() {
                LocalDatabase.shared.saveObject(newObject: conflictedModel)
            }
            completion(nil)
        }

    }

    static func delete(model: RealmCategoryModel, completion: @escaping ((Error?) -> Void)) {
        let recordName = model.recordName
        let ref = ThreadSafeReference(to: model)

        LocalDatabase.shared.deleteObject(ref: ref)
        CloudManager.shared.deleteInPrivateDB(recordNames: [recordName]) { error in
            if let error = error { completion(error) }
            else {completion(nil)}
        }
    }


    static func save(model: RealmNoteModel, completion: @escaping ((Error?) -> Void)) {

        if model.isShared {
            //save on shared & update private record also
        } else {

            let record = model.getRecord()
            LocalDatabase.shared.saveObject(newObject: model)
            CloudManager.shared.uploadRecordToPrivateDB(record: record) { (conflicted, error) in
                if let error = error {
                    return completion(error)
                } else if let conflictedModel = conflicted?.parseCategoryRecord() {
                    LocalDatabase.shared.saveObject(newObject: conflictedModel)
                }
                completion(nil)
            }
        }
    }

    static func delete(model: RealmNoteModel, completion: @escaping ((Error?) -> Void)) {

        let recordName = model.recordName
        let ref = ThreadSafeReference(to: model)

        LocalDatabase.shared.deleteObject(ref: ref)
        if model.isShared {

        } else {
            CloudManager.shared.deleteInPrivateDB(recordNames: [recordName]) { error in
                if let error = error { completion(error) }
                else {completion(nil)}

            }
        }
    }


    static func save(model: RealmImageModel, completion: @escaping ((Error?) -> Void)) {

        if model.isShared {

        } else {

            let (url, record) = model.getRecord()
            //TODO: remove URL file in completion
            LocalDatabase.shared.saveObject(newObject: model)
            CloudManager.shared.uploadRecordToPrivateDB(record: record) { (conflicted, error) in
                if let error = error {
                    return completion(error)
                } else if let conflictedModel = conflicted?.parseCategoryRecord() {
                    LocalDatabase.shared.saveObject(newObject: conflictedModel)
                }
                completion(nil)
            }
        }
    }

    static func delete(model: RealmImageModel, completion: @escaping ((Error?) -> Void)) {

        let recordName = model.recordName
        let ref = ThreadSafeReference(to: model)

        LocalDatabase.shared.deleteObject(ref: ref)
        if model.isShared {

        } else {
            CloudManager.shared.deleteInPrivateDB(recordNames: [recordName]) { error in
                if let error = error { completion(error) }
                else {completion(nil)}

            }
        }
    }


}
