//
// Created by 김범수 on 2018. 2. 12..
// Copyright (c) 2018 piano. All rights reserved.
//

import RealmSwift
import CloudKit


extension RealmCategoryModel {

    func getRecord() -> CKRecord {
        let scheme = Schema.Category.self
        let zoneID = CKRecordZoneID(zoneName: self.zoneName, ownerName: self.ownerName)
        let recordID = CKRecordID(recordName: self.recordName, zoneID: zoneID)
        let record = CKRecord(recordType: RealmCategoryModel.recordTypeString, recordID: recordID)

        record[scheme.id] = self.id as CKRecordValue
        record[scheme.name] = self.name as CKRecordValue
        record[scheme.notes] = Array(self.notes).map { model -> CKReference in
            let recordID = CKRecordID(recordName: model.recordName, zoneID: zoneID)
            return CKReference(recordID: recordID, action: .none)
        } as CKRecordValue

        return record
    }

}

extension RealmNoteModel {

    func getRecord() -> CKRecord {
        let scheme = Schema.Note.self
        let zoneID = CKRecordZoneID(zoneName: self.zoneName, ownerName: self.ownerName)
        let recordID = CKRecordID(recordName: self.recordName, zoneID: zoneID)
        let record = CKRecord(recordType: RealmNoteModel.recordTypeString, recordID: recordID)
        let categoryRecordID = CKRecordID(recordName: self.category.first!.recordName, zoneID: zoneID)
        

        record[scheme.id] = self.id as CKRecordValue
        record[scheme.title] = self.title as CKRecordValue
        record[scheme.content] = self.content as CKRecordValue
        record[scheme.pureString] = self.pureString as CKRecordValue

        record[scheme.images] = Array(self.images).map { model -> CKReference in
            let recordID = CKRecordID(recordName: model.recordName, zoneID: zoneID)
            return CKReference(recordID: recordID, action: .none)
        } as CKRecordValue


        record[scheme.category] = CKReference(recordID: categoryRecordID, action: .deleteSelf)

        return record

    }
}

extension RealmImageModel {

    func getRecord() -> CKRecord {
        let scheme = Schema.Image.self
        let zoneID = CKRecordZoneID(zoneName: self.zoneName, ownerName: self.ownerName)
        let recordID = CKRecordID(recordName: self.recordName, zoneID: zoneID)
        let noteRecordID = CKRecordID(recordName: self.note.first!.recordName, zoneID: zoneID)
        let record = CKRecord(recordType: RealmImageModel.recordTypeString, recordID: recordID)

        record[scheme.id] = self.id as CKRecordValue
        record[scheme.original] = try? CKAsset(data: self.original)
        record[scheme.thumbnail] = try? CKAsset(data: self.thumbnail)
        record[scheme.note] = CKReference(recordID: noteRecordID, action: .deleteSelf)

        record.setParent(noteRecordID)
        
        return record
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
                let pureString = self[schema.pureString] as? String,
                let isCreated = self.creationDate,
                let isModified = self.modificationDate else {return nil}

        newNoteModel.id = id
        newNoteModel.title = title
        newNoteModel.content = content
        newNoteModel.pureString = pureString
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
                let thumbAsset = self[schema.thumbnail] as? CKAsset,
                let thumbnail = try? Data(contentsOf: thumbAsset.fileURL)
                else {return nil}

        newImageModel.id = id
        newImageModel.isCreated = isCreated
        newImageModel.isModified = isModified
        newImageModel.thumbnail = thumbnail
        newImageModel.recordName = self.recordID.recordName
        newImageModel.zoneName = self.recordID.zoneID.zoneName
        newImageModel.ownerName = self.recordID.zoneID.ownerName


        return newImageModel
    }
}
