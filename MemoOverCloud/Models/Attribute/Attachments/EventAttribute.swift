//
//  EventAttribute.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 29..
//  Copyright © 2018년 piano. All rights reserved.
//

import EventKit

struct EventAttribute {
    let event: EKEvent
    let size: CGSize
}

extension EventAttribute: Hashable {
    static func ==(lhs: EventAttribute, rhs: EventAttribute) -> Bool {
        return lhs.event == rhs.event && lhs.size == rhs.size
    }
    
    var hashValue: Int {
        return event.hashValue ^ size.width.hashValue ^ size.height.hashValue &* 16777619
    }
}

extension EventAttribute: Codable {
    
    private enum DecodeError: Error {
        case decodingFailed
    }
    
    private enum CodingKeys: CodingKey {
        case event
        case size
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let eventData = try values.decode(Data.self, forKey: .event)
        guard let eventFromData = NSKeyedUnarchiver.unarchiveObject(with: eventData) as? EKEvent
            else { throw DecodeError.decodingFailed }
        event = eventFromData
        size = try values.decode(CGSize.self, forKey: .size)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let encodedEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        try container.encode(encodedEvent, forKey: .event)
        try container.encode(size, forKey: .size)
    }
}
