//
// Created by 김범수 on 2018. 2. 12..
// Copyright (c) 2018 piano. All rights reserved.
//

import RealmSwift
import CloudKit


extension RealmCategoryModel {

    func getRecord() -> CKRecord {
        let scheme = Schema.Category.self
        let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: ownerName)
        let recordID = CKRecordID(recordName: self.recordName, zoneID: zoneID)
        let record = CKRecord(recordType: RealmCategoryModel.recordTypeString, recordID: recordID)

        record[scheme.id] = self.id as CKRecordValue
        record[scheme.name] = self.name as CKRecordValue

        return record
    }

}

extension RealmNoteModel {

    func getRecord() -> CKRecord {
        let scheme = Schema.Note.self
        let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: ownerName)
        let recordID = CKRecordID(recordName: self.recordName, zoneID: zoneID)
        let record = CKRecord(recordType: RealmNoteModel.recordTypeString, recordID: recordID)
        let categoryRecordID = CKRecordID(recordName: self.categoryRecordName, zoneID: zoneID)
        

        record[scheme.id] = self.id as CKRecordValue
        record[scheme.title] = self.title as CKRecordValue
        record[scheme.content] = self.content as CKRecordValue
        record[scheme.attributes] = self.attributes as CKRecordValue


        record[scheme.categoryRecordName] = CKReference(recordID: categoryRecordID, action: .deleteSelf)

        return record

    }
}

extension RealmImageModel {

    func getRecord() -> (URL, CKRecord) {
        let scheme = Schema.Image.self
        let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: ownerName)
        let recordID = CKRecordID(recordName: self.recordName, zoneID: zoneID)
        let record = CKRecord(recordType: RealmImageModel.recordTypeString, recordID: recordID)
        let noteRecordID = CKRecordID(recordName: noteRecordName, zoneID: zoneID)

        record[scheme.id] = self.id as CKRecordValue
        guard let asset = try? CKAsset(data: self.image) else { fatalError() }
        record[scheme.image] = asset

        record[scheme.noteRecordName] = CKReference(recordID: noteRecordID, action: .deleteSelf)
        record.setParent(noteRecordID)
        
        return (asset.fileURL, record)
    }
}


extension CKRecord {
    func parseCategoryRecord() -> RealmCategoryModel? {
        let newCategoryModel = RealmCategoryModel()
        let schema = Schema.Category.self

        guard let id = self[schema.id] as? String,
                let name = self[schema.name] as? String,
                let isCreated = self.creationDate,
                let isModified = self.modificationDate else {return nil}

        newCategoryModel.id = id
        newCategoryModel.name = name
        newCategoryModel.isCreated = isCreated
        newCategoryModel.isModified = isModified
        newCategoryModel.recordName = self.recordID.recordName
        newCategoryModel.zoneName = self.recordID.zoneID.zoneName
        newCategoryModel.ownerName = self.recordID.zoneID.ownerName

        return newCategoryModel
    }

    func parseNoteRecord() -> RealmNoteModel? {
        let newNoteModel = RealmNoteModel()
        let schema = Schema.Note.self

        guard let id = self[schema.id] as? String,
                let title = self[schema.title] as? String,
                let content = self[schema.content] as? String,
                let attributes = self[schema.attributes] as? String,
                let categoryReference = self[schema.categoryRecordName] as? CKReference,
                let isCreated = self.creationDate,
                let isModified = self.modificationDate else {return nil}

        newNoteModel.id = id
        newNoteModel.title = title
        newNoteModel.content = content
        newNoteModel.attributes = attributes
        newNoteModel.categoryRecordName = categoryReference.recordID.recordName
        newNoteModel.isCreated = isCreated
        newNoteModel.isModified = isModified
        newNoteModel.recordName = self.recordID.recordName
        newNoteModel.zoneName = self.recordID.zoneID.zoneName
        newNoteModel.ownerName = self.recordID.zoneID.ownerName

        return newNoteModel
    }

    func parseImageRecord() -> RealmImageModel? {
        let newImageModel = RealmImageModel()
        let schema = Schema.Image.self

        guard let id = self[schema.id] as? String,
                let isCreated = self.creationDate,
                let isModified = self.modificationDate,
                let imageAsset = self[schema.image] as? CKAsset,
                let image = try? Data(contentsOf: imageAsset.fileURL),
                let noteReference = self[schema.noteRecordName] as? CKReference
                else {return nil}

        newImageModel.id = id
        newImageModel.isCreated = isCreated
        newImageModel.isModified = isModified
        newImageModel.image = image
        newImageModel.noteRecordName = noteReference.recordID.recordName
        newImageModel.recordName = self.recordID.recordName
        newImageModel.zoneName = self.recordID.zoneID.zoneName
        newImageModel.ownerName = self.recordID.zoneID.ownerName


        return newImageModel
    }

}
