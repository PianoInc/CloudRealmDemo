//
//  LinkAttribute.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 29..
//  Copyright © 2018년 piano. All rights reserved.
//

import CoreGraphics

struct LinkAttribute {
    let link: String
    let size: CGSize
}

extension LinkAttribute: Hashable {
    static func ==(lhs: LinkAttribute, rhs: LinkAttribute) -> Bool {
        return lhs.link == rhs.link && lhs.size == rhs.size
    }
    
    var hashValue: Int {
        return link.hashValue ^ size.width.hashValue ^ size.height.hashValue &* 16777619
    }
}

extension LinkAttribute: Codable {
    
    private enum CodingKeys: CodingKey {
        case link
        case size
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        link = try values.decode(String.self, forKey: .link)
        size = try values.decode(CGSize.self, forKey: .size)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(link, forKey: .link)
        try container.encode(size, forKey: .size)
    }
}
