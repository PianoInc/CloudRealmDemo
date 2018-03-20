//
//  ConflictResolver.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 28..
//  Copyright © 2018년 piano. All rights reserved.
//

import CloudKit

extension CloudCommonDatabase {
    func merge(ancestor: CKRecord, myRecord: CKRecord, serverRecord: CKRecord, completion: @escaping (Bool)->()) {
        guard let myModified = myRecord.modificationDate,
              let serverModified = serverRecord.modificationDate else {return}
 
        switch ancestor.recordType {
        case RealmNoteModel.recordTypeString:
            mergeNote(ancestor: ancestor, myRecord: myRecord, serverRecord: serverRecord, myModified: myModified, serverModified: serverModified, completion: completion)
            
        case RealmCategoryModel.recordTypeString:
            
            if myModified.compare(serverModified) == .orderedDescending {
                serverRecord[Schema.Category.name] = myRecord[Schema.Category.name]
                completion(true)
            } else {
                completion(false)
            }
        default: break
        }

        
    }
    
    private func mergeNote(ancestor: CKRecord, myRecord: CKRecord, serverRecord: CKRecord, myModified: Date, serverModified: Date, completion: @escaping (Bool) -> ()) {

        if let synchronizer = synchronizers[myRecord.recordID.recordName] {
            //DO diff3 here with ancestor: myrecord, a: textView.text b: b
            synchronizer.resolveConflict(myRecord: myRecord, serverRecord: serverRecord, completion: completion)
            return
        }
        

        if myModified.compare(serverModified) == .orderedDescending {

            if let serverTitle = serverRecord[Schema.Note.title] as? String,
                    let myTitle = myRecord[Schema.Note.title] as? String,
                    serverTitle != myTitle {

                serverRecord[Schema.Note.title] = myRecord[Schema.Note.title]
                completion(true)
                return
            }

            if let serverCategory = serverRecord[Schema.Note.categoryRecordName] as? String,
                    let myCategory = myRecord[Schema.Note.categoryRecordName] as? String,
                    serverCategory != myCategory {

                serverRecord[Schema.Note.categoryRecordName] = myRecord[Schema.Note.categoryRecordName]
                completion(true)
                return
            }

        }
        
        completion(false)
    }

}
