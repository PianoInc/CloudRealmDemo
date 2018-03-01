//
//  ConflictResolver.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 28..
//  Copyright © 2018년 piano. All rights reserved.
//

import CloudKit

class ConflictResolver {
    static func merge(ancestor: CKRecord, myRecord: CKRecord, serverRecord: CKRecord) -> Bool {
        guard let myModified = myRecord.modificationDate,
              let serverModified = serverRecord.modificationDate else {return false}


        if myModified.compare(serverModified) == .orderedDescending {
            //my Win!
            switch ancestor.recordType {
                case RealmCategoryModel.recordTypeString:
                    serverRecord[Schema.Category.name] = myRecord[Schema.Category.name]

                case RealmNoteModel.recordTypeString:
                    serverRecord[Schema.Note.title] = myRecord[Schema.Note.title]

                    //TODO: add attribute to merge
                    let ancestorContent = ancestor[Schema.Note.content] as! String
                    let myContent = myRecord[Schema.Note.content] as! String
                    let serverContent = serverRecord[Schema.Note.content] as! String
                    serverRecord[Schema.Note.content] = Diff3.merge(ancestor: ancestorContent, a: myContent, b: serverContent) as CKRecordValue

                    serverRecord[Schema.Note.categoryRecordName] = myRecord[Schema.Note.categoryRecordName]

                case RealmCategoryForSharedModel.recordTypeString:
                    serverRecord[Schema.categoryForSharedNote.CategoryRecordName] = myRecord[Schema.categoryForSharedNote.CategoryRecordName]

                default: break
            }
            return true
        } else {
            //server Win!
            return false
        }
    }
}
