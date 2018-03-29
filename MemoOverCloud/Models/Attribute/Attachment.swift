//
//  Attachment.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 29..
//  Copyright © 2018년 piano. All rights reserved.
//

import InteractiveTextEngine_iOS

enum AttachmentAttribute {
    
    init?(attachment: InteractiveTextAttachment) {
        switch attachment {
        case let attachment as ImageAttachment:
            self = .image(ImageAttribute(id: attachment.imageID, size: attachment.currentSize))
        case let attachment as LinkAttachment:
            self = .link(LinkAttribute(link: attachment.link, size: attachment.currentSize))
        case let attachment as ContactAttachment:
            self = .contact(ContactAttribute(contact: attachment.contact, size: attachment.currentSize))
        case let attachment as EventAttachment:
            self = .event(EventAttribute(event: attachment.event, size: attachment.currentSize))
        case let attachment as ReminderAttachment:
            self = .reminder(ReminderAttribute(reminder: attachment.reminder, size: attachment.currentSize))
        default:
            return nil
        }
    }
    
    case image(ImageAttribute)
    case link(LinkAttribute)
    case address(AddressAttribute)
    case contact(ContactAttribute)
    case event(EventAttribute)
    case reminder(ReminderAttribute)
    
    func toNSAttribute() -> [NSAttributedStringKey: Any] {
        switch self {
        case .image(let imageAttribute):
            return [.attachment: ImageAttachment(attribute: imageAttribute)]
        case .link(let linkAttribute):
            return [.attachment: LinkAttachment(attribute: linkAttribute)]
        case .address(let addressAttribute):
            return [.attachment: AddressAttachment(attribute: addressAttribute)]
        case .contact(let contactAttribute):
            return [.attachment: ContactAttachment(attribute: contactAttribute)]
        case .event(let eventAttribute):
            return [.attachment: EventAttachment(attribute: eventAttribute)]
        case .reminder(let reminderAttribute):
            return [.attachment: ReminderAttachment(attribute: reminderAttribute)]
        }
    }
}

extension AttachmentAttribute: Hashable {
    var hashValue: Int {
        switch self {
        case .image(let imageAttribute): return imageAttribute.hashValue
        case .link(let linkAttribute): return linkAttribute.hashValue
        case .address(let addressAttribute): return addressAttribute.hashValue
        case .contact(let contactAttribute): return contactAttribute.hashValue
        case .event(let eventAttribute): return eventAttribute.hashValue
        case .reminder(let reminderAttribute): return reminderAttribute.hashValue
        }
    }
    
    static func ==(lhs: AttachmentAttribute, rhs: AttachmentAttribute) -> Bool {
        switch lhs {
        case .image(let imageAttribute):
            if case let .image(rImageAttriubte) = rhs {
                return imageAttribute == rImageAttriubte
            }
            return false
        case .link(let linkAttribute):
            if case let .link(rLinkAttribute) = rhs {
                return linkAttribute == rLinkAttribute
            }
            return false
        case .address(let addressAttribute):
            if case let .address(rAddressAttribute) = rhs {
                return addressAttribute == rAddressAttribute
            }
            return false
        case .contact(let contactAttribute):
            if case let .contact(rContactAttribute) = rhs {
                return contactAttribute == rContactAttribute
            }
            return false
        case .event(let eventAttribute):
            if case let .event(rEventAttribute) = rhs {
                return eventAttribute == rEventAttribute
            }
            return false
        case .reminder(let reminderAttribute):
            if case let .reminder(rReminderAttribute) = rhs {
                return reminderAttribute == rReminderAttribute
            }
            return false
        }
    }
}


extension AttachmentAttribute: Codable {
    
    private enum CodingKeys: CodingKey {
        case image
        case link
        case address
        case contact
        case event
        case reminder
    }
    
    enum CodingError: Error {
        case decoding(String)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let imageAttribute = try? values.decode(ImageAttribute.self, forKey: .image) {
            self = .image(imageAttribute)
            return
        }
        if let linkAttribute = try? values.decode(LinkAttribute.self, forKey: .link) {
            self = .link(linkAttribute)
            return
        }
        if let addressAttribute = try? values.decode(AddressAttribute.self, forKey: .address) {
            self = .address(addressAttribute)
            return
        }
        if let contactAttribute = try? values.decode(ContactAttribute.self, forKey: .contact) {
            self = .contact(contactAttribute)
            return
        }
        
        if let eventAttribute = try? values.decode(EventAttribute.self, forKey: .event) {
            self = .event(eventAttribute)
            return
        }
        
        if let reminderAttribute = try? values.decode(ReminderAttribute.self, forKey: .reminder) {
            self = .reminder(reminderAttribute)
            return
        }
        
        throw CodingError.decoding("Decode Failed!!!")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .image(let imageAttribute): try container.encode(imageAttribute, forKey: .image)
        case .link(let linkAttribute): try container.encode(linkAttribute, forKey: .link)
        case .address(let addressAttribute): try container.encode(addressAttribute, forKey: .address)
        case .contact(let contactAttribute): try container.encode(contactAttribute, forKey: .contact)
        case .event(let eventAttribute): try container.encode(eventAttribute, forKey: .event)
        case .reminder(let reminderAttribute): try container.encode(reminderAttribute, forKey: .reminder)
        }
        
    }
    
    
}
