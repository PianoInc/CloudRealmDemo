//
// Created by 김범수 on 2018. 2. 12..
// Copyright (c) 2018 piano. All rights reserved.
//

import RealmSwift
import CloudKit


extension RealmTagsModel {
    func getRecord() -> CKRecord {
        let scheme = Schema.Tags.self

        let coder = NSKeyedUnarchiver(forReadingWith: self.ckMetaData)
        coder.requiresSecureCoding = true
        guard let record = CKRecord(coder: coder) else {fatalError("Data polluted!!")}
        coder.finishDecoding()

        record[scheme.tags] = self.tags as CKRecordValue

        return record
    }
}

extension RealmNoteModel {

    func getRecord() -> CKRecord {
        let scheme = Schema.Note.self

        let coder = NSKeyedUnarchiver(forReadingWith: self.ckMetaData)
        coder.requiresSecureCoding = true
        guard let record = CKRecord(coder: coder) else {fatalError("Data poluted!!")}
        coder.finishDecoding()

        record[scheme.id] = self.id as CKRecordValue
        record[scheme.title] = self.title as CKRecordValue
        record[scheme.content] = self.content as CKRecordValue
        record[scheme.attributes] = self.attributes as CKRecordValue

        record[scheme.tags] = self.tags as CKRecordValue
        record[scheme.isPinned] = (self.isPinned ? 1 : 0) as CKRecordValue
        record[scheme.isInTrash] = (self.isInTrash ? 1 : 0) as CKRecordValue

        return record

    }
}

extension RealmImageModel {

    func getRecord() -> (URL, CKRecord) {
        let scheme = Schema.Image.self
        
        let coder = NSKeyedUnarchiver(forReadingWith: self.ckMetaData)
        coder.requiresSecureCoding = true
        guard let record = CKRecord(coder: coder) else {fatalError("Data poluted!!")}
        coder.finishDecoding()
        
        let noteRecordID = CKRecordID(recordName: noteRecordName, zoneID: record.recordID.zoneID)

        record[scheme.id] = self.id as CKRecordValue
        guard let asset = try? CKAsset(data: self.image) else { fatalError() }
        record[scheme.image] = asset

        record[scheme.noteRecordName] = CKReference(recordID: noteRecordID, action: .deleteSelf)
        record.setParent(noteRecordID)
        
        return (asset.fileURL, record)
    }
}


extension CKRecord {

    func parseTagsRecord() -> RealmTagsModel? {
        let newTagsModel = RealmTagsModel()
        let schema = Schema.Tags.self

        guard let tags = self[schema.tags] as? String else {return nil}

        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()

        newTagsModel.tags = tags
        newTagsModel.ckMetaData = Data(referencing: data)

        return newTagsModel
    }

    func parseNoteRecord() -> RealmNoteModel? {
        let newNoteModel = RealmNoteModel()
        let schema = Schema.Note.self

        guard let id = self[schema.id] as? String,
                let title = self[schema.title] as? String,
                let content = self[schema.content] as? String,
                let attributes = self[schema.attributes] as? Data,
                let tags = self[schema.tags] as? String,
                let isPinned = self[schema.isPinned] as? Int,
                let isInTrash = self[schema.isInTrash] as? Int else {return nil}
        
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()

        newNoteModel.id = id
        newNoteModel.title = title
        newNoteModel.content = content
        newNoteModel.attributes = attributes
        newNoteModel.recordName = self.recordID.recordName
        newNoteModel.ckMetaData = Data(referencing: data)
        newNoteModel.isModified = self.modificationDate ?? Date()
        newNoteModel.tags = tags
        newNoteModel.isPinned = isPinned == 1
        newNoteModel.isInTrash = isInTrash == 1

        return newNoteModel
    }

    func parseImageRecord() -> RealmImageModel? {
        let newImageModel = RealmImageModel()
        let schema = Schema.Image.self

        guard let id = self[schema.id] as? String,
                let imageAsset = self[schema.image] as? CKAsset,
                let image = try? Data(contentsOf: imageAsset.fileURL),
                let noteReference = self[schema.noteRecordName] as? CKReference
                else {return nil}

        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()
        
        newImageModel.id = id
        newImageModel.image = image
        newImageModel.noteRecordName = noteReference.recordID.recordName
        newImageModel.recordName = self.recordID.recordName
        newImageModel.ckMetaData = Data(referencing: data)

        defer {
            try? FileManager.default.removeItem(at: imageAsset.fileURL)
        }

        return newImageModel
    }
    
}
