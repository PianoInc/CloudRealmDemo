//
//  FastTextView.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 5..
//  Copyright © 2018년 piano. All rights reserved.
//

import FastLayoutTextEngine
import UIKit
import RealmSwift

class FastTextView: FlangeTextView {

    var memo: RealmNoteModel!
    var isSyncing = false


    func set(string: String, with attributes: [PianoAttribute]) {
        let newAttributedString = NSMutableAttributedString(string: string)
        attributes.forEach{ newAttributedString.add(attribute: $0) }

        attributedText = newAttributedString
    }

    func get() -> (string: String, attributes: [PianoAttribute]) {
        return attributedText.getStringWithPianoAttributes()
    }

}

extension FastTextView {
    func insertNewLineToLeftSideIfNeeded(location: Int){
        if location != 0 && attributedText.attributedSubstring(from: NSMakeRange(location - 1, 1)).string != "\n" {
            insertText("\n")
        }
    }
    
    func insertNewlineToRightSideIfNeeded(location: Int){
        if location < attributedText.length && attributedText.attributedSubstring(from: NSMakeRange(location, 1)).string != "\n" {
            insertText("\n")
        }
    }
}

extension FastTextView {
    override func copy(_ sender: Any?) {
        guard let realm = try? Realm() else {return}
        let pasteboard = UIPasteboard.general

        let selectedAttributedString = NSMutableAttributedString(attributedString: self.attributedText.attributedSubstring(from: selectedRange))

        selectedAttributedString.enumerateAttribute(.attachment, in: NSMakeRange(0, selectedAttributedString.length),
                options: .longestEffectiveRangeNotRequired) { value, range, _ in
            if let attachment = value as? FastTextAttachment,
                let imageModel = realm.object(ofType: RealmImageModel.self, forPrimaryKey: attachment.imageID),
                let image = UIImage(data: imageModel.image) {

                let newAttachment = NSTextAttachment()
                newAttachment.image = image

                let replacement = NSAttributedString(attachment: newAttachment)

                selectedAttributedString.replaceCharacters(in: range, with: replacement)
            }
        }

        let data = (try? selectedAttributedString.data(from: NSMakeRange(0, selectedAttributedString.length)
                , documentAttributes:[.documentType: NSAttributedString.DocumentType.rtf])) ?? Data()

        pasteboard.setData(data, forPasteboardType: "com.apple.flat-rtfd")

    }

    override func cut(_ sender: Any?) {
        copy(sender)
        self.textStorage.deleteCharacters(in: selectedRange)
    }

    override func paste(_ sender: Any?) {

    }

}

extension NSAttributedString {
    func getStringWithPianoAttributes() -> (string: String, attributes: [PianoAttribute]) {
        var attributes: [PianoAttribute] = []

         self.enumerateAttributes(in: NSMakeRange(0, self.length), options: .reverse) { (dic, range, _) in
            for (key, value) in dic {
                if let pianoAttribute = PianoAttribute(range: range, attribute: (key, value)) {
                    attributes.append(pianoAttribute)
                }
            }
        }

        return (string: self.string, attributes: attributes)
    }
}
