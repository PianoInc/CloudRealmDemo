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

    private func insert(_ attributedString: NSAttributedString, at index: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.textView.textStorage.insert(attributedString, at: index)
        }
    }

    private func delete(in range: NSRange) {
        DispatchQueue.main.async { [weak self] in
            self?.textView.textStorage.deleteCharacters(in: range)
        }
    }

    private func replace(in range: NSRange, with attributedString: NSAttributedString) {
        DispatchQueue.main.async { [weak self] in
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
                let currentString = textView.text ?? ""

                let serverAttributesData = noteModel.attributes
                let serverAttributes = try! JSONDecoder().decode([PianoAttribute].self, from: serverAttributesData)
                let serverAttributedString = NSMutableAttributedString(string: noteModel.content)
                serverAttributes.forEach { serverAttributedString.add(attribute: $0) }

                let diff3Chunks = Diff3.merge(ancestor: oldNote.content, a: currentString, b: noteModel.content)
                //TODO: diff again with word level!!

                sync(with: diff3Chunks, and: serverAttributedString)

            } else if oldNote.attributes != noteModel.attributes {
                //TODO: attribute sync logic!!
            }
            textView.isSyncing = false
        }
    }

    func resolveConflict(myRecord: CKRecord, serverRecord: CKRecord) -> Bool {
        //TODO: make change to serverRecord & apply it
        let myContent = myRecord[Schema.Note.content] as! String
        let serverContent = serverRecord[Schema.Note.content] as! String

        let myAttributesData = myRecord[Schema.Note.attributes] as! Data
        let serverAttributesData = serverRecord[Schema.Note.attributes] as! Data

        if myContent != serverContent {

        } else if myAttributesData != serverAttributesData {

        } else {
            return false
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
