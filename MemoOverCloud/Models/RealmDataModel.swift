//
// Created by 김범수 on 2018. 2. 2..
// Copyright (c) 2018 piano. All rights reserved.
//

import RealmSwift
import CloudKit


class RealmCategoryModel: Object {

    static let recordTypeString = "Category"

    @objc dynamic var id = ""
    @objc dynamic var name = ""

    @objc dynamic var recordName = ""
    @objc dynamic var ckMetaData = Data()

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["recordTypeString"]
    }

    static func getNewModel(name: String) -> RealmCategoryModel {
        let id = UniqueIDGenerator.getUniqueID()
        let record = CKRecord(recordType: RealmCategoryModel.recordTypeString, zoneID: CloudManager.shared.privateDatabase.zoneID)
        
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()

        let newModel = RealmCategoryModel()
        newModel.recordName = record.recordID.recordName
        newModel.ckMetaData = Data(referencing: data)
        newModel.id = id
        newModel.name = name

        return newModel
    }
}


class RealmNoteModel: Object {

    static let recordTypeString = "Note"

    @objc dynamic var id = ""
    @objc dynamic var title = ""
    @objc dynamic var content = ""
    @objc dynamic var attributes = Data()

    @objc dynamic var recordName = ""
    @objc dynamic var ckMetaData = Data()
    @objc dynamic var isModified = Date()
    
    @objc dynamic var isShared = false


    @objc dynamic var categoryRecordName = ""

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
        newModel.categoryRecordName = categoryRecordName
        newModel.content = ""

        return newModel
    }
}

class RealmImageModel: Object {

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

