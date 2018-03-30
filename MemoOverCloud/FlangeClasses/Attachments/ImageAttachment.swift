//
//  ImageAttachment.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 5..
//  Copyright © 2018년 piano. All rights reserved.
//

import InteractiveTextEngine_iOS
import UIKit
import CoreGraphics

class ImageAttachment: InteractiveTextAttachment {
    var imageID: String!
    
    override init() {
        super.init()
    }
    
    init(attribute: ImageAttribute) {
        super.init()
        self.imageID = attribute.id
        self.currentSize = attribute.size
    }

    init(attachment: ImageAttachment) {
        super.init(attachment: attachment)
        self.imageID = attachment.imageID
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
        
    override func getCopyForDragInteraction() -> InteractiveTextAttachment {
        return ImageAttachment(attachment: self)
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
