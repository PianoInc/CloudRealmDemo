//
// Created by 김범수 on 2018. 2. 8..
// Copyright (c) 2018 piano. All rights reserved.
//

import CloudKit
import RealmSwift

fileprivate struct Schema {

    struct Category {

        static let id = "id"
        static let name = "name"
        static let notes = "notes"

    }

    struct Note {

        static let id = "id"
        static let title = "title"
        static let content = "content"

        static let shareOwner = "shareOwner"

        static let images = "images"
        static let category = "category"

    }

    struct Image {

        static let id = "id"
        static let original = "original"
        static let thumbnail = "thumbnail"

        static let note = "note"

    }
}

//TODO: I think we should check if the record is shared or not whenever saving or deleting....
class CloudRealmMapper {

    enum RealmRecordTypeString: String {

        case category = "Category"
        case note = "Note"
        case image = "Image"

    }


    static func saveRecordIntoRealm(record: CKRecord) {
        guard let realmType = RealmRecordTypeString(rawValue: record.recordType) else { /*fatal error*/ return }

        switch realmType {
            case .category: saveCategoryRecord(record)
            case .note: saveNoteRecord(record)
            case .image: saveImageRecord(record)
        }

    }

    static func deleteRecordInRealm(recordID: CKRecordID, recordType: String) {
        guard let realmType = RealmRecordTypeString(rawValue: recordType) else { /*fatal error*/ return }

        switch realmType {
            case .category: deleteCategoryRecord(recordID.recordName)
            case .note: deleteNoteRecord(recordID.recordName)
            case .image: deleteImageRecord(recordID.recordName)
        }
    }


    /*
     * Notice!!!
     * When fetching records, all records that have parents such as memo or image
     * they always assume that their parents are present in realm
     * so the order of fetch must be confined to Category -> Note -> Image
     */


    private static func saveCategoryRecord(_ record: CKRecord) {

        guard let categoryModel = parseCategoryRecord(record),
                let noteReferenceList = record[Schema.Category.notes] as? [CKReference] else {return}

        LocalDatabase.shared.saveObject(newObject: categoryModel) {
            //Fetch notes of this category

            let recordNames = noteReferenceList.map{$0.recordID.recordName}
            CloudManager.shared.loadRecordsFromPrivateDBWithID(recordNames: recordNames) { dictionary, error in
                guard error == nil,
                        let recordDic = dictionary else {return /* TODO: handle error plz!!!*/}

                recordDic.forEach{saveNoteRecord($0.value)}

            }
        }
    }

    private static func saveNoteRecord(_ record: CKRecord) {

        guard let realm = try? Realm(),
                let categoryRecordName = (record[Schema.Note.category] as? CKReference)?.recordID.recordName,
                let categoryModel = realm.objects(RealmCategoryModel.self).filter("recordName = %@", categoryRecordName).first,
                let noteModel = parseNoteRecord(record) else {return}



        let categoryRef = ThreadSafeReference(to: categoryModel.notes)
        LocalDatabase.shared.saveObjectWithAppend(list: categoryRef, object: noteModel)

    }

    private static func saveImageRecord(_ record: CKRecord) {

        guard let realm = try? Realm(),
                let noteRecordName = (record["note"] as? CKReference)?.recordID.recordName,
                let noteModel = realm.objects(RealmNoteModel.self).filter("recordName = %@", noteRecordName).first,
                let imageModel = parseImageRecord(record) else {return}


        let noteRef = ThreadSafeReference(to: noteModel.images)
        LocalDatabase.shared.saveObjectWithAppend(list: noteRef, object: imageModel)

    }

    private static func deleteCategoryRecord(_ recordName: String) {

        guard let realm = try? Realm(),
                let categoryModel = realm.objects(RealmCategoryModel.self).filter("recordName - %@", recordName).first else {return}

        categoryModel.notes.forEach {
                deleteNoteRecord($0.recordName)
            }

        let ref = ThreadSafeReference(to: categoryModel)

        LocalDatabase.shared.deleteObject(ref: ref)
    }

    private static func deleteNoteRecord(_ recordName: String) {

        guard let realm = try? Realm(),
                let noteModel = realm.objects(RealmNoteModel.self).filter("recordName = %@", recordName).first else {return}

        noteModel.images.forEach {
                deleteImageRecord($0.recordName)
            }

        let ref = ThreadSafeReference(to: noteModel)

        LocalDatabase.shared.deleteObject(ref: ref)
    }

    private static func deleteImageRecord(_ recordName: String) {

        guard let realm = try? Realm(),
                let imageModel = realm.objects(RealmImageModel.self).filter("recordName = %@", recordName).first else {return}

        let ref = ThreadSafeReference(to: imageModel)

        LocalDatabase.shared.deleteObject(ref: ref)
    }
}

// Parser for CKRecords
extension CloudRealmMapper {

    private static func parseCategoryRecord(_ record: CKRecord) -> RealmCategoryModel? {
        let newCategoryModel = RealmCategoryModel()
        let schema = Schema.Category.self

        guard let id = record[schema.id] as? String,
                let name = record[schema.name] as? String,
                let isCreated = record.creationDate,
                let isModified = record.modificationDate else {return nil}

        newCategoryModel.id = id
        newCategoryModel.name = name
        newCategoryModel.isCreated = isCreated
        newCategoryModel.isModified = isModified

        return newCategoryModel
    }

    private static func parseNoteRecord(_ record: CKRecord) -> RealmNoteModel? {
        let newNoteModel = RealmNoteModel()
        let schema = Schema.Note.self

        guard let id = record[schema.id] as? String,
                let title = record[schema.title] as? String,
                let content = record[schema.content] as? String,
                let isCreated = record.creationDate,
                let isModified = record.modificationDate else {return nil}

        newNoteModel.id = id
        newNoteModel.title = title
        newNoteModel.content = content
        newNoteModel.isCreated = isCreated
        newNoteModel.isModified = isModified

        return newNoteModel
    }

    private static func parseImageRecord(_ record: CKRecord) -> RealmImageModel? {
        let newImageModel = RealmImageModel()
        let schema = Schema.Image.self

        guard let id = record[schema.id] as? String,
                let isCreated = record.creationDate,
                let isModified = record.modificationDate,
                let thumbAsset = record[schema.thumbnail] as? CKAsset,
                let thumbnail = try? Data(contentsOf: thumbAsset.fileURL)
                else {return nil}

        newImageModel.id = id
        newImageModel.isCreated = isCreated
        newImageModel.isModified = isModified
        newImageModel.thumbnail = thumbnail
        newImageModel.recordName = record.recordID.recordName


        return newImageModel
    }
}
