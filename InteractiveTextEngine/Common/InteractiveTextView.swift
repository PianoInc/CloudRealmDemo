//
//  InteractiveTextView.swift
//  InteractiveTextEngine
//
//  Created by 김범수 on 2018. 3. 22..
//

import Foundation

extension InteractiveTextView {

    func add(_ attachment: InteractiveTextAttachment) {
        dispatcher.add(attachment: attachment)
    }

    func remove(attachmentID: String) {
        dispatcher.remove(attachmentID: attachmentID)
    }

    open func register(nib: UINib?, forCellReuseIdentifier identifier: String) {
        dispatcher.register(nib: nib, forCellReuseIdentifier: identifier)
    }
    open func dequeueReusableCell(withIdentifier identifier: String) -> InteractiveAttachmentCell {
        return dispatcher.dequeueReusableCell(withIdentifier: identifier)
    }
}

public protocol InteractiveTextViewDataSource: AnyObject {
    func textView(_ textView: InteractiveTextView, attachmentForCell attachment: InteractiveTextAttachment) -> InteractiveAttachmentCell
}

@objc public protocol InteractiveTextViewDelegate: AnyObject {
    @objc optional func textView(_ textView: InteractiveTextView, willDisplay: InteractiveAttachmentCell)
    @objc optional func textView(_ textView: InteractiveTextView, didDisplay: InteractiveAttachmentCell)
    @objc optional func textView(_ textView: InteractiveTextView, willEndDisplaying: InteractiveAttachmentCell)
    @objc optional func textView(_ textView: InteractiveTextView, didEndDisplaying: InteractiveAttachmentCell)
}
