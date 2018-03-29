//
//  ReminderAttribute.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 29..
//  Copyright © 2018년 piano. All rights reserved.
//

import EventKit

struct ReminderAttribute {
    let reminder: EKReminder
    let size: CGSize
}

extension ReminderAttribute: Hashable {
    static func ==(lhs: ReminderAttribute, rhs: ReminderAttribute) -> Bool {
        return lhs.reminder == rhs.reminder && lhs.size == rhs.size
    }
    
    var hashValue: Int {
        return reminder.hashValue ^ size.width.hashValue ^ size.height.hashValue &* 16777619
    }
}

extension ReminderAttribute: Codable {
    
    private enum DecodeError: Error {
        case decodingFailed
    }
    
    private enum CodingKeys: CodingKey {
        case reminder
        case size
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let reminderData = try values.decode(Data.self, forKey: .reminder)
        guard let reminderFromData = NSKeyedUnarchiver.unarchiveObject(with: reminderData) as? EKReminder
            else { throw DecodeError.decodingFailed }
        reminder = reminderFromData
        size = try values.decode(CGSize.self, forKey: .size)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let encodedReminder = NSKeyedArchiver.archivedData(withRootObject: reminder)
        try container.encode(encodedReminder, forKey: .reminder)
        try container.encode(size, forKey: .size)
    }
}

