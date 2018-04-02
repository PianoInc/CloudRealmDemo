//
//  FastTextView.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 5..
//  Copyright © 2018년 piano. All rights reserved.
//

import InteractiveTextEngine_iOS
import UIKit
import RealmSwift
import MobileCoreServices

class FastTextView: InteractiveTextView {

    var memo: RealmNoteModel!
    var isSyncing = false
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

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

        let selectedAttributedString = NSMutableAttributedString(attributedString: self.attributedText.attributedSubstring(from: selectedRange))

        selectedAttributedString.enumerateAttribute(.attachment, in: NSMakeRange(0, selectedAttributedString.length),
                options: .longestEffectiveRangeNotRequired) { value, range, _ in
            if let attachment = value as? ImageAttachment,
                let imageModel = realm.object(ofType: RealmImageModel.self, forPrimaryKey: attachment.imageID),
                let image = UIImage(data: imageModel.image) {
                
                let resizedImage: UIImage!
                if image.size.width > UIScreen.main.bounds.width {
                    let width = UIScreen.main.bounds.width / 2
                    let height = image.size.height * width / image.size.width
                    resizedImage = image.resizeImage(size: CGSize(width: width, height: height)) ?? UIImage()
                } else {
                    resizedImage = image
                }
                

                let newAttachment = NSTextAttachment()
                newAttachment.image = resizedImage

                let replacement = NSAttributedString(attachment: newAttachment)

                selectedAttributedString.replaceCharacters(in: range, with: replacement)
            }
        }

        let data = (try? selectedAttributedString.data(from: NSMakeRange(0, selectedAttributedString.length)
                , documentAttributes:[.documentType: NSAttributedString.DocumentType.rtfd])) ?? Data()



        let item:[String: Any] = [kUTTypeFlatRTFD as String: data,
                                  kUTTypeUTF8PlainText as String: selectedAttributedString.string]
        UIPasteboard.general.setItems([item], options: [:])

    }

    override func cut(_ sender: Any?) {
        copy(sender)
        self.textStorage.deleteCharacters(in: selectedRange)
    }

    override func paste(_ sender: Any?) {
        if let attrString = transformAttrStringFromPasteboard() {
            //when setting data transform it
            let pasteString = NSMutableAttributedString(attributedString: attrString)
            pasteString.enumerateAttributes(in: NSMakeRange(0, pasteString.length), options: .longestEffectiveRangeNotRequired, using: { (dic, range, _) in
                if let attachment = dic[.attachment] as? NSTextAttachment, let image = attachment.getImage() {
                    
                    let resizedImage: UIImage!
                    if image.size.width > UIScreen.main.bounds.width {
                        let width = UIScreen.main.bounds.width / 2
                        let height = image.size.height * width / image.size.width
                        resizedImage = image.resizeImage(size: CGSize(width: width, height: height)) ?? UIImage()
                    } else {
                        resizedImage = image
                    }

                    let newImageModel = RealmImageModel.getNewModel(noteRecordName: memo.recordName, image: resizedImage)
                    ModelManager.saveNew(model: newImageModel) { error in }


                    let newAttachment = ImageAttachment()
                    newAttachment.imageID = newImageModel.id
                    newAttachment.currentSize = resizedImage.size

                    let attachString = NSAttributedString(attachment: newAttachment)

                    pasteString.replaceCharacters(in: range, with: attachString)
                }
            })


            textStorage.replaceCharacters(in: selectedRange, with: pasteString)
        }
    }

    private func transformAttrStringFromPasteboard() -> NSAttributedString? {
        var attrString: NSAttributedString? = nil


        if let data = UIPasteboard.general.data(forPasteboardType: "com.apple.flat-rtfd") {

            do {
                attrString = try NSAttributedString(data: data, options: [.documentType:NSAttributedString.DocumentType.rtfd], documentAttributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        } else if let data = UIPasteboard.general.data(forPasteboardType: "com.apple/webarchive") {
            do {
                attrString = try NSAttributedString(data: data, options: [:], documentAttributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        } else if let data = UIPasteboard.general.data(forPasteboardType: "com.evernote.app.htmlData") {
            do {
                attrString = try NSAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        } else if let data = UIPasteboard.general.data(forPasteboardType: "Apple Web Archive pasteboard type") {
            do {
                attrString = try NSAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }

        return attrString
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
