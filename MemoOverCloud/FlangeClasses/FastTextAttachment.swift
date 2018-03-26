//
//  FastTextAttachment.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 5..
//  Copyright © 2018년 piano. All rights reserved.
//

import InteractiveTextEngine_iOS
import UIKit
import CoreGraphics

class FastTextAttachment: InteractiveTextAttachment {
    var imageID: String!
    var tempImage: UIImage!

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        
        return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
    }
}
