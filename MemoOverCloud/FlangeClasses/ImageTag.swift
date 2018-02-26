//
// Created by 김범수 on 2018. 2. 5..
// Copyright (c) 2018 piano. All rights reserved.
//

import Photos
import UIKit

class ImageTag {
    static func parseImageTag(_ tag: String) -> (String, CGFloat, CGFloat) {
        let strings = tag.components(separatedBy: "|")
        let width = CGFloat(Int(strings[1]) ?? 0)
        let height = CGFloat(Int(strings[2]) ?? 0)
        return (strings[0],width,height)
    }

    static func getImageTag(id: String, width: CGFloat, height: CGFloat) -> String {
        return "\(id)|\(Int(width))|\(Int(height))"
    }
}
