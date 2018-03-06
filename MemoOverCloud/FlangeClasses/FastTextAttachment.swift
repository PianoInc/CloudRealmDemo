//
//  FastTextAttachment.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 5..
//  Copyright © 2018년 piano. All rights reserved.
//

import FastLayoutTextEngine
import UIKit
import CoreGraphics

class FastTextAttachment: FlangeTextAttachment {
    var width: CGFloat!
    var height: CGFloat!
    var imageID: String!

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        return CGRect(x: 0, y: 0, width: width, height: height)
    }
}
