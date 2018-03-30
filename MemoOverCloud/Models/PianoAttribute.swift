//
//  PianoAttribute.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 20..
//  Copyright © 2018년 piano. All rights reserved.
//

import Foundation
import UIKit


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
    case bold
    case italic
    case image(String, CGFloat, CGFloat)

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
                //TODO: What if font is both bold&italic?
                guard let font = attribute.value as? UIFont, font.fontDescriptor.symbolicTraits.contains(.traitBold) else {return nil}
                if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    
                    self = .bold
                } else if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                    self = .italic
                } else {return nil}
            case .attachment:
                guard let attachment = attribute.value as? FastTextAttachment else {return nil}
                self = .image(attachment.imageID, attachment.currentSize.width, attachment.currentSize.height)

            default: return nil
        }
    }

    //TODO: fix dummy font attribute
    func toNSAttribute() -> [NSAttributedStringKey: Any] {
        switch self {
            case .backgroundColor(let hex): return [NSAttributedStringKey.backgroundColor: UIColor(hex: hex)]
            case .foregroundColor(let hex): return [NSAttributedStringKey.foregroundColor: UIColor(hex: hex)]
            case .strikethrough: return [NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleSingle]
            case .underline: return [NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle]
            case .bold: return [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 15)]
            case .italic: return [NSAttributedStringKey.font: UIFont.italicSystemFont(ofSize: 15)]
            case .image(let id, let width, let height):
                let attachment = FastTextAttachment()
                attachment.imageID = id
                attachment.currentSize = CGSize(width: width, height: height)
                
                return [NSAttributedStringKey.attachment: attachment]
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
            case .bold: return "bold".hashValue
            case .italic: return "italic".hashValue
            case.image(let id, let width, let height): return id.hashValue ^ width.hashValue ^ height.hashValue
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
            case .bold:
                if case .bold = rhs {
                    return true
                }
                return false
            case .italic:
                if case .italic = rhs {
                    return true
                }
                return false
            case .image(let id, let width, let height):
                if case let .image(rID, rWidth, rHeight) = rhs {
                    if id == rID && width == rWidth && height == rHeight {
                        return true
                    }
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
        case bold
        case italic
        case image
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
        if let _ = try? values.decode(String.self, forKey: .bold) {
            self = .bold
            return
        }
        if let _ = try? values.decode(String.self, forKey: .italic) {
            self = .italic
            return
        }
        if let tagString = try? values.decode(String.self, forKey: .image) {
            let (id, width, height) = ImageTag.parseImageTag(tagString)
            self = .image(id, width, height)
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
            case .bold: try container.encode("", forKey: .bold)
            case .italic: try container.encode("", forKey: .italic)
            case .image(let id, let width, let height): try container.encode(ImageTag.getImageTag(id: id, width: width, height: height), forKey: .image)
        }
    }
}
