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

extension NSTextAttachment {
    func getImage() -> UIImage? {
        if let unwrappedImage = image {
            return unwrappedImage
        } else if let data = contents,
            let decodedImage = UIImage(data: data) {
            return decodedImage
        } else if let fileWrapper = fileWrapper,
            let imageData = fileWrapper.regularFileContents,
            let decodedImage = UIImage(data: imageData) {
            return decodedImage
        }
        return nil
    }
}
