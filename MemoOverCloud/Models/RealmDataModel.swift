//
// Created by 김범수 on 2018. 2. 2..
// Copyright (c) 2018 piano. All rights reserved.
//

import RealmSwift
import CloudKit

@objc protocol Recordable {
    var recordName: String {get set}
    var isShared: Bool {get set}
    var ckMetaData: Data {get set}
    @objc optional func getRecord() -> CKRecord
}

class RealmTagsModel: Object, Recordable {
    static let recordTypeString = "Tags"

    @objc dynamic var id = ""
    @objc dynamic var tags = ""
    @objc dynamic var recordName = ""
    @objc dynamic var ckMetaData = Data()
    @objc dynamic var isShared = false

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["recordTypeString"]
    }

    static func getNewModel() -> RealmTagsModel {
        let id = UniqueIDGenerator.getUniqueID()
        let record = CKRecord(recordType: RealmTagsModel.recordTypeString, zoneID: CloudManager.shared.privateDatabase.zoneID)

        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()

        let newModel = RealmTagsModel()
        newModel.id = id
        newModel.recordName = record.recordID.recordName
        newModel.ckMetaData = Data(referencing: data)

        return newModel
    }
}


class RealmNoteModel: Object, Recordable {

    static let recordTypeString = "Note"

    @objc dynamic var id = ""
    @objc dynamic var title = ""
    @objc dynamic var content = ""
    @objc dynamic var attributes = "[]".data(using: .utf8)!

    @objc dynamic var recordName = ""
    @objc dynamic var ckMetaData = Data()
    @objc dynamic var isModified = Date()
    
    @objc dynamic var isShared = false

    @objc dynamic var isPinned = false
    @objc dynamic var isInTrash = false

    @objc dynamic var tags = ""

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["recordTypeString"]
    }

    static func getNewModel(title: String, categoryRecordName: String) -> RealmNoteModel {
        let id = UniqueIDGenerator.getUniqueID()
        let record = CKRecord(recordType: RealmNoteModel.recordTypeString, zoneID: CloudManager.shared.privateDatabase.zoneID)
        
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()

        let newModel = RealmNoteModel()
        newModel.recordName = record.recordID.recordName
        newModel.ckMetaData = Data(referencing: data)
        newModel.id = id
        newModel.title = title
        newModel.tags = "!\(categoryRecordName)!"
        newModel.content = ""

        return newModel
    }
}

class RealmImageModel: Object, Recordable {

    static let recordTypeString = "Image"

    @objc dynamic var id = ""
    @objc dynamic var image = Data()

    @objc dynamic var recordName = ""
    @objc dynamic var ckMetaData = Data()
    
    @objc dynamic var isShared = false

    @objc dynamic var noteRecordName = ""

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["recordTypeString"]
    }



    static func getNewModel(sharedZoneID: CKRecordZoneID? = nil, noteRecordName: String, image: UIImage) -> RealmImageModel {
        let id = UniqueIDGenerator.getUniqueID()
        let zoneID = sharedZoneID ?? CloudManager.shared.privateDatabase.zoneID
        let record = CKRecord(recordType: RealmImageModel.recordTypeString, zoneID: zoneID)
        
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()
        
        let newModel = RealmImageModel()
        newModel.recordName = record.recordID.recordName
        newModel.ckMetaData = Data(referencing: data)
        newModel.id = id
        newModel.isShared = sharedZoneID != nil
        newModel.noteRecordName = noteRecordName
        newModel.image = UIImageJPEGRepresentation(image, 1.0) ?? Data()
        
        return newModel
    }
}

