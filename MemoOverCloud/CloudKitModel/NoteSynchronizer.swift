//
// Created by 김범수 on 2018. 3. 15..
// Copyright (c) 2018 piano. All rights reserved.
//

import Foundation
import CloudKit
import RealmSwift

class NoteSynchronizer {

    let recordName: String
    let id: String
    let isShared: Bool
    let textView: FastTextView

    init(textView: FastTextView) {
        self.recordName = textView.memo.recordName
        self.id = textView.memo.id
        self.isShared = textView.memo.isShared
        self.textView = textView
    }

    private func sync(with blocks: [Diff3Block], and attributedString: NSAttributedString) {
        var offset = 0

        blocks.forEach {
            switch $0 {
                case .add(let index, let range):
                    let replacement = attributedString.attributedSubstring(from: range)
                    insert(replacement, at: index+offset)
                    offset += range.length
                case .delete(let range):
                    delete(in: NSMakeRange(range.location + offset, range.length))
                    offset -= range.length
                case .change(_, let myRange, let serverRange):
                    let replacement = attributedString.attributedSubstring(from: serverRange)
                    replace(in: NSMakeRange(myRange.location + offset, myRange.length), with: replacement)
                    offset += serverRange.length - myRange.length
                default: break
            }
        }



    }

    private func sync(with blocks: [Diff3Block], and attributedString: NSAttributedString, serverRecord: CKRecord) {
        sync(with: blocks, and: attributedString)

        DispatchQueue.main.sync { [weak self] in
            guard let attributedString = self?.textView.attributedText else {
                return
            }
            let (content, attributes) = attributedString.getStringWithPianoAttributes()
            let attributeData = (try? JSONEncoder().encode(attributes)) ?? Data()

            serverRecord[Schema.Note.content] = content as CKRecordValue
            serverRecord[Schema.Note.attributes] = attributeData as CKRecordValue
        }
    }


    private func insert(_ attributedString: NSAttributedString, at index: Int) {
        DispatchQueue.main.sync { [weak self] in
            self?.textView.textStorage.insert(attributedString, at: index)
        }
    }

    private func delete(in range: NSRange) {
        DispatchQueue.main.sync { [weak self] in
            self?.textView.textStorage.deleteCharacters(in: range)
        }
    }

    private func replace(in range: NSRange, with attributedString: NSAttributedString) {
        DispatchQueue.main.sync { [weak self] in
            self?.textView.textStorage.replaceCharacters(in: range, with: attributedString)
        }
    }

    func registerToCloud() {
        let database = isShared ? CloudManager.shared.sharedDatabase : CloudManager.shared.privateDatabase

        database.registerSynchronizer(self)
    }

    func unregisterFromCloud() {
        let database = isShared ? CloudManager.shared.sharedDatabase : CloudManager.shared.privateDatabase

        database.unregisterSynchronizer(recordName: recordName)
    }

    func serverContentChanged(_ record: CKRecord) {
        guard let noteModel = record.parseNoteRecord() else {return}

        if let realm = try? Realm(),
            let oldNote = realm.object(ofType: RealmNoteModel.self, forPrimaryKey: noteModel.id) {

            textView.isSyncing = true
            if oldNote.content != noteModel.content {
                let oldContent = oldNote.content
                let serverContent = noteModel.content
                DispatchQueue.main.sync {
                    let currentString = textView.textStorage.string
                    
                    DispatchQueue.global(qos: .utility).async { [weak self] in
                        let serverAttributesData = noteModel.attributes
                        let serverAttributes = try! JSONDecoder().decode([PianoAttribute].self, from: serverAttributesData)
                        let serverAttributedString = NSMutableAttributedString(string: noteModel.content)
                        serverAttributes.forEach { serverAttributedString.add(attribute: $0) }
                        
                        let diff3Maker = Diff3Maker(ancestor: oldContent, a: currentString, b: serverContent)
                        let diff3Chunks = diff3Maker.mergeInLineLevel().flatMap { chunk -> [Diff3Block] in
                            if case let .change(oRange, aRange, bRange) = chunk {
                                let oString = oldContent.substring(with: oRange)
                                let aString = currentString.substring(with: aRange)
                                let bString = serverContent.substring(with: bRange)
                                
                                let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: "")
                                return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
                                
                            } else if case let .conflict(oRange, aRange, bRange) = chunk {
                                let oString = oldContent.substring(with: oRange)
                                let aString = currentString.substring(with: aRange)
                                let bString = serverContent.substring(with: bRange)
                                
                                let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: "")
                                return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
                            } else { return [chunk] }
                        }
                        
                        self?.sync(with: diff3Chunks, and: serverAttributedString)
                    }
                }
                

                

            } else if oldNote.attributes != noteModel.attributes {
                //TODO: attribute sync logic!!
                //Use both substraction
            }
            textView.isSyncing = false
        }
    }

    func resolveConflict(myRecord: CKRecord, serverRecord: CKRecord, completion: @escaping  (Bool) -> ()) {
        
        let myContent = myRecord[Schema.Note.content] as! String
        let serverContent = serverRecord[Schema.Note.content] as! String

        let myAttributesData = myRecord[Schema.Note.attributes] as! Data
        let serverAttributesData = serverRecord[Schema.Note.attributes] as! Data

        let serverAttributes = try! JSONDecoder().decode([PianoAttribute].self, from: serverAttributesData)

        let serverAttributedString = NSMutableAttributedString(string: serverContent)
        serverAttributes.forEach { serverAttributedString.add(attribute: $0) }

        textView.isSyncing = true
        
        

        if myContent != serverContent {
            DispatchQueue.main.sync {
                let currentString = self.textView.textStorage.string
                
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    let diff3Maker = Diff3Maker(ancestor: myContent, a: currentString, b: serverContent)
                    let diff3Chunks = diff3Maker.mergeInLineLevel().flatMap { chunk -> [Diff3Block] in
                        if case let .change(oRange, aRange, bRange) = chunk {
                            let oString = myContent.substring(with: oRange)
                            let aString = currentString.substring(with: aRange)
                            let bString = serverContent.substring(with: bRange)
                            
                            let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: "")
                            return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
                            
                        } else if case let .conflict(oRange, aRange, bRange) = chunk {
                            let oString = myContent.substring(with: oRange)
                            let aString = currentString.substring(with: aRange)
                            let bString = serverContent.substring(with: bRange)
                            
                            let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: "")
                            return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
                        } else { return [chunk] }
                    }
                    
                    self?.sync(with: diff3Chunks, and: serverAttributedString, serverRecord: serverRecord)
                    self?.textView.isSyncing = false
                    completion(true)
                }
            }
        } else if myAttributesData != serverAttributesData {
            //Let's just union it

            textView.isSyncing = false
            completion(true)
        } else {
            textView.isSyncing = false
            completion(false)
        }
    }

    func saveContent(completion: ((Error?) -> Void)?) {
        let (text, pianoAttributes) = textView.attributedText.getStringWithPianoAttributes()
        let attributeData = (try? JSONEncoder().encode(pianoAttributes)) ?? Data()

        let localRecord = textView.memo.getRecord()
        localRecord[Schema.Note.content] = text as CKRecordValue
        localRecord[Schema.Note.attributes] = attributeData as CKRecordValue

        let uploadFunc: (CKRecord, @escaping ((CKRecord?, Error?) -> Void)) -> () = isShared ?
                CloudManager.shared.uploadRecordToSharedDB :
                CloudManager.shared.uploadRecordToPrivateDB

        uploadFunc(localRecord) { _, error in
            guard error == nil else { return completion?(error!) ?? () }
        }
    }
}
