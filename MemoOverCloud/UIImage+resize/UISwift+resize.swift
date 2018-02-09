//
//  UISwift+resize.swift
//  ViewAttachmentTest
//
//  Created by 김범수 on 2018. 1. 23..
//  Copyright © 2018년 piano. All rights reserved.
//

import UIKit
import CoreGraphics


extension UIImage {
    func resizeImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setShouldAntialias(false)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}

extension CGSize {
    func fitToScreen() -> CGSize {

        if self.width > UIScreen.main.bounds.width - 20 {

            let width = UIScreen.main.bounds.width - 20
            let height = self.height * width / self.width

            return CGSize(width: width, height: height)

        } else {
            return self
        }

    }
}
