//
// Created by 김범수 on 2018. 2. 8..
// Copyright (c) 2018 piano. All rights reserved.
//

import CloudKit
import RealmSwift



struct Schema {

    struct Tags {
        static let tags = "tags"
    }

    struct Note {
        static let id = "id"
        static let title = "title"
        static let content = "content"
        static let attributes = "attributes"

        static let tags = "tags"
        static let isPinned = "isPinned"
        static let isInTrash = "isInTrash"
    }

    struct Image {
        static let id = "id"
        static let image = "image"

        static let noteRecordName = "noteRecordName"
    }
}

enum RealmRecordTypeString: String {

        case tags = "Tags"
        case note = "Note"
        case image = "Image"
}


extension CloudCommonDatabase {


    static func syncChanged(record: CKRecord, isShared: Bool) {
        guard let realmType = RealmRecordTypeString(rawValue: record.recordType) else { /*fatal error*/ return }

        switch realmType {
            case .tags: saveTagsRecord(record)
            case .note: saveNoteRecord(record, isShared: isShared)
            case .image: saveImageRecord(record, isShared: isShared)
        }

    }

    static func syncDeleted(recordID: CKRecordID, recordType: String) {
        guard let realmType = RealmRecordTypeString(rawValue: recordType) else { /*fatal error*/ return }

        switch realmType {
            case .tags: break //Not gonna happen!
            case .note: deleteNoteRecord(recordID.recordName)
            case .image: deleteImageRecord(recordID.recordName)
        }
    }


    private static func saveTagsRecord(_ record: CKRecord) {
        guard let tagsModel = record.parseTagsRecord() else {return}
        LocalDatabase.shared.saveObject(newObject: tagsModel)
    }

    private static func saveNoteRecord(_ record: CKRecord, isShared: Bool) {
        guard let noteModel = record.parseNoteRecord() else {return}
        let database = isShared ? CloudManager.shared.sharedDatabase : CloudManager.shared.privateDatabase


        if let synchronizer = database.synchronizers[record.recordID.recordName] {
            synchronizer.serverContentChanged(record)
        }

        noteModel.isShared = isShared
        
        LocalDatabase.shared.saveObject(newObject: noteModel)
    }

    private static func saveImageRecord(_ record: CKRecord, isShared: Bool) {

        guard let imageModel = record.parseImageRecord() else {return}

        imageModel.isShared = isShared
        LocalDatabase.shared.saveObject(newObject: imageModel)
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

