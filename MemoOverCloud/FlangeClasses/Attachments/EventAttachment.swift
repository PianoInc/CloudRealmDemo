//
//  ScheduleAttachment.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 28..
//  Copyright © 2018년 piano. All rights reserved.
//

import InteractiveTextEngine_iOS
import EventKit

class EventAttachment: InteractiveTextAttachment {
    var event: EKEvent!
    
    override init() {
        super.init()
    }
    
    init(attribute: EventAttribute) {
        super.init()
        self.event = attribute.event
        self.currentSize = attribute.size
    }
    
    init(attachment: EventAttachment) {
        super.init(attachment: attachment)
        self.event = attachment.event
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func getCopyForDragInteraction() -> InteractiveTextAttachment {
        return EventAttachment(attachment: self)
    }
}
