//
//  AddressAttachment.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 28..
//  Copyright © 2018년 piano. All rights reserved.
//

import InteractiveTextEngine_iOS

class AddressAttachment: InteractiveTextAttachment {
    var address: String!
    
    override init() {
        super.init()
    }
    
    init(attribute: AddressAttribute) {
        super.init()
        self.address = attribute.address
        self.currentSize = attribute.size
    }
    
    init(attachment: AddressAttachment) {
        super.init(attachment: attachment)
        self.address = attachment.address
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func getCopyForDragInteraction() -> InteractiveTextAttachment {
        return AddressAttachment(attachment: self)
    }
}
