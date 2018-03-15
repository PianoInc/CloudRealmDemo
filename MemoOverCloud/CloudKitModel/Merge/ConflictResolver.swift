//
//  ConflictResolver.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 28..
//  Copyright © 2018년 piano. All rights reserved.
//

import CloudKit

extension CloudCommonDatabase {
    func merge(ancestor: CKRecord, myRecord: CKRecord, serverRecord: CKRecord) -> Bool {
        guard let myModified = myRecord.modificationDate,
              let serverModified = serverRecord.modificationDate else {return false}

        switch ancestor.recordType {
        case RealmNoteModel.recordTypeString:
            return mergeNote(ancestor: ancestor, myRecord: myRecord, serverRecord: serverRecord, myModified: myModified, serverModified: serverModified)
            
        case RealmCategoryModel.recordTypeString:
            
            if myModified.compare(serverModified) == .orderedDescending {
                serverRecord[Schema.Category.name] = myRecord[Schema.Category.name]
            }
            
        case RealmCategoryForSharedModel.recordTypeString:
            
            if myModified.compare(serverModified) == .orderedDescending {
                serverRecord[Schema.categoryForSharedNote.CategoryRecordName] = myRecord[Schema.categoryForSharedNote.CategoryRecordName]
            }
        
        default: break
        }

        return myModified.compare(serverModified) == .orderedDescending
    }
    
    private func mergeNote(ancestor: CKRecord, myRecord: CKRecord, serverRecord: CKRecord, myModified: Date, serverModified: Date) -> Bool {
        
        var flag = false

        if let synchronizer = synchronizers[myRecord.recordID.recordName] {
            //DO diff3 here with ancestor: myrecord, a: textView.text b: b
            flag = synchronizer.resolveConflict(myRecord: myRecord, serverRecord: serverRecord)
        }
        

        if myModified.compare(serverModified) == .orderedDescending {
            if let serverTitle = serverRecord[Schema.Note.title] as? String,
                    let myTitle = myRecord[Schema.Note.title] as? String,
                    serverTitle != myTitle {

                flag = true
                serverRecord[Schema.Note.title] = myRecord[Schema.Note.title]

            }

            if let serverCategory = serverRecord[Schema.Note.categoryRecordName] as? String,
                    let myCategory = myRecord[Schema.Note.categoryRecordName] as? String,
                    serverCategory != myCategory {

                flag = true
                serverRecord[Schema.Note.categoryRecordName] = myRecord[Schema.Note.categoryRecordName]
            }
        }
        
        return flag
    }

}
