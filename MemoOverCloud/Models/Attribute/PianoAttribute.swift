//
//  PianoAttribute.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 20..
//  Copyright © 2018년 piano. All rights reserved.
//

import Foundation
import UIKit
import InteractiveTextEngine_iOS


struct PianoAttribute {
    let startIndex: Int
    let endIndex: Int
    
    let style: Style

    init?(range: NSRange, attribute: (NSAttributedStringKey, Any)) {
        self.startIndex = range.location
        self.endIndex = range.location + range.length

        guard let style = Style(from: attribute) else {return nil}
        self.style = style
    }
}

extension PianoAttribute: Hashable {
    var hashValue: Int {
        return startIndex.hashValue ^ endIndex.hashValue ^ style.hashValue
    }
    
    static func ==(lhs: PianoAttribute, rhs: PianoAttribute) -> Bool {
        return lhs.startIndex == rhs.startIndex && lhs.endIndex == rhs.endIndex && lhs.style == rhs.style
    }
    
    
}

extension PianoAttribute: Codable {

    private enum CodingKeys: CodingKey {
        case startIndex
        case endIndex

        case style
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        startIndex = try values.decode(Int.self, forKey: .startIndex)
        endIndex = try values.decode(Int.self, forKey: .endIndex)

        style = try values.decode(Style.self, forKey: .style)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(startIndex, forKey: .startIndex)
        try container.encode(endIndex, forKey: .endIndex)

        try container.encode(style, forKey: .style)
    }
}

extension NSMutableAttributedString {
    func add(attribute: PianoAttribute) {
        let range = NSMakeRange(attribute.startIndex, attribute.endIndex - attribute.startIndex)

        self.addAttributes(attribute.style.toNSAttribute(), range: range)
    }
}

enum Style {
    case backgroundColor(String)
    case foregroundColor(String)
    case strikethrough
    case underline
    case font(PianoFontAttribute)
    case attachment(AttachmentAttribute)

    init?(from attribute: (key: NSAttributedStringKey, value: Any)) {
        switch attribute.key {
            case .backgroundColor:
                guard let color = attribute.value as? UIColor else {return nil}
                self = .backgroundColor(color.hexString)
            case .foregroundColor:
                guard let color = attribute.value as? UIColor else {return nil}
                self = .foregroundColor(color.hexString)
            case .strikethroughStyle:
                guard let value = attribute.value as? NSUnderlineStyle, value == .styleSingle else {return nil}
                self = .strikethrough
            case .underlineStyle:
                guard let value = attribute.value as? NSUnderlineStyle, value == .styleSingle else {return nil}
                self = .underline
            case .font:
                guard let font = attribute.value as? UIFont, let fontAttribute = PianoFontAttribute(font: font) else {return nil}
                self = .font(fontAttribute)
            case .attachment:
                guard let attachment = attribute.value as? InteractiveTextAttachment,
                    let attribute = AttachmentAttribute(attachment: attachment) else {return nil}
                self = .attachment(attribute)
            default: return nil
        }
    }

    func toNSAttribute() -> [NSAttributedStringKey: Any] {
        switch self {
            case .backgroundColor(let hex): return [.backgroundColor: UIColor(hex: hex)]
            case .foregroundColor(let hex): return [.foregroundColor: UIColor(hex: hex)]
            case .strikethrough: return [.strikethroughStyle: NSUnderlineStyle.styleSingle]
            case .underline: return [.underlineStyle: NSUnderlineStyle.styleSingle]
            case .font(let fontAttribute): return [.font: fontAttribute.getFont()]
            case .attachment(let attachmentAttribute): return attachmentAttribute.toNSAttribute()
        }
    }
}

extension Style: Hashable {
    var hashValue: Int {
        switch self {
            case .backgroundColor(let hex): return "backgroundColor".hashValue ^ hex.hashValue
            case .foregroundColor(let hex): return "foregroundColor".hashValue ^ hex.hashValue
            case .strikethrough: return "strikethrough".hashValue
            case .underline: return "underline".hashValue
            case .font(let fontAttribute): return fontAttribute.hashValue
            case .attachment(let attachmentAttribute): return attachmentAttribute.hashValue
        }
    }
    
    static func ==(lhs: Style, rhs: Style) -> Bool {
        switch lhs {
            case .backgroundColor(let hex):
                if case let .backgroundColor(rHex) = rhs {
                    if hex == rHex {return true}
                }
                return false
            case .foregroundColor(let hex):
                if case let .foregroundColor(rHex) = rhs {
                    if hex == rHex {return true}
                }
                return false
            case .strikethrough:
                if case .strikethrough = rhs {
                    return true
                }
                return false
            case .underline:
                if case .underline = rhs {
                    return true
                }
                return false
            case .font(let fontAttribute):
                if case let .font(rFontAttribute) = rhs {
                    return fontAttribute.hashValue == rFontAttribute.hashValue
                }
                return false
            case .attachment(let attachmentAttribute):
                if case let .attachment(rAttachmentAttribute) = rhs {
                    return attachmentAttribute == rAttachmentAttribute
                }
                return false
        }
        
    }
    
    
}

extension Style: Codable {

    private enum CodingKeys: String, CodingKey {
        case backgroundColor
        case foregroundColor
        case strikeThrough
        case underline
        case font
        case attachment
    }

    enum CodingError: Error {
        case decoding(String)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let hexString = try? values.decode(String.self, forKey: .backgroundColor) {
            self = .backgroundColor(hexString)
            return
        }
        if let hexString = try? values.decode(String.self, forKey: .foregroundColor) {
            self = .foregroundColor(hexString)
            return
        }
        if let _ = try? values.decode(String.self, forKey: .strikeThrough) {
            self = .strikethrough
            return
        }
        if let _ = try? values.decode(String.self, forKey: .underline) {
            self = .underline
            return
        }

        if let fontAttribute = try? values.decode(PianoFontAttribute.self, forKey: .font) {
            self = .font(fontAttribute)
            return
        }

        if let attachmentAttribute = try? values.decode(AttachmentAttribute.self, forKey: .attachment) {
            self = .attachment(attachmentAttribute)
            return
        }

        throw CodingError.decoding("Decode Failed!!!")
    }

    func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
            case .backgroundColor(let hexString): try container.encode(hexString, forKey: .backgroundColor)
            case .foregroundColor(let hexString): try container.encode(hexString, forKey: .foregroundColor)
            case .strikethrough: try container.encode("", forKey: .strikeThrough)
            case .underline: try container.encode("", forKey: .underline)
            case .font(let fontDescriptor): try container.encode(fontDescriptor, forKey: .font)
            case .attachment(let attachmentAttribute): try container.encode(attachmentAttribute, forKey: .attachment)
        }
    }
}
