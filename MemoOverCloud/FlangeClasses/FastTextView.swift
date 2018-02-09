//
//  FastTextView.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 5..
//  Copyright © 2018년 piano. All rights reserved.
//

import FlangeTextEngine
import UIKit

class FastTextView: FlangeTextView {

    var memo: RealmNoteModel!

    var unmarkedString: NSAttributedString {
        get {
            let attributedString = NSMutableAttributedString(attributedString: self.textStorage)
            
            textStorage.enumerateAttributes(in: NSMakeRange(0, attributedString.length), options: .reverse) { (dic, range, _) in
                if let attachment = dic[NSAttributedStringKey.attachment] as? FastTextAttachment {
                    attributedString.removeAttribute(.attachment, range: range)
                    attributedString.replaceCharacters(in: range, with: attachment.imageTag.getTagString())
                }
            }
            
            return attributedString
        } set {
            let newAttributedString = NSMutableAttributedString(attributedString: newValue)
            
            let tagRanges = newValue.getTagRanges()
                
            
            //Add place holder attributes to `enumerate attachment`
            tagRanges.forEach {
                let attachment = NSTextAttachment()
                attachment.contents = $0.1.data(using: .utf8)
                newAttributedString.addAttribute(.attachment, value: attachment, range: $0.0)
            }
            
            //Replace placeholder attachments to real attachment
            newAttributedString.enumerateAttribute(.attachment, in: NSMakeRange(0, newAttributedString.length), options: [.longestEffectiveRangeNotRequired, .reverse]) { (value, range, _) in
                if let attachment = value as? NSTextAttachment, let data = attachment.contents {
                    guard let tagString = String(data: data, encoding: .utf8),
                        let imageTag = ImageTag(tagString: tagString), imageTag.identifier.hasPrefix(memo.id) else {return}
                    
                    newAttributedString.removeAttribute(.attachment, range: range)
                    guard let newAttachment = dequeueAttachment() as? FastTextAttachment else {return}
                    
                    newAttachment.imageTag = imageTag
                    let attachmentString = NSAttributedString(attachment: newAttachment)
                    
                    newAttributedString.replaceCharacters(in: range, with: attachmentString)
                }
            }
            
            attributedText = newAttributedString

        }
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
