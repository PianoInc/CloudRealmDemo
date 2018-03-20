//
// Created by 김범수 on 2018. 2. 12..
// Copyright (c) 2018 piano. All rights reserved.
//

import RealmSwift
import CloudKit


extension RealmCategoryModel {

    func getRecord() -> CKRecord {
        let scheme = Schema.Category.self
        
        let coder = NSKeyedUnarchiver(forReadingWith: self.ckMetaData)
        coder.requiresSecureCoding = true
        guard let record = CKRecord(coder: coder) else {fatalError("Data poluted!!")}
        coder.finishDecoding()


        record[scheme.id] = self.id as CKRecordValue
        record[scheme.name] = self.name as CKRecordValue

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


        let categoryRecordIDs = self.categoryRecordNames.components(separatedBy: "!").map{ CKRecordID(recordName: $0, zoneID: record.recordID.zoneID) }
        

        record[scheme.id] = self.id as CKRecordValue
        record[scheme.title] = self.title as CKRecordValue
        record[scheme.content] = self.content as CKRecordValue
        record[scheme.attributes] = self.attributes as CKRecordValue


        record[scheme.categoryRecordNames] = (categoryRecordIDs.map{ CKReference(recordID: $0, action: .deleteSelf)}) as CKRecordValue

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
    func parseCategoryRecord() -> RealmCategoryModel? {
        let newCategoryModel = RealmCategoryModel()
        let schema = Schema.Category.self

        guard let id = self[schema.id] as? String,
                let name = self[schema.name] as? String else {return nil}
        
        let data = NSMutableData()
        let coder = NSKeyedArchiver.init(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()

        newCategoryModel.id = id
        newCategoryModel.name = name
        newCategoryModel.recordName = self.recordID.recordName
        newCategoryModel.ckMetaData = Data(referencing: data)

        return newCategoryModel
    }

    func parseNoteRecord() -> RealmNoteModel? {
        let newNoteModel = RealmNoteModel()
        let schema = Schema.Note.self

        guard let id = self[schema.id] as? String,
                let title = self[schema.title] as? String,
                let content = self[schema.content] as? String,
                let attributes = self[schema.attributes] as? Data,
                let categoryReferences = self[schema.categoryRecordNames] as? [CKReference] else {return nil}
        
        let data = NSMutableData()
        let coder = NSKeyedArchiver.init(forWritingWith: data)
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
        newNoteModel.categoryRecordNames = categoryReferences.map {$0.recordID.recordName}.joined(separator: "!")
        //TODO: add count property of categoryRecordNames

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
