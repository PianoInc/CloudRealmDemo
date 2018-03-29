//
//  ReminderAttachment.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 29..
//  Copyright © 2018년 piano. All rights reserved.
//

import InteractiveTextEngine_iOS
import EventKit

class ReminderAttachment: InteractiveTextAttachment {
    var reminder: EKReminder!
    
    override init() {
        super.init()
    }
    
    init(attribute: ReminderAttribute) {
        super.init()
        self.reminder = attribute.reminder
        self.currentSize = attribute.size
    }
    init(attachment: ReminderAttachment) {
        super.init(attachment: attachment)
        self.reminder = attachment.reminder
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func getCopyForDragInteraction() -> InteractiveTextAttachment {
        return ReminderAttachment(attachment: self)
    }
}
