//
//  LinkAttachment.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 28..
//  Copyright © 2018년 piano. All rights reserved.
//

import InteractiveTextEngine_iOS

class LinkAttachment: InteractiveTextAttachment {
    var link: String!
    
    override init() {
        super.init()
    }
    
    init(attribute: LinkAttribute) {
        super.init()
        self.link = attribute.link
        self.currentSize = attribute.size
    }
    
    init(attachment: LinkAttachment) {
        super.init(attachment: attachment)
        self.link = attachment.link
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func getCopyForDragInteraction() -> InteractiveTextAttachment {
        return LinkAttachment(attachment: self)
    }
}
