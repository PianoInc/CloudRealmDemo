//
//  ContactAttachment.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 28..
//  Copyright © 2018년 piano. All rights reserved.
//

import InteractiveTextEngine_iOS

class ContactAttachment: InteractiveTextAttachment {
    var contact: String!
    
    override init() {
        super.init()
    }
    
    init(attribute: ContactAttribute) {
        super.init()
        self.contact = attribute.contact
        self.currentSize = attribute.size
    }
    
    init(attachment: ContactAttachment) {
        super.init(attachment: attachment)
        self.contact = attachment.contact
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func getCopyForDragInteraction() -> InteractiveTextAttachment {
        return ContactAttachment(attachment: self)
    }
}
