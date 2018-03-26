//
//  InteractiveTextStorage.swift
//  InteractiveTextEngine
//
//  Created by 김범수 on 2018. 3. 23..
//

import UIKit

class InteractiveTextStorage: NSTextStorage {

    weak var textView: InteractiveTextView?
    
    private let backingStore = NSMutableAttributedString()
    
    override var string: String {
        return backingStore.string
    }
    
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedStringKey : Any] {
        return backingStore.attributes(at: location, effectiveRange: range)
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        attachmentChanged(deletedRange: range)
        
        beginEditing()
        backingStore.replaceCharacters(in: range, with:str)
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: str.count - range.length)
        
        endEditing()
    }
    
    override func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        attachmentChanged(deletedRange: range, newAttString: attrString)
        
        beginEditing()
        backingStore.replaceCharacters(in: range, with:attrString)
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: attrString.length - range.length)
        
        endEditing()
    }
    
    override func addAttribute(_ name: NSAttributedStringKey, value: Any, range: NSRange) {
        if name == .attachment, let attachment = value as? InteractiveTextAttachment {
            textView?.add(attachment)
            
        }
        
        beginEditing()
        backingStore.addAttribute(name, value: value, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    override func addAttributes(_ attrs: [NSAttributedStringKey : Any] = [:], range: NSRange) {
        if let attachment = attrs[.attachment] as? InteractiveTextAttachment {
            textView?.add(attachment)
            attachmentChanged(deletedRange: range)
        }
        
        beginEditing()
        backingStore.addAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    override func append(_ attrString: NSAttributedString) {
        attachmentChanged(newAttString: attrString)
        
        beginEditing()
        let index = backingStore.length
        backingStore.append(attrString)
        edited([.editedAttributes,.editedCharacters], range: NSMakeRange(index, 0), changeInLength: attrString.length)
        endEditing()
    }
    
    override func insert(_ attrString: NSAttributedString, at loc: Int) {
        attachmentChanged(newAttString: attrString)
        
        beginEditing()
        backingStore.insert(attrString, at: loc)
        edited([.editedAttributes,.editedCharacters], range: NSMakeRange(loc, 0), changeInLength: attrString.length)
        endEditing()
    }
    
    override func deleteCharacters(in range: NSRange) {
        attachmentChanged(deletedRange: range)
        
        beginEditing()
        backingStore.deleteCharacters(in: range)
        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: -range.length)
        endEditing()
    }
    
    override func removeAttribute(_ name: NSAttributedStringKey, range: NSRange) {
        if name == .attachment {attachmentChanged(deletedRange: range)}
        
        beginEditing()
        backingStore.removeAttribute(name, range: range)
        edited([.editedAttributes], range: range, changeInLength: 0)
        endEditing()
    }
    
    
    
    override func setAttributes(_ attrs: [NSAttributedStringKey : Any]?, range: NSRange) {
        if let attachment = attrs?[.attachment] as? InteractiveTextAttachment {
            textView?.add(attachment)
        }
        
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    private func attachmentChanged(deletedRange: NSRange? = nil, newAttString: NSAttributedString? = nil) {
        if let deletedRange = deletedRange {
            enumerateAttribute(.attachment, in: deletedRange, options: .longestEffectiveRangeNotRequired) { (value, _, _) in
                guard let attachment = value as? InteractiveTextAttachment else {return}
                self.textView?.remove(attachmentID: attachment.uniqueID)
            }
        }

        if let newAttString = newAttString {
            newAttString.enumerateAttribute(.attachment, in: NSMakeRange(0, newAttString.length)
            , options: .longestEffectiveRangeNotRequired) { (value, _, _) in
                guard let attachment = value as? InteractiveTextAttachment else {return}
                self.textView?.add(attachment)
            }
        }
    }
}
