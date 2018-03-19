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

        switch ancestor.recordType {
        case RealmNoteModel.recordTypeString:
            return mergeNote(ancestor: ancestor, myRecord: myRecord, serverRecord: serverRecord, myModified: myModified, serverModified: serverModified)
            
        case RealmCategoryModel.recordTypeString:
            
            if myModified.compare(serverModified) == .orderedDescending {
                serverRecord[Schema.Category.name] = myRecord[Schema.Category.name]
            }
            
        default: break
        }

        return myModified.compare(serverModified) == .orderedDescending
    }
    
    private static func mergeNote(ancestor: CKRecord, myRecord: CKRecord, serverRecord: CKRecord, myModified: Date, serverModified: Date) -> Bool {
        var flag = false
        if serverRecord.changedKeys().contains(Schema.Note.content) ||
            serverRecord.changedKeys().contains(Schema.Note.attributes) {
            
            flag = true
            
            let ancestorContent = ancestor[Schema.Note.content] as! String
            
            let myContent = myRecord[Schema.Note.content] as! String
            let serverContent = serverRecord[Schema.Note.content] as! String
            
            let myAttributesData = myRecord[Schema.Note.attributes] as! Data
            let myAttributes = try! JSONDecoder().decode([PianoAttribute].self, from: myAttributesData)
            
            let serverAttributesData = serverRecord[Schema.Note.attributes] as! Data
            let serverAttributes = try! JSONDecoder().decode([PianoAttribute].self, from: serverAttributesData)
            
            let myAttributedString = NSMutableAttributedString(string: myContent)
            myAttributes.forEach {myAttributedString.add(attribute: $0)}
            
            let serverAttributedString = NSMutableAttributedString(string: serverContent)
            serverAttributes.forEach {serverAttributedString.add(attribute: $0)}
            
            let chunks = Diff3.merge(ancestor: ancestorContent, a: myContent, b: serverContent)
            chunks.forEach {
                switch $0 {
                //TODO: make Notification here
                case .conflict(let original, let my, let server, let myRange, let serverRange):
                    //resolve conflict if possible
                    
                    if my == server { //false conflict
                        return
                    } else if my == original { //server add
                        let replacementString = serverAttributedString.attributedSubstring(from: serverRange)
                        myAttributedString.replaceCharacters(in: myRange, with: replacementString)
                    } else if server == original{ //my add
                        return
                    } else {
                        //true conflict!!
                        let myReplacementString = myAttributedString.attributedSubstring(from: myRange)
                        let serverReplacementString = serverAttributedString.attributedSubstring(from: serverRange)
                        
                        let conflictString = NSMutableAttributedString(string: "!@#$ Conflict!!\nMy\n========================\n")
                        
                        conflictString.append(myReplacementString)
                        conflictString.append(NSAttributedString(string: "\nServer\n========================\n"))
                        conflictString.append(serverReplacementString)
                        conflictString.append(NSAttributedString(string: "\n========================\n"))
                        
                        myAttributedString.replaceCharacters(in: myRange, with: conflictString)
                    }
                    
                default: break
                }
            }
            
            var attributes:[PianoAttribute] = []
            
            myAttributedString.enumerateAttributes(in: NSMakeRange(0, myAttributedString.length), options: .reverse) { (dic, range, _) in
                for (key, value) in dic {
                    if let pianoAttribute = PianoAttribute(range: range, attribute: (key, value)) {
                        attributes.append(pianoAttribute)
                    }
                }
            }
            
            serverRecord[Schema.Note.content] = myAttributedString.string as CKRecordValue
            serverRecord[Schema.Note.attributes] = ((try? JSONEncoder().encode(attributes)) ?? Data()) as CKRecordValue
        }
        
        
        if myModified.compare(serverModified) == .orderedDescending {
            flag = true
            serverRecord[Schema.Note.title] = myRecord[Schema.Note.title]
            serverRecord[Schema.Note.categoryRecordName] = myRecord[Schema.Note.categoryRecordName]
        }
        
        return flag
    }
    
}
