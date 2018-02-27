//
// Created by 김범수 on 2018. 2. 8..
// Copyright (c) 2018 piano. All rights reserved.
//

import CloudKit
import RealmSwift



struct Schema {

    struct Category {

        static let id = "id"
        static let name = "name"

    }

    struct Note {

        static let id = "id"
        static let title = "title"
        static let content = "content"
        static let attributes = "attributes"

        static let categoryRecordName = "categoryRecordName"

    }

    struct Image {

        static let id = "id"
        static let image = "image"

        static let noteRecordName = "noteRecordName"

    }

    struct categoryForSharedNote {
        static let CategoryRecordName = "categoryRecordName"
    }
}

enum RealmRecordTypeString: String {

        case category = "Category"
        case note = "Note"
        case image = "Image"
        case categoryForSharedNote = "categoryForSharedNote"
}


extension CloudCommonDatabase {


    static func syncChanged(record: CKRecord, isShared: Bool) {
        guard let realmType = RealmRecordTypeString(rawValue: record.recordType) else { /*fatal error*/ return }

        switch realmType {
            case .category: saveCategoryRecord(record)
            case .note: saveNoteRecord(record, isShared: isShared)
            case .image: saveImageRecord(record, isShared: isShared)
            case .categoryForSharedNote: saveCategoryForSharedNote(record)
        }

    }

    static func syncDeleted(recordID: CKRecordID, recordType: String) {
        guard let realmType = RealmRecordTypeString(rawValue: recordType) else { /*fatal error*/ return }

        switch realmType {
            case .category: deleteCategoryRecord(recordID.recordName)
            case .note: deleteNoteRecord(recordID.recordName)
            case .image: deleteImageRecord(recordID.recordName)
            case .categoryForSharedNote: deleteCategoryForSharedNoteRecord(recordID.recordName)
        }
    }



    private static func saveCategoryRecord(_ record: CKRecord) {

        guard let categoryModel = record.parseCategoryRecord() else {return}
        LocalDatabase.shared.saveObject(newObject: categoryModel)
    }

    private static func saveNoteRecord(_ record: CKRecord, isShared: Bool) {
        
        guard let noteModel = record.parseNoteRecord() else {return}

        noteModel.isShared = isShared
        
        if isShared {
            if let realm = try? Realm(),
                let oldNote = realm.object(ofType: RealmNoteModel.self, forPrimaryKey: noteModel.id) {
                noteModel.categoryRecordName = oldNote.categoryRecordName
            }
        }
        
        LocalDatabase.shared.saveObject(newObject: noteModel)

        
    }

    private static func saveImageRecord(_ record: CKRecord, isShared: Bool) {

        guard let imageModel = record.parseImageRecord() else {return}

        imageModel.isShared = isShared
        LocalDatabase.shared.saveObject(newObject: imageModel)
    }

    private static func saveCategoryForSharedNote(_ record: CKRecord) {
        
        guard let realm = try? Realm(),
                let noteModel = realm.objects(RealmNoteModel.self).filter("recordName = %@", record.recordID.recordName).first,
                let categoryForSharedNoteModel = record.parseCategoryForSharedNoteRecord() else {return}

        let categoryRecordName = categoryForSharedNoteModel.categoryRecordName
        let kv = [Schema.Note.categoryRecordName: categoryRecordName]
        let ref = ThreadSafeReference(to: noteModel)

        LocalDatabase.shared.updateObject(ref: ref, kv: kv)
        LocalDatabase.shared.saveObject(newObject: categoryForSharedNoteModel)
    }

    private static func deleteCategoryRecord(_ recordName: String) {

        guard let realm = try? Realm(),
                let categoryModel = realm.objects(RealmCategoryModel.self).filter("recordName = %@", recordName).first else {return}

        let notes = realm.objects(RealmNoteModel.self).filter("categoryRecordName = %@", recordName)

        let categoryRef = ThreadSafeReference(to: categoryModel)

        notes.forEach{ deleteNoteRecord($0.recordName) }
        LocalDatabase.shared.deleteObject(ref: categoryRef)
    }

    private static func deleteNoteRecord(_ recordName: String) {

        guard let realm = try? Realm(),
                let noteModel = realm.objects(RealmNoteModel.self).filter("recordName = %@", recordName).first else {return}

        if noteModel.isShared {
            deleteCategoryForSharedNoteRecord(recordName)
        }
        
        let images = realm.objects(RealmImageModel.self).filter("noteRecordName = %@", recordName)

        let noteRef = ThreadSafeReference(to: noteModel)
        let imagesRef = ThreadSafeReference(to: images)
        LocalDatabase.shared.deleteObject(ref: noteRef)
        LocalDatabase.shared.deleteObject(ref: imagesRef)
    }

    private static func deleteImageRecord(_ recordName: String) {

        guard let realm = try? Realm(),
                let imageModel = realm.objects(RealmImageModel.self).filter("recordName = %@", recordName).first else {return}

        let ref = ThreadSafeReference(to: imageModel)

        LocalDatabase.shared.deleteObject(ref: ref)
    }

    private static func deleteCategoryForSharedNoteRecord(_ recordName: String) {
        
        guard let realm = try? Realm(),
                let categoryForSharedNoteModel = realm.objects(RealmCategoryForSharedModel.self).filter("recordName = %@", recordName).first else {return}

        let ref = ThreadSafeReference(to: categoryForSharedNoteModel)
        LocalDatabase.shared.deleteObject(ref: ref)
    }
}

