//
//  FastTextView.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 5..
//  Copyright © 2018년 piano. All rights reserved.
//

import FastLayoutTextEngine
import UIKit

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
