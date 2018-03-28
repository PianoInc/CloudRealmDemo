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
    var tempImage: UIImage!//This is temp!!!!
    
    override init() {
        super.init()
    }

    init(attachment: FastTextAttachment) {
        super.init(attachment: attachment)
        self.imageID = attachment.imageID
        self.tempImage = attachment.tempImage
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func getPreviewForDragInteraction() -> UIImage? {
        return tempImage
    }
    
    override func getCopyForDragInteraction() -> InteractiveTextAttachment {
        return FastTextAttachment(attachment: self)
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
