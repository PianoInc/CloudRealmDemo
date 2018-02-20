//
// Created by 김범수 on 2018. 2. 2..
// Copyright (c) 2018 piano. All rights reserved.
//

import RealmSwift
import CloudKit

//TODO: remove List properties
protocol Recordable {
    static var recordTypeString: String {get}

    var recordName: String {get set}
    var zoneName: String {get set}
    var ownerName: String {get set}
    var isCreated: Date {get set}
    var isModified: Date {get set}

}

class RealmCategoryModel: Object, Recordable {

    static let recordTypeString = "Category"

    @objc dynamic var id = ""
    @objc dynamic var name = ""

    @objc dynamic var recordName = ""
    @objc dynamic var zoneName = ""
    @objc dynamic var ownerName = ""
    @objc dynamic var isCreated = Date()
    @objc dynamic var isModified = Date()

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["recordTypeString"]
    }

    static func getNewModel(name: String) -> RealmCategoryModel {
        let id = UniqueIDGenerator.getUniqueID()
        let record = CKRecord(recordType: RealmCategoryModel.recordTypeString, zoneID: CloudManager.shared.privateDatabase.zoneID)

        let newModel = RealmCategoryModel()
        newModel.recordName = record.recordID.recordName
        newModel.ownerName = record.recordID.zoneID.ownerName
        newModel.zoneName = record.recordID.zoneID.zoneName
        newModel.id = id
        newModel.name = name

        return newModel
    }
}


class RealmNoteModel: Object, Recordable {

    static let recordTypeString = "Note"

    @objc dynamic var id = ""
    @objc dynamic var title = ""
    @objc dynamic var content = ""
    @objc dynamic var attributes = ""

    @objc dynamic var recordName = ""
    @objc dynamic var zoneName = ""
    @objc dynamic var ownerName = ""
    @objc dynamic var isCreated = Date()
    @objc dynamic var isModified = Date()
    
    @objc dynamic var isShared = false


    let categoryRecordName = ""

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["recordTypeString"]
    }

    static func getNewModel(title: String) -> RealmNoteModel {
        let id = UniqueIDGenerator.getUniqueID()
        let record = CKRecord(recordType: RealmNoteModel.recordTypeString, zoneID: CloudManager.shared.privateDatabase.zoneID)

        let newModel = RealmNoteModel()
        newModel.recordName = record.recordID.recordName
        newModel.ownerName = record.recordID.zoneID.ownerName
        newModel.zoneName = record.recordID.zoneID.zoneName
        newModel.id = id
        newModel.title = title

        return newModel
    }
}

class RealmImageModel: Object, Recordable {

    static let recordTypeString = "Image"

    @objc dynamic var id = ""
    @objc dynamic var image = Data()

    @objc dynamic var recordName = ""
    @objc dynamic var zoneName = ""
    @objc dynamic var ownerName = ""
    @objc dynamic var isCreated = Date()
    @objc dynamic var isModified = Date()
    
    @objc dynamic var isShared = false

    let noteRecordName = ""

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["recordTypeString"]
    }

    static func getNewModel(sharedZoneID: CKRecordZoneID? = nil) -> RealmImageModel {
        let id = UniqueIDGenerator.getUniqueID()
        let zoneID = sharedZoneID ?? CloudManager.shared.privateDatabase.zoneID
        let record = CKRecord(recordType: RealmImageModel.recordTypeString, zoneID: zoneID)
        
        let newModel = RealmImageModel()
        newModel.recordName = record.recordID.recordName
        newModel.ownerName = record.recordID.zoneID.ownerName
        newModel.zoneName = record.recordID.zoneID.zoneName
        newModel.id = id
        
        return newModel
    }
}

