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

        static let category = "category"

    }

    struct Image {

        static let id = "id"
        static let image = "image"

        static let note = "note"

    }
}

//TODO: refactor syncing tasks
class CloudRealmMapper {

    enum RealmRecordTypeString: String {

        case category = "Category"
        case note = "Note"
        case image = "Image"

    }
    
    //This doesn't contain any linking objects property!!!!!!!
//    static func getRecordFromRealmObject(_ model: Object & Recordable) -> CKRecord {
//        let recordTypeString = RealmRecordTypeString(rawValue: type(of: model).recordTypeString)!
//        let zoneID = CKRecordZoneID(zoneName: model.zoneName, ownerName: model.ownerName)
//        let recordID = CKRecordID(recordName: model.recordName, zoneID: zoneID)
//        let record = CKRecord(recordType: recordTypeString.rawValue, recordID: recordID)
//
//
//        let keys = model.objectSchema.properties.map {$0.name}.filter {
//            $0 != "recordName" && $0 != "zoneName" && $0 != "ownerName"
//        }
//
//
//        keys.forEach { key in
//            switch model[key] {
//
//
//            case let value as String:
//                record[key] = value as CKRecordValue
//
//            case let value as Data:
//                record[key] = try? CKAsset(data: value)
//
//            case let list as ListBase:
//                let refList: Array<Object & Recordable>
//
//                if recordTypeString == .category {
//                    guard let noteList = list as? List<RealmNoteModel> else {return}
//                    refList = Array(noteList)
//                } else if recordTypeString == .note {
//                    guard let imageList = list as? List<RealmImageModel> else {return}
//                    refList = Array(imageList)
//                } else { refList = [] }
//
//                record[key] = refList.map { child -> CKReference in
//                    let childRecordID = CKRecordID(recordName: child.recordName, zoneID: zoneID)
//                    return CKReference(recordID: childRecordID, action: .none)
//                } as CKRecordValue
//
//            case let parent as LinkingObjects<Object>:
//                let parentRecordID: CKRecordID?
//
//                if recordTypeString == .note {
//                    guard let parentRecordName = (parent as? LinkingObjects<RealmCategoryModel>)?.first?.recordName else {return}
//                    parentRecordID = CKRecordID(recordName: parentRecordName, zoneID: zoneID)
//                } else if recordTypeString == .image {
//                    guard let parentRecordName = (parent as? LinkingObjects<RealmNoteModel>)?.first?.recordName else {return}
//                    parentRecordID = CKRecordID(recordName: parentRecordName, zoneID: zoneID)
//                } else { parentRecordID = nil; break }
//
//                record.setParent(parentRecordID)
//                record[key] = CKReference(recordID: parentRecordID!, action: .deleteSelf) as CKRecordValue
//
//
//            default: break
//            }
//        }
//
//        return record
//    }


    static func saveRecordIntoRealm(record: CKRecord, isShared: Bool) {
        guard let realmType = RealmRecordTypeString(rawValue: record.recordType) else { /*fatal error*/ return }

        switch realmType {
            case .category: saveCategoryRecord(record)
            case .note: saveNoteRecord(record, isShared: isShared)
            case .image: saveImageRecord(record, isShared: isShared)
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

        guard let categoryModel = record.parseCategoryRecord() else {return}
        LocalDatabase.shared.saveObject(newObject: categoryModel)
    }

    private static func saveNoteRecord(_ record: CKRecord, isShared: Bool) {
        guard let noteModel = record.parseNoteRecord() else {return}

        noteModel.isShared = isShared
        LocalDatabase.shared.saveObject(newObject: noteModel)

    }

    private static func saveImageRecord(_ record: CKRecord, isShared: Bool) {

        guard let imageModel = record.parseImageRecord() else {return}

        imageModel.isShared = isShared
        LocalDatabase.shared.saveObject(newObject: imageModel)
    }

    private static func deleteCategoryRecord(_ recordName: String) {

        guard let realm = try? Realm(),
                let categoryModel = realm.objects(RealmCategoryModel.self).filter("recordName = %@", recordName).first else {return}

        let notes = realm.objects(RealmNoteModel.self).filter("categoryRecordName = %@", recordName)

        let categoryRef = ThreadSafeReference(to: categoryModel)
        let notesRef =  ThreadSafeReference(to: notes)
        LocalDatabase.shared.deleteObject(ref: categoryRef)
        LocalDatabase.shared.deleteObject(ref: notesRef)
    }

    private static func deleteNoteRecord(_ recordName: String) {

        guard let realm = try? Realm(),
                let noteModel = realm.objects(RealmNoteModel.self).filter("recordName = %@", recordName).first else {return}

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
}

