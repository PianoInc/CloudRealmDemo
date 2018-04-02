//
//  ImageAttribute.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 29..
//  Copyright © 2018년 piano. All rights reserved.
//

import CoreGraphics

struct ImageAttribute {
    let id: String
    let size: CGSize
}

extension ImageAttribute: Hashable {
    static func ==(lhs: ImageAttribute, rhs: ImageAttribute) -> Bool {
        return lhs.id == rhs.id && lhs.size == rhs.size
    }
    
    var hashValue: Int {
        return id.hashValue ^ size.width.hashValue ^ size.height.hashValue &* 16777619
    }
}

extension ImageAttribute: Codable {
    
    private enum CodingKeys: CodingKey {
        case id
        case size
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(String.self, forKey: .id)
        size = try values.decode(CGSize.self, forKey: .size)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(size, forKey: .size)
    }
}
