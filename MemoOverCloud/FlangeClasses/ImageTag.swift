//
// Created by 김범수 on 2018. 2. 5..
// Copyright (c) 2018 piano. All rights reserved.
//

import Photos
import UIKit

struct ImageTag {
    static let tagName = "flg_image"
    let identifier: String
    let width: CGFloat
    let height: CGFloat

    
    init(identifier: String, width: CGFloat, height: CGFloat) {
        self.identifier = identifier
        self.width = width
        self.height = height
    }

    init?(tagString: String) {
        let components = tagString.components(separatedBy: "\"")
        let identifier = components[1]
        guard let width = Int(components[3]), let height = Int(components[5]) else {return nil}
        self.init(identifier: identifier, width: CGFloat(width), height: CGFloat(height))
    }

    func getTagString() -> String {
        return "<\(ImageTag.tagName) src=\"\(identifier)\" width=\"\(Int(width))\"height=\"\(Int(height))\">"
    }
}
