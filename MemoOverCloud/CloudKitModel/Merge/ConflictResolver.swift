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
            
        case RealmCategoryForSharedModel.recordTypeString:
            
            if myModified.compare(serverModified) == .orderedDescending {
                serverRecord[Schema.categoryForSharedNote.CategoryRecordName] = myRecord[Schema.categoryForSharedNote.CategoryRecordName]
            }
        
        default: break
        }

        return myModified.compare(serverModified) == .orderedDescending
    }
    
    private static func mergeNote(ancestor: CKRecord, myRecord: CKRecord, serverRecord: CKRecord, myModified: Date, serverModified: Date) -> Bool {
        
        var flag = false
        
        let ancestorContent = ancestor[Schema.Note.content] as? String ?? ""
        let myContent = myRecord[Schema.Note.content] as! String
        let serverContent = serverRecord[Schema.Note.content] as! String
        
        
        
        let myAttributesData = myRecord[Schema.Note.attributes] as! Data
        let myAttributes = try! JSONDecoder().decode([PianoAttribute].self, from: myAttributesData)
        
        let serverAttributesData = serverRecord[Schema.Note.attributes] as! Data
        let serverAttributes = try! JSONDecoder().decode([PianoAttribute].self, from: serverAttributesData)
        
        if myContent.hashValue != serverContent.hashValue || myAttributesData.hashValue != serverAttributesData.hashValue {
            flag = true
            
            let myAttributedString = NSMutableAttributedString(string: myContent)
            myAttributes.forEach {myAttributedString.add(attribute: $0)}
            
            let serverAttributedString = NSMutableAttributedString(string: serverContent)
            serverAttributes.forEach {serverAttributedString.add(attribute: $0)}
            
            //TODO; notify
            let chunks = Diff3.merge(ancestor: ancestorContent, a: myContent, b: serverContent)
            _ = chunks.reduce(0) { offset, diff3Chunk -> Int in
                var currentOffset = offset
                switch diff3Chunk {
                    case .add(let index, let serverRange):
                        let replaceString = serverAttributedString.attributedSubstring(from: serverRange)
                        myAttributedString.insert(replaceString, at: index + currentOffset)
                        currentOffset += serverRange.length
                    
                    case .delete(let range):
                        myAttributedString.deleteCharacters(in: NSMakeRange(range.location + currentOffset, range.length))
                        currentOffset -= range.length
                    
                    case .change(let myRange, let serverRange):
                        let replaceString = serverAttributedString.attributedSubstring(from: serverRange)
                        myAttributedString.replaceCharacters(in: NSMakeRange(myRange.location + currentOffset, myRange.length), with: replaceString)
                        currentOffset += serverRange.length - myRange.length
                    
                    case .conflict(let myRange, let serverRange):
                        let replaceString = serverAttributedString.attributedSubstring(from: serverRange)
                        let myReplaceString = myAttributedString.attributedSubstring(from: myRange)
                    
                        let conflictString = NSMutableAttributedString(string: "************************\nmy\n************************\n")
                        conflictString.append(myReplaceString)
                        conflictString.append(NSAttributedString(string: "server\n************************\n"))
                        conflictString.append(replaceString)
                        conflictString.append(NSAttributedString(string: "\n************************\n"))
                    
                        myAttributedString.replaceCharacters(in: NSMakeRange(myRange.location + currentOffset, myRange.length), with: conflictString)
                    
                        currentOffset += conflictString.length - myRange.length
                }
                
                return currentOffset
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
